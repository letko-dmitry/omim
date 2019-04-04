//
//  MWMapView.m
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import "MWMapViewRenderer.h"
#import "MWMMapDownloader.h"
#import "MWMFrameworkListener.h"
#import "EAGLView.h"

#import "drape_frontend/user_event_stream.hpp"
#import "framework.h"


@interface MWMapViewRenderer() <MWMFrameworkDrapeObserver, MWMFrameworkStorageObserver>
@property (nonatomic) EAGLView *mapView;
@property (nonatomic) MWMMapDownloader *mapDownloader;

- (void)invalidateRendering;

- (void)subscribeToApplicationNotifications;
- (void)unsubscribeFromApplicationNotifications;

@end

@implementation MWMapViewRenderer

- (instancetype)init {
    self = [super init];

    if (self) {
        self.mapView = [EAGLView new];
        self.mapDownloader = [MWMMapDownloader new];

        auto &framework = GetFramework();
        framework.SetupMeasurementSystem();
    }

    return self;
}

- (void)dealloc {
    [self unsubscribeFromApplicationNotifications];
}

- (void)setupWithView:(UIView *)view {
    [MWMFrameworkListener addObserver:self];

    [view addSubview:self.mapView];
}

- (void)handleViewWillApear {
    [self invalidateRendering];
    [self subscribeToApplicationNotifications];
}

- (void)handleViewDidDisappear {
    [self unsubscribeFromApplicationNotifications];
}

- (void)handleViewDidLayoutSubviews {
    self.mapView.frame = self.mapView.superview.bounds;

    if (!self.mapView.drapeEngineCreated) {
        [self.mapView createDrapeEngine];
    }
}

- (void)setMapDownloadingDelegate:(id<MWMMapDownloadingDelegate>)mapDownloadingDelegate {
    self.mapDownloader.delegate = mapDownloadingDelegate;
}

// MARK: - Touches handling

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
    
    Framework & f = GetFramework();
    f.TouchEvent(e);
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouchType:df::TouchEvent::TOUCH_DOWN withTouches:touches andEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouchType:df::TouchEvent::TOUCH_MOVE withTouches:nil andEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouchType:df::TouchEvent::TOUCH_UP withTouches:touches andEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouchType:df::TouchEvent::TOUCH_CANCEL withTouches:touches andEvent:event];
}

// MARK: - MWMFrameworkDrapeObserver

- (void)processViewportCountryEvent:(CountryId const &)countryId {
    [self.mapDownloader downloadCountry:countryId];
}

// MARK: - MWMFrameworkStorageObserver

- (void)processCountryEvent:(CountryId const &)countryId {
    
}

- (void)enableRendering {
    auto &framework = GetFramework();
    framework.SetRenderingEnabled();
    // On some devices we have to free all belong-to-graphics memory
    // because of new OpenGL driver powered by Metal.
//    if ([AppInfo sharedInfo].openGLDriver == MWMOpenGLDriverMetalPre103)
//    {
//        m2::PointU const size = ((EAGLView *)self.mapViewController.view).pixelSize;
//        f.OnRecoverSurface(static_cast<int>(size.x), static_cast<int>(size.y), true /* recreateContextDependentResources */);
//    }
}

- (void)disableRendering {
    auto &framework = GetFramework();
    // On some devices we have to free all belong-to-graphics memory
    // because of new OpenGL driver powered by Metal.
//    if ([AppInfo sharedInfo].openGLDriver == MWMOpenGLDriverMetalPre103)
//    {
//        f.SetRenderingDisabled(true);
//        f.OnDestroySurface();
//    }
//    else
//    {
        framework.SetRenderingDisabled(false);
//    }

}

- (void)moveToForeground {
    GetFramework().EnterForeground();
}

- (void)moveToBackground {
    GetFramework().EnterBackground();
}

- (void)invalidateRendering {
    GetFramework().InvalidateRendering();
}

- (void)subscribeToApplicationNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: self
                           selector: @selector(applicationWillResignActive:)
                               name: UIApplicationWillResignActiveNotification
                             object: nil];
    [notificationCenter addObserver: self
                           selector: @selector(applicationDidBecomeActive:)
                               name: UIApplicationDidBecomeActiveNotification
                             object: nil];
}

- (void)unsubscribeFromApplicationNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.mapView setPresentAvailable:NO];
    [self disableRendering];
    [self moveToBackground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    [self moveToForeground];
    [self.mapView setPresentAvailable:YES];
    [self enableRendering];
}

@end
