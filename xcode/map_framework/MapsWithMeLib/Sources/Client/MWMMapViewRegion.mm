//
//  MWMMapViewRegion.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapViewRegion.h"

#import "geometry/mercator.hpp"

@implementation MWMMapViewRegion

- (instancetype)initWithTopRight:(CLLocationCoordinate2D)topRight bottomLeft:(CLLocationCoordinate2D)bottomLeft {
    self = [super init];

    if (self) {
        _topRight = topRight;
        _bottomLeft = bottomLeft;
    }

    return self;
}

- (instancetype)initWithCenter:(CLLocationCoordinate2D)center
             latitudinalMeters:(CLLocationDistance)latitudinalMeters
            longitudinalMeters:(CLLocationDistance)longitudinalMeters {
    auto centerXY = MercatorBounds::FromLatLon(center.latitude, center.longitude);
    auto rectXY = MercatorBounds::RectByCenterXYAndSizeInMeters(centerXY.x, centerXY.y, latitudinalMeters, longitudinalMeters);
    auto rect = MercatorBounds::ToLatLonRect(rectXY);
    auto topRight = rect.RightTop();
    auto bottomLeft = rect.LeftBottom();

    self = [self initWithTopRight: CLLocationCoordinate2DMake(topRight.x, topRight.y)
                       bottomLeft: CLLocationCoordinate2DMake(bottomLeft.x, bottomLeft.y)];

    if (self) {

    }

    return self;
}

@end
