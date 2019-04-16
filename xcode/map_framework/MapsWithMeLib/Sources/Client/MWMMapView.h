//
//  MWMMapView.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/16/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWMMapEngine;
@class MWMMapViewRegion;

@protocol MWMMapViewDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapView)
@interface MWMMapView : UIView
@property (nonatomic, readonly) MWMMapEngine *engine;
@property (nonatomic, readonly) MWMMapViewRegion *region;
@property (weak, nonatomic, nullable) id<MWMMapViewDelegate> delegate;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEngine:(MWMMapEngine *)engine NS_DESIGNATED_INITIALIZER;

- (void)showRegion:(MWMMapViewRegion *)region animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
