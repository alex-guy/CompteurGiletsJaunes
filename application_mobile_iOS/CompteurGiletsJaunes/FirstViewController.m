//
//  FirstViewController.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 22/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Premier tab avec bouton inscription et compteur total
//

#import "FirstViewController.h"
#import "KeyInterface.h"
#import "Brain.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>

@interface FirstViewController () {
    Brain * brain;
    NSString *nb_total;
    bool inscription_realisee;
}

@end

@implementation FirstViewController

@synthesize compteurLabel;
@synthesize inscriptionLabel;
@synthesize dateInscriptionLabel;
@synthesize communeLabel;
@synthesize giletJauneButton;
@synthesize locationManager;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewDidLoad
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewDidLoad {
    [super viewDidLoad];

    brain = [Brain sharedInstance];
    
    nb_total = @"non disponible";
    
    inscription_realisee = FALSE;
    
    // Pas encore utilisé
    //[KeyInterface generateTouchIDKeyPair];
    //NSLog(@"Public key raw bits:\n%@", [KeyInterface publicKeyBits]);

    // Pour test
    //[brain supprimeChaineDeLaCle:@"org.gilets-jaunes.compteur"];

}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// prefersStatusBarHidden
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(BOOL)prefersStatusBarHidden{
    return YES;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewWillAppear
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewWillAppear:(BOOL)animated {

    if([brain hasConnectivity]) {
        
        // Récupération des infos de la Keychain
        NSString * uuid = [brain recupereChaineDeLaCle:@"org.gilets-jaunes.compteur"];
        
        // L'utilisateur est déjà inscrit
        if(![uuid isEqualToString:@""]) {
            [self afficheDejaInscrit: uuid];
        }
    
        // Mise à jour du compteur
        [self metAJourCompteurTotal];
        
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
// Met à jour le compteur total de Gilets Jaunes
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) metAJourCompteurTotal {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        
        nb_total = [brain chargeCompteurTotal];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [compteurLabel setText:nb_total];
            [hud hideAnimated:YES];
        });
    });
    
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Affiche les labels de déjà inscrit et désactive le bouton d'inscription
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) afficheDejaInscrit: (NSString *) uuid {
    [inscriptionLabel setHidden:TRUE];
    [dateInscriptionLabel setHidden:FALSE];
    [communeLabel setHidden:FALSE];
    //giletJauneButton.enabled = NO;
    [giletJauneButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    NSArray * resultat = [brain recupereInformationsUUID:uuid];
    NSString * date_inscription = resultat[0];
    NSString * commune = resultat[1];
    [dateInscriptionLabel setText:date_inscription];
    [communeLabel setText:commune];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Action appelée lorsque l'utilisateur clique sur le bouton Gilet Jaune
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (IBAction)clickGiletJaune:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                   message:@"Clicker sur OK pour confirmer l'inscription"
                                                            preferredStyle:UIAlertControllerStyleActionSheet]; // 1
    UIAlertAction *premiereAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              NSLog(@"OK !!!");
                                                              [self confirmeClickGiletJaune];
                                                          }]; // 2
    UIAlertAction *secondeAction = [UIAlertAction actionWithTitle:@"Annuler"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                               NSLog(@"Annulation");
                                                               return;
                                                           }];
    [alert addAction:premiereAction];
    [alert addAction:secondeAction];
    [alert setModalPresentationStyle:UIModalPresentationPopover];
    UIPopoverPresentationController *popPresenter = [alert
                                                     popoverPresentationController];
    popPresenter.sourceView = self.view;
    
    popPresenter.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0, 0);
    popPresenter.permittedArrowDirections = NO;
    
    [self presentViewController:alert animated:YES completion:nil];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Inscription en Gilet Jaune si on confirme le click sur le bouton Gilet Jaune
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) confirmeClickGiletJaune {

    // GPS
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.delegate = self;
    
    if([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    
/*
    CLLocation *curPos = self.locationManager.location;
    NSString *latitude = [[NSNumber numberWithDouble:curPos.coordinate.latitude] stringValue];
    NSString *longitude = [[NSNumber numberWithDouble:curPos.coordinate.longitude] stringValue];
    NSLog(@"Lat: %@", latitude);
    NSLog(@"Long: %@", longitude);
    
    NSString *message = @"Une erreur est intervenue durant l'inscription :(";
    if([brain inscriptionUUID:[uuid UUIDString] avecLongitude:longitude etLatitude:latitude]) {
        message = @"Inscription bien enregistrée !";
        [self afficheDejaInscrit:[uuid UUIDString]];
    }

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];

    // Mise à jour du compteur
    [self metAJourCompteurTotal];
*/
}


#pragma mark - CLLocationManagerDelegate

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Appelé lors d'une erreur pour récupérer la position GPS ou interdiction de l'utilisateur
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Impossible de déterminer votre position GPS !"
                                                                   message:@"Vous pouvez continuer l'inscription mais vous ne serez pas associé à une commune, ou vous pouvez annuler et renouveler votre inscription ultérieurement"
                                                            preferredStyle:UIAlertControllerStyleActionSheet]; // 1
    UIAlertAction *premiereAction = [UIAlertAction actionWithTitle:@"Continuer"
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                 NSLog(@"OK !!!");
                                                                 [self inscriptionUtilisateurAvecLongitude:@"0.0" etLatitude:@"0.0"];
                                                             }]; // 2
    UIAlertAction *secondeAction = [UIAlertAction actionWithTitle:@"Annuler"
                                                            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                NSLog(@"Annulation");
                                                                return;
                                                            }];
    [alert addAction:premiereAction];
    [alert addAction:secondeAction];
    [alert setModalPresentationStyle:UIModalPresentationPopover];
    UIPopoverPresentationController *popPresenter = [alert
                                                     popoverPresentationController];
    popPresenter.sourceView = self.view;
    
    popPresenter.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0, 0);
    popPresenter.permittedArrowDirections = NO;
    
    [self presentViewController:alert animated:YES completion:nil];

}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Appelé lorsque la position GPS est mise à jour
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations
{
    CLLocation * derniere_position = [locations objectAtIndex:locations.count - 1];
    NSLog(@"didUpdateLocations: %@", derniere_position);

    NSString *latitude = [[NSNumber numberWithDouble:derniere_position.coordinate.latitude] stringValue];
    NSString *longitude = [[NSNumber numberWithDouble:derniere_position.coordinate.longitude] stringValue];
    NSLog(@"Lat: %@   Long: %@", latitude, longitude);
    [self inscriptionUtilisateurAvecLongitude:longitude etLatitude:latitude];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Demande d'autorisation d'utiliser la position GPS
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didChangeAuthorizationStatus 1");
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            // do some error handling
        }
            break;
        default:{
            [self.locationManager startUpdatingLocation];
        }
            break;
    }
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Lance l'inscription de l'utilisateur
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) inscriptionUtilisateurAvecLongitude:(NSString *) longitude etLatitude:(NSString *) latitude {
    if(!inscription_realisee) {
        inscription_realisee = TRUE;
        NSUUID * uuid = [[NSUUID alloc] init];
        NSLog(@"Génération et enregistrement de l'UUID: %@", uuid);
        NSString *message = @"Une erreur est intervenue durant l'inscription :(";
        if([brain inscriptionUUID:[uuid UUIDString] avecLongitude:longitude etLatitude:latitude]) {
            message = @"Inscription bien enregistrée !";
            [self afficheDejaInscrit:[uuid UUIDString]];
            [self.locationManager stopUpdatingLocation];
        }
        else {
            inscription_realisee = FALSE;
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:message
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
        
        // Mise à jour du compteur
        [self metAJourCompteurTotal];
    }
    else {
        NSLog(@"inscription en cours ou déjà réalisée");
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// didReceiveMemoryWarning
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.locationManager stopUpdatingLocation];
}

@end
