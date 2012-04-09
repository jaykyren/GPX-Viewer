//
//  GPXRoute+MapKit.h
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <GPX/GPXRoute.h>
#import <MapKit/MapKit.h>

@interface GPXRoute (MapKit)

- (MKPointAnnotation *)annotation;
- (MKPolyline *)overlay;

@end
