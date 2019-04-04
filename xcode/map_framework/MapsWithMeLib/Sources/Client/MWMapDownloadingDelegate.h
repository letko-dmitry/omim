//
//  MWMapDownloadingDelegate.h
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MWMMapDownloadingDelegate <NSObject>

@optional
- (void)handleMapLoadingQueued;
- (void)handleMapLoadingProgress:(CGFloat)progress;
- (void)handleMapDownloaded;
- (void)handleMapLoadingFinishedWithError;

@end
