//
//  MWMMapEngine.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapEngine)
@interface MWMMapEngine : NSObject

@end


#if __cplusplus

class Framework;

__attribute__((visibility("hidden")))
Framework &MWMMapEngineFramework(MWMMapEngine *engine);

#endif

NS_ASSUME_NONNULL_END
