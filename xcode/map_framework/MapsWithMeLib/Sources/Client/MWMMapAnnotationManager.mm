//
//  MWMMapAnnotationManager.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapAnnotationManager.h"
#import "MWMMapAnnotation.h"
#import "MWMMapEngine.h"

#import "AnnotationMark.hpp"

#import "map/framework.hpp"

@interface MWMMapAnnotationManager () {
    std::map<id<MWMMapAnnotation>, kml::MarkId> _markIdentifiersByAnnotation;
}

@end

@implementation MWMMapAnnotationManager

- (instancetype)initWithEngine:(MWMMapEngine *)engine {
    NSParameterAssert(engine != nil);

    self = [super init];

    if (self) {
        _engine = engine;
    }

    return self;
}

- (void)addAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations {
    NSParameterAssert(annotations != nil);

    auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

    for (NSObject<MWMMapAnnotation> *annotation in annotations) {
        auto point = MercatorBounds::FromLatLon(annotation.coordinate.latitude, annotation.coordinate.longitude);
        auto mark = session.CreateUserMark<AnnotationMark>(point);
        auto markIdentifier = mark->GetId();

        _markIdentifiersByAnnotation[annotation] = markIdentifier;
    }
}

- (void)removeAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations {
    NSParameterAssert(annotations != nil);

    auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

    for (NSObject<MWMMapAnnotation> *annotation in annotations) {
        auto iterator = _markIdentifiersByAnnotation.find(annotation);
        auto markIdentifier = iterator->second;

        session.DeleteUserMark(markIdentifier);

        _markIdentifiersByAnnotation.erase(iterator);
    }
}

@end
