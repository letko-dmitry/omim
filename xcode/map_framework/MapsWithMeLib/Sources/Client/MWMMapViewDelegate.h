//
//  MWMMapViewDelegate.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWMMapView;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapViewDelegate)
@protocol MWMMapViewDelegate <NSObject>
@optional

- (void)mapViewDidChangeRegion:(MWMMapView *)view NS_SWIFT_NAME(mapViewDidChangeRegion(_:));
- (void)mapView:(MWMMapView *)view regionDidChangeAnimated:(BOOL)animated NS_SWIFT_NAME(mapView(_:regionDidChangeAnimated:));

- (void)mapViewDidChangeCountry:(MWMMapView *)view NS_SWIFT_NAME(mapViewDidChangeCountry(_:));

@end

NS_ASSUME_NONNULL_END
