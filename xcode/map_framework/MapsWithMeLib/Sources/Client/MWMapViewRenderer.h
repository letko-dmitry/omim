//
//  MWMapView.h
//  MapsWithMeLib
//
//  Created by Oleg Sorochich on 10/31/18.
//  Copyright © 2018 Target50. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MWMapDownloadingDelegate.h"

@interface MWMapViewRenderer: NSObject
@property (nonatomic, weak) id<MWMMapDownloadingDelegate> mapDownloadingDelegate;

- (void)setupWithView:(UIView *)view;

- (void)handleViewWillApear;
- (void)handleViewDidDisappear;
- (void)handleViewDidLayoutSubviews;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end

