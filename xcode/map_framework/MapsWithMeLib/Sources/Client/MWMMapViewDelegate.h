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

- (void)mapViewDidChangeRegion:(MWMMapView *)renderer NS_SWIFT_NAME(mapViewDidChangeRegion(_:));
- (void)mapView:(MWMMapView *)renderer regionDidChangeAnimated:(BOOL)animated NS_SWIFT_NAME(mapView(_:regionDidChangeAnimated:));

@end

NS_ASSUME_NONNULL_END
