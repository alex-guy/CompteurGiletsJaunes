//
//  CarteViewController.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 22/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Troisieme Tab avec carte Open Street Map
//

#import "CarteViewController.h"
#import "Brain.h"
#import "CustomAnnotationView.h"

@interface CarteViewController () <MKMapViewDelegate> {
    Brain * brain;

}

@end

@implementation CarteViewController
{
    CLLocation *originalLocation;
}

@synthesize mapView;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewDidLoad
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewDidLoad {
    [super viewDidLoad];
    
    brain = [Brain sharedInstance];
    
    if([brain hasConnectivity]) {

        originalLocation = nil;
        
        // MapView
        self.mapView.delegate = self;
        NSString *template = @"https://tile.openstreetmap.org/{z}/{x}/{y}.png";
        MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
        overlay.canReplaceMapContent = YES;
        [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
        
        //    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
        //    self.mapView.showsUserLocation = YES;
        
        [brain dessineAnnotationsRegionsSurLaCarte:self.mapView];

    }
    else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Internet non disponible !"
                                                                       message:@"Cette application a besoin d'Internet pour fonctionner"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [alert setModalPresentationStyle:UIModalPresentationPopover];
        UIPopoverPresentationController *popPresenter = [alert
                                                         popoverPresentationController];
        popPresenter.sourceView = self.view;
        
        popPresenter.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0, 0);
        popPresenter.permittedArrowDirections = NO;
        [self presentViewController:alert animated:YES completion:nil];
    }
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// prefersStatusBarHidden
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(BOOL)prefersStatusBarHidden{
    return YES;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Callback overlay
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return nil;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Calcule le niveau de zoom
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSUInteger)zoomLevel {
    return log2(360 * ((self.mapView.frame.size.width/256) / self.mapView.region.span.longitudeDelta)) + 1;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Appelée lorsque le zone de zoom a changé
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"ZoomLevel: %lu", (unsigned long) [self zoomLevel]);

    if([self zoomLevel] > 9) {
        [brain dessineAnnotationsCommunesSurLaCarte:self.mapView];
    }
    else if([self zoomLevel] > 7) {
        [brain dessineAnnotationsDepartementsSurLaCarte:self.mapView];
    }
    else {
        [brain dessineAnnotationsRegionsSurLaCarte:self.mapView];
    }
}


- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *SFAnnotationIdentifier = @"SFAnnotationIdentifier";
    MKPinAnnotationView *pinView =
    (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:SFAnnotationIdentifier];
    if (!pinView)
    {
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                        reuseIdentifier:SFAnnotationIdentifier];
        UIImage *flagImage = [UIImage imageNamed:@"icone_32x32b.png"];
        annotationView.image = flagImage;
        annotationView.canShowCallout = true;
        return annotationView;
    }
    else
    {
        pinView.annotation = annotation;
    }
    return pinView;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewWillDisappear
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// didReceiveMemoryWarning
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
