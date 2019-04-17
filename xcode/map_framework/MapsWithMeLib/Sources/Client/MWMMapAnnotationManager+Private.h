//
//  MWMMapAnnotationManager+Private.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/17/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapAnnotationManager.h"

#if __cplusplus

#import "drape_frontend/frontend_renderer.hpp"

#endif

NS_ASSUME_NONNULL_BEGIN

@interface MWMMapAnnotationManager (Private)

#if __cplusplus

class ScreenBase;

- (void)handleTap:(df::TapInfo)tapInfo inViewport:(ScreenBase)viewport;

#endif

@end

NS_ASSUME_NONNULL_END
