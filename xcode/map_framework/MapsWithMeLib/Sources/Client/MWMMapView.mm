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
#import "MWMMapEngine+Private.h"
#import "MWMMapEngineSubscriber.h"

#import "MWMMapAnnotationManager.h"
#import "MWMMapAnnotationManager+Private.h"

#import "EAGLView.h"

#import "drape_frontend/user_event_stream.hpp"
#import "drape_frontend/visual_params.hpp"
#import "geometry/screenbase.hpp"
#import "map/framework.hpp"

@interface MWMMapView() <MWMMapEngineSubscriber> {
    BOOL _delegateRespondsToDidChangeRegion;
    BOOL _delegateRespondsToRegionDidChangeAnimated;

    BOOL _didChangeViewportWhileDragging;
    BOOL _didChangeViewportWhileAnimating;

    NSTimeInterval _delayedReportDidChangeViewportTimeInterval;

    ScreenBase _didChangeRegionAnimatedLastViewport;
    ScreenBase _viewport;
}

@property (nonatomic, readonly) EAGLView *mapView;
@property (nonatomic, readonly) NSTimer *delayedReportDidChangeViewportTimer;
@property (nonatomic, readonly) BOOL needsDelayedReportDidChangeViewport;

- (void)createDrapeIfNeeded;

- (void)subscribeToDrapeEvents;
- (void)unsubscribeFromDrapeEvents;

- (void)subscribeToFrameworkEvents;
- (void)unsubscribeFromFrameworkEvents;

- (void)subscribeToEngineEvents;
- (void)unsubscribeFromEngineEvents;

- (void)changeViewport:(ScreenBase)viewport;

- (void)didFinishDragging;
- (void)didChangeViewport;

- (void)reportDidChangeRegionAnimated:(BOOL)animated delayed:(BOOL)delayed;

- (void)setNeedsDelayedReportDidChangeViewportAnimated:(BOOL)animated;
- (void)resetNeedsDelayedReportDidChangeViewport;

@end

@implementation MWMMapView
@synthesize annotationManager = _annotationManager;

- (instancetype)initWithEngine:(MWMMapEngine *)engine {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _engine = engine;
        _mapView = [EAGLView new];

        _delayedReportDidChangeViewportTimeInterval = 0.05;

        [self addSubview:_mapView];

        [self subscribeToFrameworkEvents];
        [self subscribeToEngineEvents];
    }

    return self;
}

- (void)dealloc {
    [self unsubscribeFromEngineEvents];
    [self unsubscribeFromDrapeEvents];
    [self unsubscribeFromFrameworkEvents];
}

- (MWMMapAnnotationManager *)annotationManager {
    NSAssert([NSThread isMainThread], @"The property is expected to be called from the main thread only");

    if (_annotationManager == nil) {
        _annotationManager = [[MWMMapAnnotationManager alloc] initWithEngine:_engine];
    }

    return _annotationManager;
}

- (MWMMapViewRegion *)region {
    NSAssert([NSThread isMainThread], @"The property is expected to be called from the main thread only");

    auto coordinate = MercatorBounds::ToLatLonRect(_viewport.ClipRect());

    return [[MWMMapViewRegion alloc] initWithTopRight: CLLocationCoordinate2DMake(coordinate.maxX(), coordinate.maxY())
                                          bottomLeft: CLLocationCoordinate2DMake(coordinate.minX(), coordinate.minY())];
}

- (void)setDelegate:(id<MWMMapViewDelegate>)delegate {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    if (_delegate != delegate) {
        _delegate = delegate;

        _delegateRespondsToDidChangeRegion = [delegate respondsToSelector:@selector(mapViewDidChangeRegion:)];
        _delegateRespondsToRegionDidChangeAnimated = [delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)];
    }
}

- (void)setRegion:(MWMMapViewRegion *)region edgeInsets:(UIEdgeInsets)edgeInsets animated:(BOOL)animated {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");


    auto viewSize= self.bounds.size;
    auto pointScale = df::VisualParams::Instance().GetVisualScale();
    auto regionCoordinates = m2::RectD(region.bottomLeft.longitude, region.bottomLeft.latitude,
                                 region.topRight.longitude, region.topRight.latitude);

    auto rect = MercatorBounds::FromLatLonRect(regionCoordinates);
    auto rectWidth = rect.SizeX();
    auto rectHeight = rect.SizeY();

    rect.setMaxY(rect.maxY() + rectHeight * (edgeInsets.top / viewSize.height) * pointScale);
    rect.setMinY(rect.minY() - rectHeight * (edgeInsets.bottom / viewSize.height) * pointScale);
    rect.setMaxX(rect.maxX() + rectWidth * (edgeInsets.right / viewSize.width) * pointScale);
    rect.setMinX(rect.minX() - rectWidth * (edgeInsets.left / viewSize.width) * pointScale);

    MWMMapEngineFramework(_engine).ShowRect(rect, -1, animated);
}

// MARK: - UIView

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window != nil) {
        [_engine start];
    } else {
        [_engine stop];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _mapView.frame = self.bounds;

    [self createDrapeIfNeeded];
}

// MARK: - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    _isTracking = YES;
    _isDragging = NO;

    [self sendTouchType:df::TouchEvent::TOUCH_DOWN withTouches:touches andEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    _isTracking = NO;
    _isDragging = YES;

    [self sendTouchType:df::TouchEvent::TOUCH_MOVE withTouches:nil andEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    BOOL isDragging = _isDragging;

    _isTracking = NO;
    _isDragging = NO;

    [self sendTouchType:df::TouchEvent::TOUCH_UP withTouches:touches andEvent:event];

    if (isDragging) {
        [self didFinishDragging];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];

    BOOL isDragging = _isDragging;

    _isTracking = NO;
    _isDragging = NO;

    [self sendTouchType:df::TouchEvent::TOUCH_CANCEL withTouches:touches andEvent:event];

    if (isDragging) {
        [self didFinishDragging];
    }
}

// MARK: - private

- (void)sendTouchType:(df::TouchEvent::ETouchType)type
          withTouches:(NSSet *)touches
             andEvent:(UIEvent *)event {
    NSArray<UITouch *> *allTouches = event.allTouches.allObjects;

    if (allTouches.count == 0) {
        return;
    }

    CGFloat scaleFactor = _mapView.contentScaleFactor;

    df::TouchEvent touchEvent;
    touchEvent.SetTouchType(type);

    UITouch *firstTouch = [allTouches objectAtIndex:0];
    CGPoint firstTouchLocation = [firstTouch locationInView:_mapView];

    df::Touch t0;
    t0.m_location = m2::PointD(firstTouchLocation.x * scaleFactor, firstTouchLocation.y * scaleFactor);
    t0.m_id = reinterpret_cast<int64_t>(firstTouch);

    touchEvent.SetFirstTouch(t0);

    if (allTouches.count > 1) {
        UITouch *secondTouch = [allTouches objectAtIndex:1];
        CGPoint secondTouchLocation = [secondTouch locationInView:_mapView];

        df::Touch t1;
        t1.m_location = m2::PointD(secondTouchLocation.x * scaleFactor, secondTouchLocation.y * scaleFactor);
        t1.m_id = reinterpret_cast<int64_t>(secondTouch);

        touchEvent.SetSecondTouch(t1);
    }

    MWMMapEngineFramework(_engine).TouchEvent(touchEvent);
}

// MARK: - private

- (void)createDrapeIfNeeded {
    if (!_mapView.drapeEngineCreated) {
        [_mapView createDrapeEngine];

        [self subscribeToDrapeEvents];
    }
}

- (void)subscribeToDrapeEvents {
    auto &framework = MWMMapEngineFramework(_engine);
    auto drape = framework.GetDrapeEngine();

    drape->SetUserPositionListener(nil);
    drape->SetTapEventInfoListener([self] (df::TapInfo const &tapInfo) {
        auto tapInfoCopy = tapInfo;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_annotationManager handleTap:tapInfoCopy inViewport:self->_viewport];
        });
    });
}

- (void)unsubscribeFromDrapeEvents {
    auto &framework = MWMMapEngineFramework(_engine);
    auto drape = framework.GetDrapeEngine();

    drape->SetUserPositionListener(nil);
    drape->SetTapEventInfoListener(nil);
}

- (void)subscribeToFrameworkEvents {
    auto &framework = MWMMapEngineFramework(_engine);

    framework.SetViewportListener([self] (ScreenBase const &viewport) {
        [self changeViewport:viewport];
    });
}

- (void)unsubscribeFromFrameworkEvents {
    auto &framework = MWMMapEngineFramework(_engine);
    framework.SetViewportListener(nil);
}

- (void)subscribeToEngineEvents {
    [_engine subscribe:self];
}

- (void)unsubscribeFromEngineEvents {
    [_engine unsubscribe:self];
}

// MARK: - private

- (void)changeViewport:(ScreenBase)viewport {
    _viewport = viewport;

    [self didChangeViewport];
}

// MARK: - private

- (void)didFinishDragging {
    if (_didChangeViewportWhileDragging) {
        _didChangeViewportWhileDragging = NO;

        if (!_engine.isAnimating) {
            [self reportDidChangeRegionAnimated:NO delayed:YES];
        }
    }
}

- (void)didChangeViewport {
    BOOL isDrugging = _isDragging;
    BOOL isAnimating = _engine.isAnimating;

    if (_delegateRespondsToDidChangeRegion) {
        [_delegate mapViewDidChangeRegion:self];
    }

    if (!isDrugging && !isAnimating) {
        BOOL didChangeRegionWhileAnimating = _didChangeViewportWhileAnimating;

        _didChangeViewportWhileDragging = NO;
        _didChangeViewportWhileAnimating = NO;

        if (self.needsDelayedReportDidChangeViewport) {
            if (didChangeRegionWhileAnimating) {
                [self reportDidChangeRegionAnimated:YES delayed:NO];
            }
        } else {
             [self reportDidChangeRegionAnimated:didChangeRegionWhileAnimating delayed:NO];
        }
    } else {
        _didChangeViewportWhileDragging |= isDrugging;
        _didChangeViewportWhileAnimating |= isAnimating;

        [self resetNeedsDelayedReportDidChangeViewport];
    }
}

// MARK: - private

- (BOOL)needsDelayedReportDidChangeViewport {
    return (_delayedReportDidChangeViewportTimer != nil);
}

- (void)reportDidChangeRegionAnimated:(BOOL)animated delayed:(BOOL)delayed {
    [self resetNeedsDelayedReportDidChangeViewport];

    if (_delegateRespondsToRegionDidChangeAnimated) {

        if (_didChangeRegionAnimatedLastViewport != _viewport) {
            if (delayed) {
                [self setNeedsDelayedReportDidChangeViewportAnimated:animated];
            } else {
                _didChangeRegionAnimatedLastViewport = _viewport;

                [_delegate mapView:self regionDidChangeAnimated:animated];
            }
        }
    }
}

- (void)setNeedsDelayedReportDidChangeViewportAnimated:(BOOL)animated {
    [self resetNeedsDelayedReportDidChangeViewport];

    __weak auto selfWeak = self;

    _delayedReportDidChangeViewportTimer = [NSTimer scheduledTimerWithTimeInterval:_delayedReportDidChangeViewportTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
        [selfWeak resetNeedsDelayedReportDidChangeViewport];
        [selfWeak reportDidChangeRegionAnimated:animated delayed:NO];
    }];
}

- (void)resetNeedsDelayedReportDidChangeViewport {
    if (_delayedReportDidChangeViewportTimer) {
        [_delayedReportDidChangeViewportTimer invalidate];
        _delayedReportDidChangeViewportTimer = nil;
    }
}

// MARK: - MWMMapEngineSubscriber

- (void)mapEngineWillPause:(MWMMapEngine *)engine {
    [_mapView setPresentAvailable:NO];
}

- (void)mapEngineDidResume:(MWMMapEngine *)engine {
    [_mapView setPresentAvailable:YES];
}

@end
