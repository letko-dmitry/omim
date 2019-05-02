//
//  MWMMapSymbols.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 5/1/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapSymbols.h"


@implementation MWMMapSymbols

- (instancetype)initWithName:(NSString *)name imageFileUrl:(NSURL *)imageFileUrl mapFileUrl:(NSURL *)mapFileUrl {
    NSParameterAssert(name.length);
    NSParameterAssert(imageFileUrl.isFileURL);
    NSParameterAssert(mapFileUrl.isFileURL);

    self = [super init];

    if (self) {
        _name = [name copy];
        _imageFileUrl = [imageFileUrl copy];
        _mapFileUrl = [mapFileUrl copy];
    }

    return self;
}

@end
