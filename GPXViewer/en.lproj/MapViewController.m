//
//  MapViewController.m
//  GPXViewer
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <GPX/GPX.h>
#import "MapViewController.h"
#import "DetailViewController.h"
#import "MKPointAnnotation+GPX.h"
#import "MKPolyline+GPX.h"
#import "GPXWaypoint+MapKit.h"
#import "GPXRoute+MapKit.h"
#import "GPXTrack+MapKit.h"
#import "SVProgressHUD.h"


@interface MapViewController ()
@property (strong, nonatomic) MKUserTrackingBarButtonItem *trackingButton;
@property (strong, nonatomic) UIBarButtonItem *openButton;
- (NSString *)inboxDirectory;
- (void)loadGPXAtURL:(NSURL *)url;
- (void)didReceiveNewURL:(NSNotification *)notification;
- (void)userDefaultDidChangeNotification:(NSNotification *)notification;
- (void)pushDetailViewControllerWithGPXElement:(GPXElement *)GPXElement;
@end

@interface MapViewController (UIAlertViewDelegate) <UIAlertViewDelegate>
@end

@interface MapViewController (UISearchBarDelegate) <UISearchBarDelegate>
- (void)filterAnnotationsForSearchText:(NSString*)searchText;
@end

@interface MapViewController (MKMapViewDelegate) <MKMapViewDelegate>
- (void)loadMapType;
- (void)saveMapType;
- (void)reloadMapView;
@end

@interface MapViewController (UITableViewDataSource) <UITableViewDataSource>
@end

@interface MapViewController (UITableViewDelegate) <UITableViewDelegate>
- (void)tableViewWillAppear:(UITableView *)tableView;
@end



@implementation MapViewController {
    GPXRoot *__gpx;
    NSArray *__filterdAnnotations;
}

@synthesize placeSearchBar = __placeSearchBar;
@synthesize contentView = __contentView;
@synthesize mapView = __mapView;
@synthesize listView = __listView;
@synthesize searchResultView = __searchResultView;
@synthesize toolBar = __toolBar;
@synthesize mapTypeButton = __mapTypeButton;
@synthesize mapTypeControl = __mapTypeControl;
@synthesize flipButton = __flipButton;
@synthesize trackingButton = __trackingButton;
@synthesize openButton = __openButton;


#pragma mark - Instance

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GPXViewerDidReceiveNewURL" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewURL:) name:@"GPXViewerDidReceiveNewURL" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultDidChangeNotification:) name:NSUserDefaultsDidChangeNotification object:nil];

    __filterdAnnotations = [NSArray array];

    self.title = NSLocalizedString(@"Map", nil);
    [self.mapTypeControl setTitle:NSLocalizedString(@"Standard", nil) forSegmentAtIndex:0];
    [self.mapTypeControl setTitle:NSLocalizedString(@"Satellite", nil) forSegmentAtIndex:1];
    [self.mapTypeControl setTitle:NSLocalizedString(@"Hybrid", nil) forSegmentAtIndex:2];
    
    self.navigationItem.titleView = self.placeSearchBar;  
    self.navigationItem.titleView.frame = CGRectMake(0, 0, 320, 44);
    
    // setup the tracking button
    self.trackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolBar.items];
    [items insertObject:self.trackingButton atIndex:0];
    self.toolBar.items = items;

    // setup the open button
    self.openButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Open", nil)
                                                       style:UIBarButtonItemStyleBordered 
                                                      target:self
                                                      action:@selector(open:)];

    [self loadMapType];
    
    // load last file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *urlString = [defaults objectForKey:@"url"];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [self loadGPXAtURL:url];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self tableViewWillAppear:self.listView];
    
    if (!self.searchResultView.hidden) {
        [self.placeSearchBar becomeFirstResponder];
        [self tableViewWillAppear:self.searchResultView];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // reset tracking mode
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Public methods

- (IBAction)mapTypeChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    self.mapView.mapType = segmentedControl.selectedSegmentIndex;
    
    [self saveMapType];
}

- (IBAction)flip:(id)sender
{
    // reset tracking mode
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
    
    // flip the button
    [UIView transitionWithView:self.flipButton
                      duration:0.5f
                       options:[self.mapView superview] ?  UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        if ([self.mapView superview]) {
                            [self.flipButton setImage:[UIImage imageNamed:@"MapButton"] forState:UIControlStateNormal];
                        } else {
                            [self.flipButton setImage:[UIImage imageNamed:@"ListButton"] forState:UIControlStateNormal];
                        }
                    } 
                    completion:nil
     ];
    
    // flip the content view
    [UIView transitionWithView:self.contentView
                      duration:0.5f
                       options:[self.mapView superview] ?  UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        if ([self.mapView superview]) {
                            [self.mapView removeFromSuperview];
                            [self.contentView addSubview:self.listView];
                        } else {
                            [self.listView removeFromSuperview];
                            [self.contentView addSubview:self.mapView];
                        }
                    }
                    completion:^(BOOL finished) {
                        if (finished) {
                            // replace toolbar items
                            if (![self.mapView superview]) {
                                NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolBar.items];
                                [items removeObject:self.trackingButton];
                                [items removeObject:self.mapTypeButton];
                                [items insertObject:self.openButton atIndex:0];
                                self.toolBar.items = items;
                            } else {
                                NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolBar.items];
                                [items removeObject:self.openButton];
                                [items insertObject:self.trackingButton atIndex:0];
                                [items insertObject:self.mapTypeButton atIndex:2];
                                self.toolBar.items = items;
                            }
                        }
                    }
     ];
}

- (IBAction)open:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Open", nil)
                                                   message:NSLocalizedString(@"Enter the URL of GPX file.", nil) 
                                                  delegate:self 
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
                                         otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeURL;
    [alert show];
}


#pragma mark - Private method

- (NSString *)inboxDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"Inbox"];
}

- (void)loadGPXAtURL:(NSURL *)url
{
    [SVProgressHUD show];
    self.navigationController.view.userInteractionEnabled = NO;
    
    // remove all annotations and overlays
    NSMutableArray *annotations = [NSMutableArray array];
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        
        [annotations addObject:annotation];
    }
    [self.mapView removeAnnotations:annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    // load new GPX
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // observe GPX format error
        [[NSNotificationCenter defaultCenter] addObserverForName:kGPXInvalidGPXFormatNotification 
                                                          object:nil 
                                                           queue:nil 
                                                      usingBlock:^(NSNotification *note){
                                                          NSString *description = [[note userInfo] valueForKey:kGPXDescriptionKey];
                                                          NSLog(@"%@", description);
                                                      }
         ];
        
        __gpx = [GPXParser parseGPXAtURL:url];
        
        // remove GPX format error observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kGPXInvalidGPXFormatNotification object:nil];
        
        if (__gpx) {
            // save curent url for next load
            NSString *urlString = [url absoluteString];

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:urlString forKey:@"url"];
            [defaults synchronize];

            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                self.navigationController.view.userInteractionEnabled = YES;
                
                [self reloadMapView];
                [self.listView reloadData];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                self.navigationController.view.userInteractionEnabled = YES;

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:NSLocalizedString(@"Failed to read the GPX file", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
            });
        }
    });
}

- (void)didReceiveNewURL:(NSNotification *)notification
{
    NSURL *url = (NSURL *)[notification object];
    
    [self loadGPXAtURL:url];
}

- (void)userDefaultDidChangeNotification:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL clearHistory = [defaults boolForKey:@"clear_history"];
    
    if (clearHistory) {
        // delete cache files
        NSString *inboxDirectory = [self inboxDirectory];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxDirectory error:nil];
        for (NSString *path in files) {
            NSString *fullPath = [inboxDirectory stringByAppendingPathComponent:path];
            NSLog(@"delete, %@", fullPath);
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        }
        
        // remove all annotations and overlays
        NSMutableArray *annotations = [NSMutableArray array];
        for (id<MKAnnotation> annotation in self.mapView.annotations) {
            if ([annotation isKindOfClass:[MKUserLocation class]]) {
                continue;
            }
            
            [annotations addObject:annotation];
        }
        [self.mapView removeAnnotations:annotations];
        [self.mapView removeOverlays:self.mapView.overlays];
        
        __gpx = nil;
        __filterdAnnotations = [NSArray array];
        
        [self.listView reloadData];
        [self.searchResultView reloadData];
        
        // reset settings
        [defaults setBool:NO forKey:@"clear_history"];
        [defaults setObject:nil forKey:@"url"];
        [defaults synchronize];
    }
}

- (void)pushDetailViewControllerWithGPXElement:(GPXElement *)GPXElement
{
    DetailViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
    if (viewController) {
        viewController.GPXElement = GPXElement;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end


#pragma mark - 
@implementation MapViewController (UIAlertViewDelegate)

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSString *urlString = [alertView textFieldAtIndex:0].text;
        
        if (!urlString || urlString.length == 0) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                message:NSLocalizedString(@"Please enter the URL", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            return;
        }
        
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                message:NSLocalizedString(@"Failed to Open the URL", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            return;
        }
        
        [self loadGPXAtURL:url];
    }
}

@end


#pragma mark - 
@implementation MapViewController (UISearchBarDelegate)

- (void)filterAnnotationsForSearchText:(NSString*)searchText
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", searchText];
    __filterdAnnotations = [self.mapView.annotations filteredArrayUsingPredicate:predicate];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
    
    // show table view
    if (self.searchResultView.hidden) {
        self.searchResultView.hidden = NO;
        [UIView animateWithDuration:0.5f
                         animations:^{
                             self.searchResultView.alpha = 1.f;
                         }
         ];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    [searchBar resignFirstResponder];
    
    [searchBar setShowsCancelButton:NO animated:YES];
    
    __filterdAnnotations = [NSArray array];
    
    [self.searchResultView reloadData];
    
    // hide table view
    if (!self.searchResultView.hidden) {
        self.searchResultView.hidden = NO;
        [UIView animateWithDuration:0.5f
                         animations:^{
                             self.searchResultView.alpha = 0.f;
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 self.searchResultView.hidden = YES;
                             }
                         }
         ];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self filterAnnotationsForSearchText:searchText];
    [self.searchResultView reloadData];
}

@end


#pragma mark - 
@implementation MapViewController (MKMapViewDelegate)

- (void)loadMapType
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *mapType = [defaults objectForKey:@"map-type"];
    if (!mapType) {
        mapType = [NSNumber numberWithInteger:0];
    }
    
    self.mapView.mapType = [mapType integerValue];
    self.mapTypeControl.selectedSegmentIndex = [mapType integerValue];
}

- (void)saveMapType
{
    NSNumber *mapType = [NSNumber numberWithInteger:self.mapView.mapType];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:mapType forKey:@"map-type"];
    [defaults synchronize];
}

- (void)reloadMapView
{
    NSMutableArray *annotations = [NSMutableArray array];
    NSMutableArray *overlays = [NSMutableArray array];
    
    // add waypoints
    for (GPXWaypoint *waypoint in __gpx.waypoints) {
        MKShape *annotation = waypoint.annotation;
        if (annotation) {
            [annotations addObject:annotation];
        }
    }
    
    // add routes
    for (GPXRoute *route in __gpx.routes) {
        MKShape *annotation = route.annotation;
        if (annotation) {
            [annotations addObject:annotation];
        }

        MKPolyline *line = route.overlay;
        if (line) {
            [overlays addObject:line];
        }
    }
    
    // add tracks
    for (GPXTrack *track in __gpx.tracks) {
        MKShape *annotation = track.annotation;
        if (annotation) {
            [annotations addObject:annotation];
        }
        
        [overlays addObjectsFromArray:track.overlays];
    }
    
    [self.mapView addAnnotations:annotations];
    [self.mapView addOverlays:overlays];

    // set zoom in next run loop.
    dispatch_async(dispatch_get_main_queue(), ^{

        //
        // Thanks for elegant code!
        // https://gist.github.com/915374
        //
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in self.mapView.annotations)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
            if (MKMapRectIsNull(zoomRect)) {
                zoomRect = pointRect;
            } else {
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
            }
        }
        [self.mapView setVisibleMapRect:zoomRect animated:YES];
    });
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    GPXElement *GPXElement = ((MKPointAnnotation *)annotation).GPXElement;
    if (GPXElement) {
        MKAnnotationView *annotationView;

        // waypoint
        if ([GPXElement isKindOfClass:[GPXWaypoint class]]) {
            
            NSString *PinAnnotationViewIdentifer = @"PinAnnotationView";
            
            annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:PinAnnotationViewIdentifer];
            if (!annotationView) {
                annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PinAnnotationViewIdentifer];
            } else {
                annotationView.annotation = annotation;
            }
        }
        // track or route
        else if ([GPXElement isKindOfClass:[GPXRoot class]]
                 || [GPXElement isKindOfClass:[GPXTrack class]]) {

            NSString *AnnotationViewIdentifer = @"SquareAnnotationView";
            annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewIdentifer];
            if (!annotationView) {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewIdentifer];
            } else {
                annotationView.annotation = annotation;
            }
            
            annotationView.image = [UIImage imageNamed:@"Square"];
        } else {
            return nil;
        }

        annotationView.canShowCallout = YES;
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        return annotationView;

    }
    
    return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    GPXElement *GPXElement = ((MKPolyline *)overlay).GPXElement;
    if (GPXElement) {
        MKPolylineView *overlayView = [[MKPolylineView alloc] initWithOverlay:overlay];

        // route
        if ([GPXElement isKindOfClass:[GPXRoute class]]) {
            overlayView.strokeColor = [UIColor redColor];
            overlayView.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:8], [NSNumber numberWithInt:8], nil];
        }
        // track
        else if ([GPXElement isKindOfClass:[GPXTrack class]]) {
            overlayView.strokeColor = [UIColor blueColor];
        }
        else {
            return nil;
        }

        overlayView.lineWidth = 5.f;

        return overlayView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPointAnnotation *pointAnnotation = (MKPointAnnotation *)view.annotation;
        [self pushDetailViewControllerWithGPXElement:pointAnnotation.GPXElement];
    }
}

@end


#pragma mark - 
@implementation MapViewController (UITableViewDataSource)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchResultView) {
        return __filterdAnnotations.count;
    }
    
    return self.mapView.annotations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MKPointAnnotation *annotation;
    if (tableView == self.searchResultView) {
        annotation = [__filterdAnnotations objectAtIndex:indexPath.row];
    } else {
        annotation = [self.mapView.annotations objectAtIndex:indexPath.row];
    }
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.textLabel.text = annotation.title;
    cell.detailTextLabel.text = annotation.subtitle;
    
    return cell;
}

@end


#pragma mark - 
@implementation MapViewController (UITableViewDelegate)

- (void)tableViewWillAppear:(UITableView *)tableView
{
    NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
    if (indexPath) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    [tableView flashScrollIndicators];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.listView) {
        if (__gpx) {
            GPXMetadata *metadata = __gpx.metadata;
            if (metadata) {
                return metadata.name;
            }
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == self.searchResultView) {
        [self.placeSearchBar resignFirstResponder];
    }
    
    MKPointAnnotation *annotation;
    if (tableView == self.searchResultView) {
        annotation = [__filterdAnnotations objectAtIndex:indexPath.row];
    } else {
        annotation = [self.mapView.annotations objectAtIndex:indexPath.row];
    }
    
    // cancel searching
    if (tableView == self.searchResultView) {
        [self searchBarCancelButtonClicked:self.placeSearchBar];
    }
    
    // flip to mapview
    if (self.listView.superview) {
        [self flip:nil];
    }
    
    // move to the selected annotation
    [self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    MKPointAnnotation *annotation;
    if (tableView == self.searchResultView) {
        annotation = [__filterdAnnotations objectAtIndex:indexPath.row];
    } else {
        annotation = [self.mapView.annotations objectAtIndex:indexPath.row];
    }
    
    [self pushDetailViewControllerWithGPXElement:annotation.GPXElement];
}

@end
