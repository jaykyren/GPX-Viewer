//
//  GPXRoute+MapKit.m
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <GPX/GPXRoutepoint.h>
#import "GPXRoute+MapKit.h"
#import "MKPointAnnotation+GPX.h"
#import "MKPolyline+GPX.h"

@implementation GPXRoute (MapKit)

- (MKPointAnnotation *)annotation
{
    GPXRoutePoint *routepoint = [self.routepoints lastObject];

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(routepoint.latitude, routepoint.longitude);
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.GPXElement = self;
    annotation.coordinate = coordinate;
    annotation.title = self.name;
    annotation.subtitle = self.comment;
    
    return annotation;
}

- (MKPolyline *)overlay
{
    CLLocationCoordinate2D coors[self.routepoints.count];
    
    int i = 0;
    for (GPXRoutePoint *routepoint in self.routepoints) {
        coors[i] = CLLocationCoordinate2DMake(routepoint.latitude, routepoint.longitude);
        i++;
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coors count:self.routepoints.count];
    polyline.GPXElement = self;
    return polyline;
}

@end
