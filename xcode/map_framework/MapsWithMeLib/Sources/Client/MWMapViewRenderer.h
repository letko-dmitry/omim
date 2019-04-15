//
//  MWMapView.h
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MWMMapDownloadingDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapRenderer)
@interface MWMapViewRenderer: UIResponder
@property (weak, nonatomic, nullable) id<MWMMapDownloadingDelegate> mapDownloadingDelegate;

- (void)setupWithView:(UIView *)view;

- (void)handleViewWillApear;
- (void)handleViewDidDisappear;
- (void)handleViewDidLayoutSubviews;

@end

NS_ASSUME_NONNULL_END
