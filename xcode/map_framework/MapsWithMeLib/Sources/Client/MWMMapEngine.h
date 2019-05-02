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
@class MWMMapSymbols;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapEngine)
@interface MWMMapEngine : NSObject
@property (copy, nonatomic, readonly) NSArray<MWMMapSymbols *> *symbols;

- (instancetype)initWithSymbols:(NSArray<MWMMapSymbols *> *)symbols NS_DESIGNATED_INITIALIZER;

- (void)loadCountry:(MWMMapCountry *)country NS_SWIFT_NAME(loadCountry(_:));

@end

NS_ASSUME_NONNULL_END
