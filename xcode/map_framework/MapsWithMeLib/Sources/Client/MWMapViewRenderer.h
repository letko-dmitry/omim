//
//  MWMapView.h
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWMMapEngine;
@class MWMapViewRegion;

@protocol MWMapViewRendererDelegate;
@protocol MWMMapDownloadingDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapRenderer)
@interface MWMapViewRenderer: UIResponder
@property (nonatomic, readonly) MWMMapEngine *engine;
@property (nonatomic, readonly) MWMapViewRegion *region;
@property (weak, nonatomic, nullable) id<MWMapViewRendererDelegate> delegate;
@property (weak, nonatomic, nullable) id<MWMMapDownloadingDelegate> mapDownloadingDelegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEngine:(MWMMapEngine *)engine;

- (void)setupWithView:(UIView *)view;

- (void)handleViewWillApear;
- (void)handleViewDidDisappear;
- (void)handleViewDidLayoutSubviews;

@end

NS_ASSUME_NONNULL_END
