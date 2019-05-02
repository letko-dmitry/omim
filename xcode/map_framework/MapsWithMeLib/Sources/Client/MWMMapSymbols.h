//
//  MWMMapSymbols.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 5/1/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MapSymbols)
@interface MWMMapSymbols: NSObject
@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSURL *imageFileUrl;
@property (copy, nonatomic, readonly) NSURL *mapFileUrl;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)name imageFileUrl:(NSURL *)imageFileUrl mapFileUrl:(NSURL *)mapFileUrl;

@end

NS_ASSUME_NONNULL_END
