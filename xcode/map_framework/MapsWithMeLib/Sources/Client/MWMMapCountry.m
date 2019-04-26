//
//  MWMMapCountry.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/26/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapCountry.h"

@implementation MWMMapCountry

- (instancetype)initWith:(MWMMapCountryIdentifier)identifier fileUrl:(NSURL *)fileUrl {
    return [self initWith: identifier
                  fileUrl: fileUrl
                  version: 0];
}

- (instancetype)initWith:(MWMMapCountryIdentifier)identifier fileUrl:(NSURL *)fileUrl version:(NSInteger)version {
    NSParameterAssert(identifier != nil);
    NSParameterAssert(fileUrl != nil);
    NSParameterAssert(fileUrl.isFileURL);

    self = [super init];

    if (self) {
        _identifier = [identifier copy];
        _fileUrl = [fileUrl copy];
        _version = version;
    }

    return self;
}

@end
