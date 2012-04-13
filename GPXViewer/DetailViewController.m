//
//  DetailViewController.m
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <GPX/GPX.h>
#import "DetailViewController.h"

@implementation DetailViewController

@synthesize webView = __webView;
@synthesize GPXElement = __GPXElement;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Detail", nil);
    
    NSString *name;
    NSString *description;
    
    if ([self.GPXElement isKindOfClass:[GPXWaypoint class]]) {
        GPXWaypoint *waypoint = (GPXWaypoint *)self.GPXElement;
        name = waypoint.name;
        description = waypoint.desc;
    }
    else if ([self.GPXElement isKindOfClass:[GPXRoute class]]) {
        GPXRoute *route = (GPXRoute *)self.GPXElement;
        name = route.name;
        description = route.desc;
    }
    else if ([self.GPXElement isKindOfClass:[GPXTrack class]]) {
        GPXTrack *track = (GPXTrack *)self.GPXElement;
        name = track.name;
        description = track.desc;
    }
    
    // replace line breaks to <br>
    if (description) {
        description = [description stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    }
    
    NSString *htmlString = [NSString stringWithFormat:
                            @"<!DOCTYPE HTML>"
                            "<html>"
                            "<head>"
                            "<meta charset=\"UTF-8\">"
                            "<meta name=\"viewport\" content=\"initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no\">"
                            "<style type=\"text/css\">"
                            "body { margin: 0; background: white; color: black; font-family: arial,sans-serif; font-size: 13px;}"
                            "div { margin: 0; padding: 0; }"
                            "div[align=left] { text-align: -webkit-left; }"
                            "div#content { padding: 8px; }"
                            "div#name { font-weight: bold; padding-bottom: .7em; }"
                            "div#description { padding-bottom: .7em; }"
                            "</style>"
                            "</head>"
                            "<body>"
                            "<div id=\"content\">"
                            "<div>"
                            "<div align=\"left\" id=\"name\">%@</div>"
                            "<div align=\"left\" id=\"description\">%@</div>"
                            "</div>"
                            "</div>"
                            "</body>"
                            "</html>"
                            , name
                            , description];
    
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked
        || navigationType == UIWebViewNavigationTypeFormSubmitted) {
        
        [[UIApplication sharedApplication] openURL:request.URL];
        
        return NO;
    }
    
    return YES;
}

@end
