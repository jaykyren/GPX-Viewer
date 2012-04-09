//
//  GPXTrack+MapKit.m
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <GPX/GPXTrackSegment.h>
#import <GPX/GPXTrackpoint.h>
#import "GPXTrack+MapKit.h"
#import "MKPointAnnotation+GPX.h"
#import "MKPolyline+GPX.h"


@implementation GPXTrack (MapKit)

- (MKPointAnnotation *)annotation
{
    if (self.tracksegments.count == 0) {
        return nil;
    }

    GPXTrackSegment *trackSegment = [self.tracksegments objectAtIndex:0];
    
    if (trackSegment.trackpoints.count == 0) {
        return nil;
    }
    
    GPXTrackPoint *trackpoint = [trackSegment.trackpoints objectAtIndex:0];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(trackpoint.latitude, trackpoint.longitude);
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.GPXElement = self;
    annotation.coordinate = coordinate;
    annotation.title = self.name;
    annotation.subtitle = self.comment;
    
    return annotation;
}

- (NSArray *)overlays
{
    NSMutableArray *overlays = [NSMutableArray array];
    for (GPXTrackSegment *trackSegment in self.tracksegments) {
        CLLocationCoordinate2D coors[trackSegment.trackpoints.count];
        
        int i = 0;
        for (GPXTrackPoint *trackpoint in trackSegment.trackpoints) {
            coors[i] = CLLocationCoordinate2DMake(trackpoint.latitude, trackpoint.longitude);
            i++;
        }
        
        MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coors count:trackSegment.trackpoints.count];
        polyline.GPXElement = self;
        
        [overlays addObject:polyline];
    }

    return overlays;
}

@end
