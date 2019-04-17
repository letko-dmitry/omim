//
//  MWMMapEngine+Private.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/16/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapEngine.h"

@protocol MWMMapEngineSubscriber;

NS_ASSUME_NONNULL_BEGIN

@interface MWMMapEngine (Private)
@property (nonatomic, readonly) BOOL isAnimating;

- (void)start;
- (void)stop;

- (void)subscribe:(id<MWMMapEngineSubscriber>)subscriber;
- (void)unsubscribe:(id<MWMMapEngineSubscriber>)subscriber;

@end


#if __cplusplus

class Framework;

__attribute__((visibility("hidden")))
Framework &MWMMapEngineFramework(MWMMapEngine *engine);

#endif

NS_ASSUME_NONNULL_END
