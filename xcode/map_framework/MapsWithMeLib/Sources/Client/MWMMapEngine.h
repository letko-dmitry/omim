//
//  MWMMapEngine.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MWMMapCountry.h"

@class MWMMapCountry;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapEngine)
@interface MWMMapEngine : NSObject

- (void)loadCountry:(MWMMapCountry *)country NS_SWIFT_NAME(loadCountry(_:));

@end

NS_ASSUME_NONNULL_END
