//
//  Brain.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Singleton contenant le code métier de l'application et différentes fonctions utilitaires
//

#import <Foundation/Foundation.h>

@import MapKit;

@interface Brain : NSObject

@property (retain, nonatomic) NSArray * ListeDesRegions;
@property (retain, nonatomic) NSArray * ListeDesDepartements;
@property (retain, nonatomic) NSArray * ListeDesCommunes;

// Méthodes de classe
+(id) sharedInstance;

// Méthodes
- (NSString *) chargeCompteurTotal;
- (void) chargeRegion;
- (void) chargeDepartementDeLaRegion: (NSString *) unique_id;
- (void) chargeCommunesDuDepartement: (NSString *) unique_id;
- (void) dessineAnnotationsRegionsSurLaCarte:(MKMapView *) mapView;
- (void) dessineAnnotationsDepartementsSurLaCarte:(MKMapView *) mapView;
- (void) dessineAnnotationsCommunesSurLaCarte:(MKMapView *) mapView;
- (BOOL) hasConnectivity;
- (NSDictionary *) localiseAvecCoordonnees: (CLLocationCoordinate2D) centre;
- (void) sauveChaine:(NSString*)chaine deLaCle:(NSString*)cle;
- (NSString *) recupereChaineDeLaCle:(NSString*)cle;
- (void) supprimeChaineDeLaCle:(NSString*)cle;
- (BOOL) inscriptionUUID: uuid avecLongitude:(NSString *) longitude etLatitude: (NSString *) latitude;
- (NSArray *) recupereInformationsUUID:(NSString *) uuid;
- (NSString *)convertiDate:(NSString *)dateStr;

@end

