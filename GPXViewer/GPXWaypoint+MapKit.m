//
//  GPXWaypoint+MapKit.m
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "GPXWaypoint+MapKit.h"
#import "MKPointAnnotation+GPX.h"


@implementation GPXWaypoint (MapKit)

- (MKPointAnnotation *)annotation
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.GPXElement = self;
    annotation.coordinate = coordinate;
    annotation.title = self.name;
    annotation.subtitle = self.comment;
    
    return annotation;
}

@end
