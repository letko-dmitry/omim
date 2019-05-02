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
#import "MWMMapEngineSubscriber.h"

#import "AnnotationMark.hpp"

#import "map/framework.hpp"
#import "drape_frontend/frontend_renderer.hpp"
#import "geometry/screenbase.hpp"


static const size_t MWMMapAnnotationManagerMarksCacheSizeMax = 5000;

@interface MWMMapAnnotationManager () <MWMMapEngineSubscriber> {
    std::map<id<MWMMapAnnotation>, kml::MarkId> _markIdentifiersByAnnotation;
    std::unordered_map<kml::MarkId, id<MWMMapAnnotation>> _annotationsByMarkIdentifiers;
    std::vector<AnnotationMark *> _marksCache;
}

- (void)deselectAnnotationAutomatically;

@end

@implementation MWMMapAnnotationManager

- (instancetype)initWithEngine:(MWMMapEngine *)engine {
    NSParameterAssert(engine != nil);

    self = [super init];

    if (self) {
        _engine = engine;

        [self subscribeToEngineEvents];
    }

    return self;
}

- (void)dealloc {
    [self unsubscribeFromEngineEvents];
}

- (void)addAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");
    NSParameterAssert(annotations != nil);

    auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

    for (id<MWMMapAnnotation> annotation in annotations) {
        auto point = MercatorBounds::FromLatLon(annotation.coordinate.latitude, annotation.coordinate.longitude);

        AnnotationMark *mark;

        if (_marksCache.empty()) {
            mark = session.CreateUserMark<AnnotationMark>(point);
        } else {
            mark = _marksCache.back();
            mark->SetPtOrg(point);
            mark->SetHidden(false);

            _marksCache.pop_back();
        }

        if (annotation == _selectedAnnotation) {
            mark->SetSymbol(annotation.selectedSymbol.UTF8String);
        } else {
            mark->SetSymbol(annotation.symbol.UTF8String);
        }

        auto markIdentifier = mark->GetId();

        _markIdentifiersByAnnotation[annotation] = markIdentifier;
        _annotationsByMarkIdentifiers[markIdentifier] = annotation;
    }
}

- (void)removeAnnotations:(NSSet<id<MWMMapAnnotation>> *)annotations {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");
    NSParameterAssert(annotations != nil);

    _marksCache.reserve(min(_marksCache.size() + annotations.count, MWMMapAnnotationManagerMarksCacheSizeMax));

    auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

    for (NSObject<MWMMapAnnotation> *annotation in annotations) {
        auto iterator = _markIdentifiersByAnnotation.find(annotation);
        auto markIdentifier = iterator->second;

        if (_marksCache.size() < MWMMapAnnotationManagerMarksCacheSizeMax) {
            auto mark = session.GetMarkForEdit<AnnotationMark>(markIdentifier);
            mark->SetHidden(true);

            _marksCache.push_back(mark);
        } else {
            session.DeleteUserMark(markIdentifier);
        }

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
            mark->SetSymbol(annotation.selectedSymbol.UTF8String);

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
            mark->SetSymbol(_selectedAnnotation.symbol.UTF8String);
        }
    }

    _selectedAnnotation = nil;
}

- (void)handleTap:(df::TapInfo)tapInfo inViewport:(ScreenBase)viewport {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    auto &manager = MWMMapEngineFramework(_engine).GetBookmarkManager();

    auto rect = tapInfo.GetDefaultSearchRect(viewport);
    auto distance = numeric_limits<double>().max();
    auto mark = manager.FindMarkInRect(UserMark::Type::STATIC, rect, true, distance);

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
    if (_selectedAnnotation) {
        id<MWMMapAnnotation> selectedAnnotationOld = _selectedAnnotation;

        [self deselectAnnotation];
        [self.delegate mapAnnotationManager:self didDeselect:selectedAnnotationOld];
    }
}

- (void)purge {
    if (!_marksCache.empty()) {
        auto session = MWMMapEngineFramework(_engine).GetBookmarkManager().GetEditSession();

        for (auto mark : _marksCache) {
            session.DeleteUserMark(mark->GetId());
        }

        _marksCache.resize(0);
    }
}

// MARK: - private

- (void)subscribeToEngineEvents {
    [_engine subscribe:self];
}

- (void)unsubscribeFromEngineEvents {
    [_engine unsubscribe:self];
}

// MARK: - MWMMapEngineSubscriber

- (void)mapEngineWillPurge:(MWMMapEngine *)engine {
    [self purge];
}

- (void)mapEngineWillPause:(MWMMapEngine *)engine {
    [self purge];
}

- (void)mapEngineDidResume:(MWMMapEngine *)engine {
    // empty implementation
}

@end
