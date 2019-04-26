//
//  MWMMapEngine.m
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/12/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "MWMMapEngine.h"
#import "MWMMapEngine+Private.h"
#import "MWMMapEngineSubscriber.h"
#import "MWMMapCountry.h"

#import "base/logging.hpp"
#import "base/assert.hpp"
#import "platform/platform.hpp"
#import "platform/local_country_file_utils.hpp"
#import "map/framework.hpp"
#import "drape_frontend/animation_system.hpp"


@interface MWMMapEngine () {
@public
    Framework *_framework;
}

@property (nonatomic, readonly) NSHashTable<id<MWMMapEngineSubscriber>> *subscibers;
@property (nonatomic, readonly) BOOL subscribedToApplicationNotifications;
@property (nonatomic, readonly) BOOL isRendering;
@property (nonatomic, readonly) BOOL isPaused;
@property (nonatomic, readonly) BOOL isApplicationActive;

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

+ (void)initialize {
#ifndef DEBUG
    base::SetLogMessageFn([] (base::LogLevel level, base::SrcPoint const &, std::string const &) { });
    base::SetAssertFunction([] (base::SrcPoint const & srcPoint, std::string const & msg) { return true; });
#endif
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _isPaused = NO;

        _framework = new Framework(FrameworkParams(false, true));
        _framework->SetupMeasurementSystem();

        [self pause];
    }

    return self;
}

- (void)dealloc {
    [self unsubscribeFromApplicationNotifications];

    delete _framework; _framework = nullptr;
}

- (BOOL)isAnimating {
    NSAssert([NSThread isMainThread], @"The property is expected to be called from the main thread only");

    return df::AnimationSystem::Instance().HasMapAnimations();
}

- (void)start {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    if (!_isRendering) {
        _isRendering = YES;

        [self subscribeToApplicationNotifications];

        if (self.isApplicationActive) {
            [self resume];
        }
    }
}

- (void)stop {
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    if (_isRendering) {
        _isRendering = NO;

        [self pause];
        [self unsubscribeFromApplicationNotifications];
    }
}

- (void)subscribe:(id<MWMMapEngineSubscriber>)subscriber {
    NSParameterAssert(subscriber != nil);
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    if (_subscibers == nil) {
        _subscibers = [NSHashTable weakObjectsHashTable];
    }

    [_subscibers addObject:subscriber];
}

- (void)unsubscribe:(id<MWMMapEngineSubscriber>)subscriber {
    NSParameterAssert(subscriber != nil);
    NSAssert([NSThread isMainThread], @"The method is expected to be called from the main thread only");

    [_subscibers removeObject:subscriber];

    if (_subscibers.allObjects.count == 0) {
        _subscibers = nil;
    }
}

- (void)loadCountry:(MWMMapCountry *)country {
    NSParameterAssert(country != nil);

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        auto fileUrl = country.fileUrl;
        auto fileName = platform::CountryFile(fileUrl.URLByDeletingPathExtension.lastPathComponent.UTF8String);
        auto file = platform::LocalCountryFile(fileUrl.URLByDeletingLastPathComponent.path.UTF8String, fileName, country.version);

        file.SyncWithDisk();

        dispatch_async(dispatch_get_main_queue(), ^{
            self->_framework->OnCountryFileDownloaded(country.identifier.UTF8String, std::make_shared<platform::LocalCountryFile>(file));
        });
    });
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
    [_subscibers.allObjects makeObjectsPerformSelector:@selector(mapEngineWillPause:) withObject:self];

    [self pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self resume];

    [_subscibers.allObjects makeObjectsPerformSelector:@selector(mapEngineDidResume:) withObject:self];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    _framework->MemoryWarning();
}

@end

Framework &MWMMapEngineFramework(MWMMapEngine *engine) {
    return *(engine->_framework);
}
