//
//  MWMMapEngine.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapEngine.h"

//#import "map/framework.hpp"
#import "Framework.h"

@interface MWMMapEngine () {
@public
    Framework *_framework;
}

@end

@implementation MWMMapEngine

- (instancetype)init {
    self = [super init];

    if (self) {
        _framework = &GetFramework();//new Framework(FrameworkParams(false, true));
    }

    return self;
}

- (void)dealloc {
    //delete framework;
}

@end

Framework &MWMMapEngineFramework(MWMMapEngine *engine) {
    return *(engine->_framework);
}
