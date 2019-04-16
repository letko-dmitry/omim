//
//  MWMMapView.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/16/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapView.h"
#import "MWMMapViewDelegate.h"
#import "MWMMapViewRegion.h"
#import "MWMMapEngine.h"
#import "MWMMapDownloader.h"
#import "MWMapDownloadingDelegate.h"
#import "MWMFrameworkListener.h"
#import "EAGLView.h"

#import "drape_frontend/user_event_stream.hpp"
#import "map/framework.hpp"

@interface MWMMapView() <MWMFrameworkDrapeObserver>
@property (nonatomic, readonly) EAGLView *mapView;
@property (nonatomic, readonly) MWMMapDownloader *mapDownloader;

- (void)invalidateRendering;

@end

@implementation MWMMapView

- (instancetype)initWithEngine:(MWMMapEngine *)engine {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _engine = engine;
        _mapView = [EAGLView new];
        _mapDownloader = [MWMMapDownloader new];

        [self addSubview:_mapView];

        [MWMFrameworkListener addObserver:self];
    }

    return self;
}

- (void)dealloc {
    [MWMFrameworkListener removeObserver:self];
}

- (MWMMapViewRegion *)region {
    auto &framework = MWMMapEngineFramework(_engine);
    auto coordinate = MercatorBounds::ToLatLonRect(framework.GetCurrentViewport());

    return [[MWMMapViewRegion alloc] initWithTopRight: CLLocationCoordinate2DMake(coordinate.maxX(), coordinate.maxY())
                                          bottomLeft: CLLocationCoordinate2DMake(coordinate.minX(), coordinate.minY())];
}

- (void)showRegion:(MWMMapViewRegion *)region animated:(BOOL)animated {
    auto rect = m2::RectD(region.bottomLeft.latitude, region.bottomLeft.longitude, region.topRight.latitude, region.topRight.longitude);
    auto viewport = MercatorBounds::FromLatLonRect(rect);

    MWMMapEngineFramework(_engine).SetVisibleViewport(viewport);
}

// MARK: - UIView

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window != nil) {
        [self invalidateRendering];
        [self subscribeToApplicationNotifications];
    } else {
        [self unsubscribeFromApplicationNotifications];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _mapView.frame = self.bounds;

    if (!_mapView.drapeEngineCreated) {
        [_mapView createDrapeEngine];
    }
}

// MARK: - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    [self sendTouchType:df::TouchEvent::TOUCH_DOWN withTouches:touches andEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    [self sendTouchType:df::TouchEvent::TOUCH_MOVE withTouches:nil andEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    [self sendTouchType:df::TouchEvent::TOUCH_UP withTouches:touches andEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];

    [self sendTouchType:df::TouchEvent::TOUCH_CANCEL withTouches:touches andEvent:event];
}

// MARK: - private

- (void)sendTouchType:(df::TouchEvent::ETouchType)type
          withTouches:(NSSet *)touches
             andEvent:(UIEvent *)event {
    NSArray * allTouches = [[event allTouches] allObjects];
    if ([allTouches count] < 1)
        return;

    UIView * v = self.mapView;
    CGFloat const scaleFactor = v.contentScaleFactor;

    df::TouchEvent e;
    UITouch * touch = [allTouches objectAtIndex:0];
    CGPoint const pt = [touch locationInView:v];

    e.SetTouchType(type);

    df::Touch t0;
    t0.m_location = m2::PointD(pt.x * scaleFactor, pt.y * scaleFactor);
    t0.m_id = reinterpret_cast<int64_t>(touch);
    if ([self hasForceTouch])
        t0.m_force = touch.force / touch.maximumPossibleForce;
    e.SetFirstTouch(t0);

    if (allTouches.count > 1)
    {
        UITouch * touch = [allTouches objectAtIndex:1];
        CGPoint const pt = [touch locationInView:v];

        df::Touch t1;
        t1.m_location = m2::PointD(pt.x * scaleFactor, pt.y * scaleFactor);
        t1.m_id = reinterpret_cast<int64_t>(touch);
        if ([self hasForceTouch])
            t1.m_force = touch.force / touch.maximumPossibleForce;
        e.SetSecondTouch(t1);
    }

    NSArray * toggledTouches = [touches allObjects];
    if (toggledTouches.count > 0)
        [self checkMaskedPointer:[toggledTouches objectAtIndex:0] withEvent:e];

    if (toggledTouches.count > 1)
        [self checkMaskedPointer:[toggledTouches objectAtIndex:1] withEvent:e];

    MWMMapEngineFramework(_engine).TouchEvent(e);
}

- (BOOL)hasForceTouch {
    return self.mapView.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
}

- (void)checkMaskedPointer:(UITouch *)touch withEvent:(df::TouchEvent &)e
{
    int64_t id = reinterpret_cast<int64_t>(touch);
    int8_t pointerIndex = df::TouchEvent::INVALID_MASKED_POINTER;
    if (e.GetFirstTouch().m_id == id)
        pointerIndex = 0;
    else if (e.GetSecondTouch().m_id == id)
        pointerIndex = 1;

    if (e.GetFirstMaskedPointer() == df::TouchEvent::INVALID_MASKED_POINTER)
        e.SetFirstMaskedPointer(pointerIndex);
    else
        e.SetSecondMaskedPointer(pointerIndex);
}

// MARK: - MWMFrameworkDrapeObserver

- (void)processViewportCountryEvent:(CountryId const &)countryId {
    // [self.mapDownloader downloadCountry:countryId];
}

- (void)processViewportChangedEvent {
    [_delegate mapViewRendererDidChangeRegion:self];
}

@end
