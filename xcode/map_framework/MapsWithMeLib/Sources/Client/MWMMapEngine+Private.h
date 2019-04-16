//
//  MWMMapEngine+Private.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/16/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapEngine.h"

@protocol MWMMapEngineDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface MWMMapEngine (Private)
@property (nonatomic, readonly) BOOL isAnimating;
@property (weak, nonatomic, nullable) id<MWMMapEngineDelegate> delegate;

- (void)start;
- (void)stop;

@end


#if __cplusplus

class Framework;

__attribute__((visibility("hidden")))
Framework &MWMMapEngineFramework(MWMMapEngine *engine);

#endif

NS_ASSUME_NONNULL_END
