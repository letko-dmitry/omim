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
#import "MWMMapEngineDelegate.h"

#import "MWMMapDownloader.h"
#import "MWMFrameworkListener.h"

#import "EAGLView.h"

#import "drape_frontend/user_event_stream.hpp"
#import "map/framework.hpp"

@interface MWMMapView() <MWMFrameworkDrapeObserver, MWMMapEngineDelegate> {
    BOOL _delegateRespondsToDidChangeRegion;
    BOOL _delegateRespondsToRegionDidChangeAnimated;

    BOOL _didChangeRegionWhileDragging;
    BOOL _didChangeRegionWhileAnimating;

    m2::RectD _didChangeRegionAnimatedLastViewport;
}

@property (nonatomic, readonly) EAGLView *mapView;
@property (nonatomic, readonly) MWMMapDownloader *mapDownloader;

@end

@implementation MWMMapView

- (instancetype)initWithEngine:(MWMMapEngine *)engine {
    NSParameterAssert(engine.delegate == nil);

    self = [super initWithFrame:CGRectZero];

    if (self) {
        _engine = engine;
        _engine.delegate = self;
        _mapView = [EAGLView new];
        _mapDownloader = [MWMMapDownloader new];

        [self addSubview:_mapView];

        [MWMFrameworkListener addObserver:self];
    }

    return self;
}

- (void)dealloc {
    _engine.delegate = nil;
    
    [MWMFrameworkListener removeObserver:self];
}

- (MWMMapViewRegion *)region {
    auto &framework = MWMMapEngineFramework(_engine);
    auto coordinate = MercatorBounds::ToLatLonRect(framework.GetCurrentViewport());

    return [[MWMMapViewRegion alloc] initWithTopRight: CLLocationCoordinate2DMake(coordinate.maxX(), coordinate.maxY())
                                          bottomLeft: CLLocationCoordinate2DMake(coordinate.minX(), coordinate.minY())];
}

- (void)setDelegate:(id<MWMMapViewDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;

        _delegateRespondsToDidChangeRegion = [delegate respondsToSelector:@selector(mapViewDidChangeRegion:)];
        _delegateRespondsToRegionDidChangeAnimated = [delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)];
    }
}

- (void)showRegion:(MWMMapViewRegion *)region animated:(BOOL)animated {
    auto coordinates = m2::RectD(region.bottomLeft.latitude, region.bottomLeft.longitude, region.topRight.latitude, region.topRight.longitude);
    auto rect = MercatorBounds::FromLatLonRect(coordinates);
    auto &framework = MWMMapEngineFramework(_engine);


    if (animated) {
        framework.ShowRect(rect);
    } else {
        framework.SetVisibleViewport(rect);
    }
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

    if (!_mapView.drapeEngineCreated) {
        [_mapView createDrapeEngine];

        auto &framework = MWMMapEngineFramework(_engine);
        auto drape = framework.GetDrapeEngine();

        drape->SetTapEventInfoListener([self] (df::TapInfo const &tapInfo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"lol");
            });
        });
    }
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

- (void)didFinishDragging {
    if (_didChangeRegionWhileDragging) {
        _didChangeRegionWhileDragging = NO;

        if (!_engine.isAnimating) {
            [self didChangeRegionAnimated:NO];
        }
    }
}

- (void)didChangeRegionAnimated:(BOOL)animated {
    if (_delegateRespondsToRegionDidChangeAnimated) {
        auto &framework = MWMMapEngineFramework(_engine);
        auto viewport = framework.GetCurrentViewport();

        if (_didChangeRegionAnimatedLastViewport != viewport) {
            _didChangeRegionAnimatedLastViewport = viewport;

            [_delegate mapView:self regionDidChangeAnimated:NO];
        }
    }
}

// MARK: - MWMFrameworkDrapeObserver

- (void)processViewportCountryEvent:(CountryId const &)countryId {
    // [self.mapDownloader downloadCountry:countryId];
}

- (void)processViewportChangedEvent {
    BOOL isDrugging = _isDragging;
    BOOL isAnimating = _engine.isAnimating;

    if (_delegateRespondsToDidChangeRegion) {
        [_delegate mapViewDidChangeRegion:self];
    }

    if (!isDrugging && !isAnimating) {
        BOOL didChangeRegionWhileAnimating = _didChangeRegionWhileAnimating;

        _didChangeRegionWhileDragging = NO;
        _didChangeRegionWhileAnimating = NO;

        [self didChangeRegionAnimated:didChangeRegionWhileAnimating];
    } else {
        _didChangeRegionWhileDragging |= isDrugging;
        _didChangeRegionWhileAnimating |= isAnimating;
    }
}

// MARK: - MWMMapEngineDelegate

- (void)mapEngineWillPause:(MWMMapEngine *)engine {
    [_mapView setPresentAvailable:NO];
}

- (void)mapEngineDidResume:(MWMMapEngine *)engine {
    [_mapView setPresentAvailable:YES];
}

@end
