#include "generator/regions/regions_builder.hpp"

#include "base/assert.hpp"
#include "base/thread_pool_computational.hpp"
#include "base/stl_helpers.hpp"
#include "base/thread_pool_computational.hpp"

#include <algorithm>
#include <chrono>
#include <fstream>
#include <functional>
#include <numeric>
#include <queue>
#include <thread>
#include <unordered_set>

namespace generator
{
namespace regions
{
namespace
{
Node::Ptr ShrinkToFit(Node::Ptr p)
{
  p->ShrinkToFitChildren();
  for (auto ptr : p->GetChildren())
    ShrinkToFit(ptr);

  return p;
}
}  // namespace

RegionsBuilder::RegionsBuilder(Regions && regions, size_t threadsCount)
  : m_regions(std::move(regions))
  , m_threadsCount(threadsCount)
{
  ASSERT(m_threadsCount != 0, ());

  auto const isCountry = [](Region const & r) { return r.IsCountry(); };
  std::copy_if(std::begin(m_regions), std::end(m_regions), std::back_inserter(m_countries), isCountry);
  base::EraseIf(m_regions, isCountry);
  auto const cmp = [](Region const & l, Region const & r) { return l.GetArea() > r.GetArea(); };
  std::sort(std::begin(m_countries), std::end(m_countries), cmp);
}

RegionsBuilder::Regions const & RegionsBuilder::GetCountries() const
{
  return m_countries;
}

RegionsBuilder::StringsList RegionsBuilder::GetCountryNames() const
{
  StringsList result;
  std::unordered_set<std::string> set;
  for (auto const & c : GetCountries())
  {
    auto name = c.GetName();
    if (set.insert(name).second)
      result.emplace_back(std::move(name));
  }

  return result;
}

Node::PtrList RegionsBuilder::MakeSelectedRegionsByCountry(Region const & country,
                                                           Regions const & allRegions)
{
  std::vector<LevelRegion> regionsInCountry{{PlaceLevel::Country, country}};
  for (auto const & region : allRegions)
  {
    if (country.ContainsRect(region))
      regionsInCountry.emplace_back(GetLevel(region), region);
  }

  auto const comp = [](LevelRegion const & l, LevelRegion const & r) {
    auto const lArea = l.GetArea();
    auto const rArea = r.GetArea();
    return lArea != rArea ? lArea > rArea : l.GetRank() < r.GetRank();
  };
  std::sort(std::begin(regionsInCountry), std::end(regionsInCountry), comp);

  Node::PtrList nodes;
  nodes.reserve(regionsInCountry.size());
  for (auto && region : regionsInCountry)
    nodes.emplace_back(std::make_shared<Node>(std::move(region)));

  return nodes;
}

Node::Ptr RegionsBuilder::BuildCountryRegionTree(Region const & country,
                                                 Regions const & allRegions)
{
  auto nodes = MakeSelectedRegionsByCountry(country, allRegions);
  while (nodes.size() > 1)
  {
    auto itFirstNode = std::rbegin(nodes);
    auto & firstRegion = (*itFirstNode)->GetData();
    auto itCurr = itFirstNode + 1;
    for (; itCurr != std::rend(nodes); ++itCurr)
    {
      auto const & currRegion = (*itCurr)->GetData();
      if (currRegion.Contains(firstRegion) ||
          (GetWeight(firstRegion) < GetWeight(currRegion) &&
           currRegion.Contains(firstRegion.GetCenter()) &&
           currRegion.CalculateOverlapPercentage(firstRegion) > 50.0))
      {
        (*itFirstNode)->SetParent(*itCurr);
        (*itCurr)->AddChild(*itFirstNode);
        // We want to free up memory.
        firstRegion.DeletePolygon();
        nodes.pop_back();
        break;
      }
    }

    if (itCurr == std::rend(nodes))
      nodes.pop_back();
  }

  return nodes.empty() ? std::shared_ptr<Node>() : ShrinkToFit(nodes.front());
}

void RegionsBuilder::ForEachNormalizedCountry(NormalizedCountryFn fn)
{
  for (auto const & countryName : GetCountryNames())
  {
    RegionsBuilder::Regions country;
    auto const & countries = GetCountries();
    auto const pred = [&](const Region & r) { return countryName == r.GetName(); };
    std::copy_if(std::begin(countries), std::end(countries), std::back_inserter(country), pred);
    auto const countryTrees = BuildCountryRegionTrees(country);
    auto mergedTree = std::accumulate(std::begin(countryTrees), std::end(countryTrees),
                                      Node::Ptr(), MergeTree);
    NormalizeTree(mergedTree);
    fn(countryName, mergedTree);
  }
}

std::vector<Node::Ptr> RegionsBuilder::BuildCountryRegionTrees(RegionsBuilder::Regions const & countries)
{
  std::vector<std::future<Node::Ptr>> tmp;
  {
    base::thread_pool::computational::ThreadPool threadPool(m_threadsCount);
    for (auto const & country : countries)
    {
      auto result = threadPool.Submit(&RegionsBuilder::BuildCountryRegionTree, country, m_regions);
      tmp.emplace_back(std::move(result));
    }
  }
  std::vector<Node::Ptr> res;
  res.reserve(tmp.size());
  std::transform(std::begin(tmp), std::end(tmp),
                 std::back_inserter(res), [](auto & f) { return f.get(); });
  return res;
}

// static
PlaceLevel RegionsBuilder::GetLevel(Region const & region)
{
  switch (region.GetPlaceType())
  {
  case PlaceType::City:
  case PlaceType::Town:
  case PlaceType::Village:
  case PlaceType::Hamlet:
    return PlaceLevel::Locality;
  case PlaceType::Suburb:
  case PlaceType::Neighbourhood:
    return PlaceLevel::Suburb;
  case PlaceType::IsolatedDwelling:
    return PlaceLevel::Sublocality;
  case PlaceType::Unknown:
    break;
  }

  switch (region.GetAdminLevel())
  {
  case AdminLevel::Two:
    return PlaceLevel::Country;
  case AdminLevel::Four:
    return PlaceLevel::Region;
  case AdminLevel::Six:
    return PlaceLevel::Subregion;
  default:
    break;
  }

  return PlaceLevel::Unknown;
}

// static
size_t RegionsBuilder::GetWeight(Region const & region)
{
  switch (region.GetPlaceType())
  {
  case PlaceType::City:
  case PlaceType::Town:
  case PlaceType::Village:
  case PlaceType::Hamlet:
    return 3;
  case PlaceType::Suburb:
  case PlaceType::Neighbourhood:
    return 2;
  case PlaceType::IsolatedDwelling:
    return 1;
  case PlaceType::Unknown:
    break;
  }

  switch (region.GetAdminLevel())
  {
  case AdminLevel::Two:
    return 6;
  case AdminLevel::Four:
    return 5;
  case AdminLevel::Six:
    return 4;
  default:
    break;
  }

  return 0;
}
}  // namespace regions
}  // namespace generator
