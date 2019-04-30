#include "openlr/score_candidate_paths_getter.hpp"

#include "openlr/graph.hpp"
#include "openlr/helpers.hpp"
#include "openlr/openlr_model.hpp"
#include "openlr/score_candidate_points_getter.hpp"

#include "routing/road_graph.hpp"

#include "platform/location.hpp"

#include "geometry/angles.hpp"
#include "geometry/mercator.hpp"

#include "base/logging.hpp"
#include "base/stl_helpers.hpp"

#include <algorithm>
#include <functional>
#include <iterator>
#include <queue>
#include <set>
#include <tuple>
#include <utility>

using namespace routing;
using namespace std;

namespace openlr
{
namespace
{
int constexpr kNumBuckets = 256;
double constexpr kAnglesInBucket = 360.0 / kNumBuckets;

double ToAngleInDeg(uint32_t angleInBuckets)
{
  CHECK_GREATER_OR_EQUAL(angleInBuckets, 0, ());
  CHECK_LESS_OR_EQUAL(angleInBuckets, 255, ());
  return base::clamp(kAnglesInBucket * static_cast<double>(angleInBuckets), 0.0, 360.0);
}

uint32_t BearingInDeg(m2::PointD const & a, m2::PointD const & b)
{
  auto const angle = location::AngleToBearing(base::RadToDeg(ang::AngleTo(a, b)));
  CHECK_LESS_OR_EQUAL(angle, 360.0, ());
  CHECK_GREATER_OR_EQUAL(angle, 0.0, ());
  return angle;
}

double DifferenceInDeg(double a1, double a2)
{
  auto const diff = 180.0 - abs(abs(a1 - a2) - 180.0);
  CHECK_LESS_OR_EQUAL(diff, 180.0, ());
  CHECK_GREATER_OR_EQUAL(diff, 0.0, ());
  return diff;
}
}  // namespace

// ScoreCandidatePathsGetter::Link ----------------------------------------------------------------------
Graph::Edge ScoreCandidatePathsGetter::Link::GetStartEdge() const
{
  auto * start = this;
  while (start->m_parent)
    start = start->m_parent.get();

  return start->m_edge;
}

bool ScoreCandidatePathsGetter::Link::IsJunctionInPath(Junction const & j) const
{
  for (auto * l = this; l; l = l->m_parent.get())
  {
    if (l->m_edge.GetEndJunction() == j)
    {
      LOG(LDEBUG, ("A loop detected, skipping..."));
      return true;
    }
  }

  return false;
}

// ScoreCandidatePathsGetter ----------------------------------------------------------------------------
bool ScoreCandidatePathsGetter::GetLineCandidatesForPoints(
    vector<LocationReferencePoint> const & points, vector<ScorePathVec> & lineCandidates)
{
  CHECK_GREATER(points.size(), 1, ());

  for (size_t i = 0; i < points.size(); ++i)
  {
    if (i != points.size() - 1 && points[i].m_distanceToNextPoint == 0)
    {
      LOG(LINFO, ("Distance to next point is zero. Skipping the whole segment"));
      ++m_stats.m_zeroDistToNextPointCount;
      return false;
    }

    lineCandidates.emplace_back();
    auto const isLastPoint = i == points.size() - 1;
    double const distanceToNextPointM =
        (isLastPoint ? points[i - 1] : points[i]).m_distanceToNextPoint;

    ScoreEdgeVec edgesCandidates;
    m_pointsGetter.GetEdgeCandidates(MercatorBounds::FromLatLon(points[i].m_latLon),
                                     isLastPoint, edgesCandidates);

    GetLineCandidates(points[i], isLastPoint, distanceToNextPointM, edgesCandidates,
                      lineCandidates.back());

    if (lineCandidates.back().empty())
    {
      LOG(LINFO, ("No candidate lines found for point", points[i].m_latLon, "Giving up"));
      ++m_stats.m_noCandidateFound;
      return false;
    }
  }

  CHECK_EQUAL(lineCandidates.size(), points.size(), ());
  return true;
}

void ScoreCandidatePathsGetter::GetAllSuitablePaths(ScoreEdgeVec const & startLines,
                                                    bool isLastPoint, double bearDistM,
                                                    FunctionalRoadClass functionalRoadClass,
                                                    FormOfWay formOfWay,
                                                    vector<shared_ptr<Link>> & allPaths)
{
  queue<shared_ptr<Link>> q;

  for (auto const & e : startLines)
  {
    Score roadScore = 0; // Score based on functional road class and form of way.
    if (!PassesRestrictionV3(e.m_edge, functionalRoadClass, formOfWay, m_infoGetter, roadScore))
      continue;

    q.push(
        make_shared<Link>(nullptr /* parent */, e.m_edge, 0 /* distanceM */, e.m_score, roadScore));
  }

  // Filling |allPaths| staring from |startLines| which have passed functional road class
  // and form of way restrictions. All paths in |allPaths| are shorter then |bearDistM| plus
  // one segment length.
  while (!q.empty())
  {
    auto const u = q.front();
    q.pop();

    auto const & currentEdge = u->m_edge;
    auto const currentEdgeLen = EdgeLength(currentEdge);

    if (u->m_distanceM + currentEdgeLen >= bearDistM)
    {
      allPaths.emplace_back(move(u));
      continue;
    }

    CHECK_LESS(u->m_distanceM + currentEdgeLen, bearDistM, ());

    Graph::EdgeVector edges;
    if (!isLastPoint)
      m_graph.GetOutgoingEdges(currentEdge.GetEndJunction(), edges);
    else
      m_graph.GetIngoingEdges(currentEdge.GetStartJunction(), edges);

    for (auto const & e : edges)
    {
      CHECK(!e.IsFake(), ());

      if (EdgesAreAlmostEqual(e.GetReverseEdge(), currentEdge))
        continue;

      CHECK(currentEdge.HasRealPart(), ());

      Score roadScore = 0;
      if (!PassesRestrictionV3(e, functionalRoadClass, formOfWay, m_infoGetter, roadScore))
        continue;

      if (u->IsJunctionInPath(e.GetEndJunction()))
        continue;

      // Road score for a path is minimum value of score of segments based on functional road class
      // of the segments and form of way of the segments.
      q.emplace(make_shared<Link>(u, e, u->m_distanceM + currentEdgeLen, u->m_pointScore,
                                  min(roadScore, u->m_minRoadScore)));
    }
  }
}

void ScoreCandidatePathsGetter::GetBestCandidatePaths(
    vector<shared_ptr<Link>> const & allPaths, bool isLastPoint, uint32_t requiredBearing,
    double bearDistM, m2::PointD const & startPoint, ScorePathVec & candidates)
{
  CHECK_GREATER_OR_EQUAL(requiredBearing, 0, ());
  CHECK_LESS_OR_EQUAL(requiredBearing, 255, ());

  multiset<CandidatePath, greater<>> candidatePaths;

  BearingPointsSelector pointsSelector(static_cast<uint32_t>(bearDistM), isLastPoint);
  for (auto const & link : allPaths)
  {
    auto const bearStartPoint = pointsSelector.GetStartPoint(link->GetStartEdge());

    // Number of edges counting from the last one to check bearing on. According to OpenLR spec
    // we have to check bearing on a point that is no longer than 25 meters traveling down the path.
    // But sometimes we may skip the best place to stop and generate a candidate. So we check several
    // edges before the last one to avoid such a situation. Number of iterations is taken
    // by intuition.
    // Example:
    // o -------- o  { Partners segment. }
    // o ------- o --- o { Our candidate. }
    //               ^ 25m
    //           ^ This one may be better than
    //                 ^ this one.
    // So we want to check them all.
    uint32_t traceBackIterationsLeft = 3;
    for (auto part = link; part; part = part->m_parent)
    {
      if (traceBackIterationsLeft == 0)
        break;

      --traceBackIterationsLeft;

      auto const bearEndPoint = pointsSelector.GetEndPoint(part->m_edge, part->m_distanceM);

      auto const bearingDeg = BearingInDeg(bearStartPoint, bearEndPoint);
      double const requiredBearingDeg = ToAngleInDeg(requiredBearing);
      double const angleDeviationDeg = DifferenceInDeg(bearingDeg, requiredBearingDeg);

      // If the bearing according to osm segments (|bearingDeg|) is significantly different
      // from the bearing set in openlr (|requiredBearingDeg|) the candidate should be skipped.
      double constexpr kMinAngleDeviationDeg = 50.0;
      if (angleDeviationDeg > kMinAngleDeviationDeg)
        continue;

      double constexpr kMaxScoreForBearing = 60.0;
      double constexpr kAngleDeviationFactor = 4.3;
      auto const bearingScore = static_cast<Score>(
          kMaxScoreForBearing / (1.0 + angleDeviationDeg / kAngleDeviationFactor));
      candidatePaths.emplace(part, part->m_pointScore, part->m_minRoadScore, bearingScore);
    }
  }

  size_t constexpr kMaxCandidates = 7;
  vector<CandidatePath> paths;
  copy_n(candidatePaths.begin(), min(static_cast<size_t>(kMaxCandidates), candidatePaths.size()),
         back_inserter(paths));

  for (auto const & path : paths)
  {
    Graph::EdgeVector edges;
    for (auto * p = path.m_path.get(); p; p = p->m_parent.get())
      edges.push_back(p->m_edge);

    if (!isLastPoint)
      reverse(edges.begin(), edges.end());

    candidates.emplace_back(path.GetScore(), move(edges));
  }
}

void ScoreCandidatePathsGetter::GetLineCandidates(openlr::LocationReferencePoint const & p,
                                                  bool isLastPoint,
                                                  double distanceToNextPointM,
                                                  ScoreEdgeVec const & edgeCandidates,
                                                  ScorePathVec & candidates)
{
  double constexpr kDefaultBearDistM = 25.0;
  double const bearDistM = min(kDefaultBearDistM, distanceToNextPointM);

  ScoreEdgeVec const & startLines = edgeCandidates;
  LOG(LDEBUG, ("Listing start lines:"));
  for (auto const & e : startLines)
    LOG(LDEBUG, (LogAs2GisPath(e.m_edge)));

  auto const startPoint = MercatorBounds::FromLatLon(p.m_latLon);

  vector<shared_ptr<Link>> allPaths;
  GetAllSuitablePaths(startLines, isLastPoint, bearDistM, p.m_functionalRoadClass, p.m_formOfWay,
                      allPaths);

  GetBestCandidatePaths(allPaths, isLastPoint, p.m_bearing, bearDistM, startPoint, candidates);
  // Sorting by increasing order.
  sort(candidates.begin(), candidates.end(),
       [](ScorePath const & s1, ScorePath const & s2) { return s1.m_score > s2.m_score; });
  LOG(LDEBUG, (candidates.size(), "Candidate paths found for point:", p.m_latLon));
}
}  // namespace openlr
