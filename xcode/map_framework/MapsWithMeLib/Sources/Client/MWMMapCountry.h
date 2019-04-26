//
//  MWMMapCountry.h
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 26.4.19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *MWMMapCountryIdentifier NS_SWIFT_NAME(MapCountryIdentifier);

NS_SWIFT_NAME(MapCountry)
@interface MWMMapCountry: NSObject
@property (copy, nonatomic, readonly) MWMMapCountryIdentifier identifier;
@property (copy, nonatomic, readonly) NSURL *fileUrl;
@property (nonatomic, readonly) NSInteger version;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWith:(MWMMapCountryIdentifier)identifier fileUrl:(NSURL *)fileUrl;
- (instancetype)initWith:(MWMMapCountryIdentifier)identifier fileUrl:(NSURL *)fileUrl version:(NSInteger)version NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
