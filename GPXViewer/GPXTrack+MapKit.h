//
//  GPXTrack+MapKit.h
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <GPX/GPXTrack.h>
#import <MapKit/MapKit.h>

@interface GPXTrack (MapKit)

- (MKPointAnnotation *)annotation;
- (NSArray *)overlays;

@end
