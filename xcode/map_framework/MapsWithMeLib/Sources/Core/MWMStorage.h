#include "storage/storage_defines.hpp"

@interface MWMStorage : NSObject

+ (void)downloadNode:(storage::CountryId const &)countryId onSuccess:(MWMVoidBlock)onSuccess;
+ (void)retryDownloadNode:(storage::CountryId const &)countryId;

@end
