//
//  MWMMapEngine.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MWMMapCountry.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapEngine)
@interface MWMMapEngine : NSObject

- (void)loadCountryWithIdentifier:(MWMMapCountryIdentifier)identifier fromFileAt:(NSURL *)fileUrl NS_SWIFT_NAME(loadCountry(withIdentifier:from:));

@end

NS_ASSUME_NONNULL_END
