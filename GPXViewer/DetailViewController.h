//
//  DetailViewController.h
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <GPX/GPXElement.h>

@interface DetailViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) GPXElement *GPXElement;

@end
