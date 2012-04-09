//
//  MKPolyline+GPX.m
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <objc/runtime.h>
#import "MKPolyline+GPX.h"

@implementation MKPolyline (GPX)

- (GPXElement *)GPXElement
{
    return objc_getAssociatedObject(self, "kMKShapeGPXElementKey");
    
}

- (void)setGPXElement:(GPXElement *)element
{
    objc_setAssociatedObject(self, "kMKShapeGPXElementKey", element, OBJC_ASSOCIATION_RETAIN);
}

@end
