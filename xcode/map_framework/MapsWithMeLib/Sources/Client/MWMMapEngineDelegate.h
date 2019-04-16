//
//  MWMMapEngineDelegate.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/16/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWMMapEngine;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapEngineDelegate)
@protocol MWMMapEngineDelegate <NSObject>

- (void)mapEngineWillPause:(MWMMapEngine *)engine NS_SWIFT_NAME(mapEngineWillPause(_:));
- (void)mapEngineDidResume:(MWMMapEngine *)engine NS_SWIFT_NAME(mapEngineDidResume(_:));

@end

NS_ASSUME_NONNULL_END
