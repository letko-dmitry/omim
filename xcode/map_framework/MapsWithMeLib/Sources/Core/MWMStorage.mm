#import "MWMStorage.h"

#include "Framework.h"

#include "storage/storage_helpers.hpp"

#include <numeric>

using namespace storage;

@implementation MWMStorage

+ (void)downloadNode:(CountryId const &)countryId onSuccess:(MWMVoidBlock)onSuccess
{
  if (IsEnoughSpaceForDownload(countryId, GetFramework().GetStorage()))
  {
      GetFramework().GetStorage().DownloadNode(countryId);
      if (onSuccess)
          onSuccess();
  }
}

+ (void)retryDownloadNode:(CountryId const &)countryId
{
    GetFramework().GetStorage().RetryDownloadNode(countryId);
}

@end
