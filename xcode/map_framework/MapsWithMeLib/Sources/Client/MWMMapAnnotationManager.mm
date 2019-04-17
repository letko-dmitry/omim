//
//  MWMMapAnnotationManager.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapAnnotationManager.h"
#import "MWMMapAnnotationManager+Private.h"
#import "MWMMapAnnotationManagerDelegate.h"
#import "MWMMapAnnotation.h"
#import "MWMMapEngine.h"
#import "MWMMapEngine+Private.h"

#import "AnnotationMark.hpp"

#import "map/framework.hpp"
#import "drape_frontend/frontend_renderer.hpp"
#import "geometry/screenbase.hpp"


@interface MWMMapAnnotationManager () {
    std::map<id<MWMMapAnnotation>, kml::MarkId> _markIdentifiersByAnnotation;
    std::map<kml::MarkId, id<MWMMapAnnotation>> _annotationsByMarkIdentifiers;
}

- (void)deselectAnnotationAutomatically;

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
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");
    NSParameterAssert(annotations != nil);

    auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

    for (NSObject<MWMMapAnnotation> *annotation in annotations) {
        auto point = MercatorBounds::FromLatLon(annotation.coordinate.latitude, annotation.coordinate.longitude);
        auto mark = session.CreateUserMark<AnnotationMark>(point);
        auto markIdentifier = mark->GetId();

        _markIdentifiersByAnnotation[annotation] = markIdentifier;
        _annotationsByMarkIdentifiers[markIdentifier] = annotation;
    }
}

- (void)removeAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");
    NSParameterAssert(annotations != nil);

    auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

    for (NSObject<MWMMapAnnotation> *annotation in annotations) {
        auto iterator = _markIdentifiersByAnnotation.find(annotation);
        auto markIdentifier = iterator->second;

        session.DeleteUserMark(markIdentifier);

        _markIdentifiersByAnnotation.erase(iterator);
        _annotationsByMarkIdentifiers.erase(markIdentifier);
    }
}

- (void)selectAnnotation:(id<MWMMapAnnotation>)annotation {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");
    NSParameterAssert(annotation != nil);

    if (_selectedAnnotation == annotation) {
        return;
    }

    [self deselectAnnotationAutomatically];

    auto markIdentifier = _markIdentifiersByAnnotation[annotation];

    if (markIdentifier != kml::kInvalidMarkId) {
        auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();
        auto mark = session.GetMarkForEdit<AnnotationMark>(markIdentifier);

        if (mark != nullptr) {
            mark->SetSelected(true);

            _selectedAnnotation = annotation;
        }
    }
}

- (void)deselectAnnotation {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    if (_selectedAnnotation == nil) {
        return;
    }

    auto markIdentifier = _markIdentifiersByAnnotation[_selectedAnnotation];

    if (markIdentifier != kml::kInvalidMarkId) {
        auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();
        auto mark = session.GetMarkForEdit<AnnotationMark>(markIdentifier);

        if (mark != nullptr) {
            mark->SetSelected(false);
        }
    }

    _selectedAnnotation = nil;
}

- (void)handleTap:(df::TapInfo)tapInfo inViewport:(ScreenBase)viewport {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    auto &manager = MWMMapEngineFramework(_engine).GetBookmarkManager();

    auto rect = tapInfo.GetDefaultSearchRect(viewport);
    auto distance = numeric_limits<double>().max();
    auto mark = manager.FindMarkInRect(UserMark::Type::STATIC, rect, distance);

    if (mark == nil) {
        [self deselectAnnotationAutomatically];
    } else {
        auto annotation = _annotationsByMarkIdentifiers[mark->GetId()];

        if (annotation == nil) {
            [self deselectAnnotationAutomatically];
        } else {
            if (_selectedAnnotation != annotation) {
                [self selectAnnotation:annotation];
                [self.delegate mapAnnotationManager:self didSelect:annotation];
            }
        }
    }
}

// MARK: - private

- (void)deselectAnnotationAutomatically {
    if (_selectedAnnotation != nil) {
        id<MWMMapAnnotation> selectedAnnotationOld = _selectedAnnotation;

        [self deselectAnnotation];
        [self.delegate mapAnnotationManager:self didDeselect:selectedAnnotationOld];
    }
}

@end
