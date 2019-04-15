//
//  MWMapViewRendererDelegate.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapRendererDelegate)
@protocol MWMapViewRendererDelegate <NSObject>

- (void)mapViewRendererDidChangeRegion:(MWMapViewRenderer *)renderer NS_SWIFT_NAME(mapRendererDidChangeRegion(_:));

@end

NS_ASSUME_NONNULL_END
