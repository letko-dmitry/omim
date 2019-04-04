//
//  MWMMapDownloader.h
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import "storage/storage_defines.hpp"

@protocol MWMMapDownloadingDelegate;

@interface MWMMapDownloader : NSObject
@property (weak, nonatomic) id<MWMMapDownloadingDelegate> delegate;

- (void)downloadCountry:(storage::CountryId const &)countryId;

@end

