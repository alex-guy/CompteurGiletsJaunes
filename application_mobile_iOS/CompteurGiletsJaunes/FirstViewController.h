//
//  FirstViewController.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 22/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Premier tab avec bouton inscription et compteur total
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FirstViewController : UIViewController <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *compteurLabel;
@property (weak, nonatomic) IBOutlet UITextView *inscriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateInscriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *communeLabel;
@property (weak, nonatomic) IBOutlet UIButton *giletJauneButton;
@property (nonatomic, retain) CLLocationManager *locationManager;

- (IBAction)clickGiletJaune:(id)sender;

@end

