//
//  MWMMapAnnotation.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapAnnotation)
@protocol MWMMapAnnotation <NSObject>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

NS_ASSUME_NONNULL_END
