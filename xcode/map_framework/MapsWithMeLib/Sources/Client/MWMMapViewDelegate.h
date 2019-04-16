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

- (void)mapViewDidChangeRegion:(MWMMapView *)renderer NS_SWIFT_NAME(mapViewDidChangeRegion(_:));

@end

NS_ASSUME_NONNULL_END
