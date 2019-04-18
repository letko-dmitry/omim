//
//  MWMMapViewRegion.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapViewRegion)
@interface MWMMapViewRegion : NSObject
@property (nonatomic, readonly) CLLocationCoordinate2D topRight;
@property (nonatomic, readonly) CLLocationCoordinate2D bottomLeft;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTopRight:(CLLocationCoordinate2D)topRight bottomLeft:(CLLocationCoordinate2D)bottomLeft NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCenter:(CLLocationCoordinate2D)center
             latitudinalMeters:(CLLocationDistance)latitudinalMeters
            longitudinalMeters:(CLLocationDistance)longitudinalMeters;

@end

NS_ASSUME_NONNULL_END
