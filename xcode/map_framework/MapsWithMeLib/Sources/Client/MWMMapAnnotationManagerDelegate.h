//
//  MWMMapAnnotationManagerDelegate.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/17/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWMMapAnnotationManager;

@protocol MWMMapAnnotation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapAnnotationManagerDelegate)
@protocol MWMMapAnnotationManagerDelegate <NSObject>
@optional

- (void)mapAnnotationManager:(MWMMapAnnotationManager *)manager didSelect:(id<MWMMapAnnotation>)annotation NS_SWIFT_NAME(mapAnnotationManager(_:didSelect:));
- (void)mapAnnotationManager:(MWMMapAnnotationManager *)manager didDeselect:(id<MWMMapAnnotation>)annotation NS_SWIFT_NAME(mapAnnotationManager(_:didDeselect:));

@end

NS_ASSUME_NONNULL_END
