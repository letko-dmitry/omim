//
//  MWMMapAnnotationManager.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWMMapEngine;
@protocol MWMMapAnnotation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapAnnotationManager)
@interface MWMMapAnnotationManager : NSObject
@property (nonatomic, readonly) MWMMapEngine *engine;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEngine:(MWMMapEngine *)engine NS_DESIGNATED_INITIALIZER;

- (void)addAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations;
- (void)removeAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations;

@end

NS_ASSUME_NONNULL_END
