//
//  MWMMapEngine.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapEngine.h"
#import "MWMMapEngine+Private.h"
#import "MWMMapEngineDelegate.h"

#import "map/framework.hpp"
#import "drape_frontend/animation_system.hpp"

#import "Framework.h"


@interface MWMMapEngine () {
@public
    Framework *_framework;
}

@property (nonatomic, readonly) BOOL subscribedToApplicationNotifications;
@property (nonatomic, readonly) BOOL isRendering;
@property (nonatomic, readonly) BOOL isPaused;
@property (nonatomic, readonly) BOOL isApplicationActive;
@property (weak, nonatomic, nullable) id<MWMMapEngineDelegate> delegate;

- (void)moveToForeground;
- (void)moveToBackground;

- (void)invalidateRendering;

- (void)enableRendering;
- (void)disableRendering;

- (void)pause;
- (void)resume;

- (void)subscribeToApplicationNotifications;
- (void)unsubscribeFromApplicationNotifications;

- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;

@end

@implementation MWMMapEngine

- (instancetype)init {
    self = [super init];

    if (self) {
        _isPaused = NO;

        _framework = &GetFramework();//new Framework(FrameworkParams(false, true));
        _framework->SetupMeasurementSystem();

        [self pause];
    }

    return self;
}

- (void)dealloc {
    [self unsubscribeFromApplicationNotifications];

    //delete framework;
}

- (BOOL)isAnimating {
    return df::AnimationSystem::Instance().HasMapAnimations();
}

- (void)start {
    if (!_isRendering) {
        _isRendering = YES;

        [self subscribeToApplicationNotifications];

        if (self.isApplicationActive) {
            [self resume];
        }
    }
}

- (void)stop {
    if (_isRendering) {
        _isRendering = NO;

        [self pause];
        [self unsubscribeFromApplicationNotifications];
    }
}

// MARK: - private

- (BOOL)isApplicationActive {
    return (UIApplication.sharedApplication.applicationState == UIApplicationStateActive);
}

// MARK: - private

- (void)moveToForeground {
    _framework->EnterForeground();
}

- (void)moveToBackground {
    _framework->EnterBackground();
}

// MARK: - private

- (void)invalidateRendering {
    _framework->InvalidateRendering();
}

- (void)enableRendering {
    _framework->SetRenderingEnabled();
    // On some devices we have to free all belong-to-graphics memory
    // because of new OpenGL driver powered by Metal.
    //    if ([AppInfo sharedInfo].openGLDriver == MWMOpenGLDriverMetalPre103)
    //    {
    //        m2::PointU const size = ((EAGLView *)self.mapViewController.view).pixelSize;
    //        f.OnRecoverSurface(static_cast<int>(size.x), static_cast<int>(size.y), true /* recreateContextDependentResources */);
    //    }
}

- (void)disableRendering {
    // On some devices we have to free all belong-to-graphics memory
    // because of new OpenGL driver powered by Metal.
    //    if ([AppInfo sharedInfo].openGLDriver == MWMOpenGLDriverMetalPre103)
    //    {
    //        f.SetRenderingDisabled(true);
    //        f.OnDestroySurface();
    //    }
    //    else
    //    {
    _framework->SetRenderingDisabled(false);
    //    }

}

// MARK: - private

- (void)pause {
    if (!_isPaused) {
        _isPaused = YES;

        [self disableRendering];
        [self moveToBackground];
    }
}

- (void)resume {
    if (_isPaused) {
        _isPaused = NO;

        [self moveToForeground];
        [self invalidateRendering];
        [self enableRendering];
    }
}

// MARK: - private

- (void)subscribeToApplicationNotifications {
    if (!_subscribedToApplicationNotifications) {
        _subscribedToApplicationNotifications = YES;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: self
                               selector: @selector(applicationWillResignActive:)
                                   name: UIApplicationWillResignActiveNotification
                                 object: nil];
        [notificationCenter addObserver: self
                               selector: @selector(applicationDidBecomeActive:)
                                   name: UIApplicationDidBecomeActiveNotification
                                 object: nil];
        [notificationCenter addObserver: self
                               selector: @selector(applicationDidReceiveMemoryWarning:)
                                   name: UIApplicationDidReceiveMemoryWarningNotification
                                 object: nil];
    }
}

- (void)unsubscribeFromApplicationNotifications {
    if (_subscribedToApplicationNotifications) {
        _subscribedToApplicationNotifications = NO;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
        [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.delegate mapEngineWillPause:self];

    [self pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self resume];

    [self.delegate mapEngineDidResume:self];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    _framework->MemoryWarning();
}

@end

Framework &MWMMapEngineFramework(MWMMapEngine *engine) {
    return *(engine->_framework);
}
