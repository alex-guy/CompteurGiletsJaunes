//
//  CarteViewController.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 22/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Troisieme Tab avec carte Open Street Map
//

#import <UIKit/UIKit.h>
@import MapKit;

@interface CarteViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
