//
//  MWMapViewRegion.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMapViewRegion.h"

@implementation MWMapViewRegion

- (instancetype)initWithTopRight:(CLLocationCoordinate2D)topRight bottomLeft:(CLLocationCoordinate2D)bottomLeft {
    self = [super init];

    if (self) {
        _topRight = topRight;
        _bottomLeft = bottomLeft;
    }

    return self;
}

@end
