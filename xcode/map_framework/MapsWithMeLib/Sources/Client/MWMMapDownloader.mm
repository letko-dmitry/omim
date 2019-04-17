//
//  MWMMapDownloader.m
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import "MWMMapDownloader.h"
#import "MWMapDownloadingDelegate.h"
#import "MWMStorage.h"
#import "Framework.h"

using namespace storage;

@interface MWMMapDownloader() {
    CountryId m_countryId;
}

@end

@implementation MWMMapDownloader

- (instancetype)init {
    self = [super init];

    if (self) {

    }

    return self;
}

- (void)downloadCountry:(CountryId const &)countryId {
    m_countryId = countryId;
    if (countryId == kInvalidCountryId) {
        return;
    }
    
    auto & f = GetFramework();
    auto const & s = f.GetStorage();

    NodeAttrs nodeAttrs;
    s.GetNodeAttrs(countryId, nodeAttrs);
    
    if (nodeAttrs.m_present) {
        [self.delegate handleMapDownloaded];
        return;
    }

    switch (nodeAttrs.m_status)
    {
        case NodeStatus::NotDownloaded:
        case NodeStatus::Partly: {
            [MWMStorage downloadNode:countryId
                           onSuccess:^{
                               [self.delegate handleMapLoadingQueued];
                           }];
            break;
        }
            
        case NodeStatus::Downloading: {
            CGFloat progress = static_cast<CGFloat>(nodeAttrs.m_downloadingProgress.first) / nodeAttrs.m_downloadingProgress.second;
            [self.delegate handleMapLoadingProgress:progress];
            break;
        }
            
        case NodeStatus::Applying:
        case NodeStatus::InQueue:
            [self.delegate handleMapLoadingQueued];
            break;
            
        case NodeStatus::Undefined:
        case NodeStatus::Error:
            [self.delegate handleMapLoadingFinishedWithError];
            break;
            
        case NodeStatus::OnDisk:
        case NodeStatus::OnDiskOutOfDate:
            [self.delegate handleMapDownloaded];
            break;
    }
}

//#pragma mark - MWMFrameworkStorageObserver
//
//- (void)processCountryEvent:(CountryId const &)countryId {
//    if (m_countryId == countryId) {
//        [self downloadCountry:countryId];
//    }
//}
//
//- (void)processCountry:(CountryId const &)countryId
//              progress:(MapFilesDownloader::Progress const &)progress {
//    if (m_countryId == countryId) {
//        [self downloadCountry:countryId];
//    }
//}

@end
