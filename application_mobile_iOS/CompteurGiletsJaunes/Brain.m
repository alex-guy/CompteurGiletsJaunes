//
//  Brain.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Singleton contenant le code métier de l'application et différentes fonctions utilitaires
//

#import "Brain.h"
#import "Region.h"
#import "Departement.h"
#import "Commune.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Security/Security.h"
#include <CommonCrypto/CommonDigest.h>
@import MapKit;

@interface Brain () {
}
@end

@implementation Brain


#pragma mark - Attributs publics partagés

@synthesize ListeDesRegions;
@synthesize ListeDesDepartements;
@synthesize ListeDesCommunes;

static Brain * sharedInstance = nil;

#pragma mark - Méthodes de classe

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Méthode de classe implémentant le patron Singleton
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+ (id) sharedInstance {
    static dispatch_once_t onceQueue;
    
    dispatch_once(&onceQueue, ^{
        sharedInstance = [[self alloc] init];
        NSLog(@"*** Initialisation de l'instance partagée ***");
    });
    return sharedInstance;
}


#pragma mark - méthodes de chargement de données

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Charge le compteur total de Gilets Jaunes
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSString *) chargeCompteurTotal {

    // JSON Mike
    NSError *error;
    NSString *url_string = [NSString stringWithFormat: @"https://gj.tetalab.org:42443/regions/total"];
    NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString:url_string]];
    NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSArray *results = [json valueForKey:@"args"];
    
    NSNumber *compteur = [results valueForKey:@"total"];

    NSLog(@"Total: %@", compteur);
    
    return [compteur stringValue];

}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Charge la liste des régions
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) chargeRegion {
    NSMutableArray *liste = [[NSMutableArray alloc] init];
    NSError *error;
    NSString *url_string = [NSString stringWithFormat: @"https://gj.tetalab.org:42443/regions/list"];
    NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString:url_string]];
    NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    NSArray *results = [json valueForKey:@"args"];
    for(NSString *res in results) {
        //NSLog(@"RES: %@", [results valueForKey:res]);
        Region *r = [[Region alloc] initWithUniqueId:res nom:[[results valueForKey:res] valueForKey:@"nom"] nombreTotal:[[[results valueForKey:res] valueForKey:@"cpt"] stringValue] longitude:[[results valueForKey:res] valueForKey:@"lon"] latitude:[[results valueForKey:res] valueForKey:@"lat"]];
        [liste addObject:r];
        //NSLog(@"Région %@ (%@ %@)", r.nom, r.longitude, r.latitude);
    }
    NSSortDescriptor * sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"nombre_total" ascending:NO
                                                                      selector:@selector(localizedStandardCompare:)];
    NSSortDescriptor * sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"nom" ascending:YES];
    self.ListeDesRegions = [liste sortedArrayUsingDescriptors:@[sortDescriptor1, sortDescriptor2]];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Charge la liste des départements d'une région donnée
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) chargeDepartementDeLaRegion: (NSString *) unique_id {
    NSMutableArray *liste = [[NSMutableArray alloc] init];
    NSError *error;
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://gj.tetalab.org:42443/departements/list"]];
    NSString *userUpdate =[NSString stringWithFormat:@"rgid=%@", unique_id, nil];
    [urlRequest setHTTPMethod:@"POST"];
    NSData *arg_post = [userUpdate dataUsingEncoding:NSUTF8StringEncoding];
    [urlRequest setHTTPBody:arg_post];
    NSError *error2 = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    NSData * data = [self sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error2];
  
    if(data != nil) {
        //NSLog (@"RESULTAT : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSArray *results = [json valueForKey:@"args"];
        for(NSString *res in results) {
            //NSLog(@"RES: %@", [results valueForKey:res]);
            Departement *d = [[Departement alloc] initWithUniqueId:res nom:[[results valueForKey:res] valueForKey:@"nom"] nombreTotal:[[[results valueForKey:res] valueForKey:@"cpt"] stringValue] longitude:[[results valueForKey:res] valueForKey:@"lon"] latitude:[[results valueForKey:res] valueForKey:@"lat"]];
            [liste addObject:d];
            //NSLog(@"Département %@ (%@ %@)", d.nom, d.longitude, d.latitude);
        }
        NSSortDescriptor * sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"nombre_total" ascending:NO
                                                                          selector:@selector(localizedStandardCompare:)];
        NSSortDescriptor * sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"nom" ascending:YES];
        self.ListeDesDepartements = [liste sortedArrayUsingDescriptors:@[sortDescriptor1, sortDescriptor2]];
    }
    else {
        self.ListeDesDepartements = nil;
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Charge la liste des communes d'un département donné
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) chargeCommunesDuDepartement:(NSString *)unique_id {
    NSMutableArray *liste = [[NSMutableArray alloc] init];
    NSError *error;

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://gj.tetalab.org:42443/communes/list"]];
    NSString *userUpdate =[NSString stringWithFormat:@"dgid=%@", unique_id, nil];
    [urlRequest setHTTPMethod:@"POST"];
    NSData *arg_post = [userUpdate dataUsingEncoding:NSUTF8StringEncoding];
    [urlRequest setHTTPBody:arg_post];
    NSError *error2 = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    NSData * data = [self sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error2];
    
    if(data != nil) {
        //NSLog (@"RESULTAT : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
        NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSArray *results = [json valueForKey:@"args"];
        for(NSString *res in results) {
            Commune *c = [[Commune alloc] initWithUniqueId:res nom:[[results valueForKey:res] valueForKey:@"nom"] nombreTotal:[[[results valueForKey:res] valueForKey:@"cpt"] stringValue] longitude:[[results valueForKey:res] valueForKey:@"lon"] latitude:[[results valueForKey:res] valueForKey:@"lat"]];
            [liste addObject:c];
            //NSLog(@"Commune %@ (%@ %@)", c.nom, c.longitude, c.latitude);
        }
        NSSortDescriptor * sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"nombre_total" ascending:NO
                                                                          selector:@selector(localizedStandardCompare:)];
        NSSortDescriptor * sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"nom" ascending:YES];
        self.ListeDesCommunes = [liste sortedArrayUsingDescriptors:@[sortDescriptor1, sortDescriptor2]];
    }
    else {
        self.ListeDesCommunes = nil;
    }

}


#pragma mark - Méthodes de dessin des annotations

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Dessine les annotations des régions sur la carte OSM
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) dessineAnnotationsRegionsSurLaCarte:(MKMapView *) mapView {
    [self chargeRegion];
    [mapView removeAnnotations:mapView.annotations];
    for(Region *region in self.ListeDesRegions) {
        if(![region.unique_id isEqualToString:@"-1"] && ![region.unique_id isEqualToString:@"-2"]) {
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            annotation.coordinate = CLLocationCoordinate2DMake([region.latitude floatValue], [region.longitude floatValue]);
            annotation.title = [NSString stringWithFormat:@"%@", region.nom];
            NSString * pluriel = @"";
            if([region.nombre_total intValue] > 1) pluriel = @"s";
            annotation.subtitle = [NSString stringWithFormat:@"%@ gilet%@ jaune%@", region.nombre_total, pluriel, pluriel];
            [mapView addAnnotation:annotation];
        }
    }
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Dessine les annotations des départements sur la carte OSM
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) dessineAnnotationsDepartementsSurLaCarte:(MKMapView *) mapView {

    CLLocationCoordinate2D centre = [mapView centerCoordinate];
    NSDictionary * results = [self localiseAvecCoordonnees:centre];
    
    if(results == nil) return;

    NSString * rgid = [results valueForKey:@"rgid"];
    
    NSLog(@"Centre: %f %f  Région: %@", centre.longitude, centre.latitude, rgid);
    
    [self chargeDepartementDeLaRegion:rgid];
    [mapView removeAnnotations:mapView.annotations];
    for(Departement *departement in self.ListeDesDepartements) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake([departement.latitude floatValue], [departement.longitude floatValue]);
        annotation.title = [NSString stringWithFormat:@"%@", departement.nom];
        NSString * pluriel = @"";
        if([departement.nombre_total intValue] > 1) pluriel = @"s";
        annotation.subtitle = [NSString stringWithFormat:@"%@ gilet%@ jaune%@", departement.nombre_total, pluriel, pluriel];
        [mapView addAnnotation:annotation];
    }
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Dessine les annotations des communes sur la carte OSM
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) dessineAnnotationsCommunesSurLaCarte:(MKMapView *) mapView {

    CLLocationCoordinate2D centre = [mapView centerCoordinate];
    NSDictionary * results = [self localiseAvecCoordonnees:centre];
    
    if(results == nil) return;

    NSString * dgid = [results valueForKey:@"dgid"];
    
    NSLog(@"Centre: %f %f  Département: %@", centre.longitude, centre.latitude, dgid);
    
    [self chargeCommunesDuDepartement:dgid];
    [mapView removeAnnotations:mapView.annotations];
    for(Commune *communes in self.ListeDesCommunes) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        NSLog(@"Commune %@ (%@ %@)", communes.nom, communes.longitude, communes.latitude);
        annotation.coordinate = CLLocationCoordinate2DMake([communes.latitude floatValue], [communes.longitude floatValue]);
        annotation.title = [NSString stringWithFormat:@"%@", communes.nom];
        NSString * pluriel = @"";
        if([communes.nombre_total intValue] > 1) pluriel = @"s";
        annotation.subtitle = [NSString stringWithFormat:@"%@ gilet%@ jaune%@", communes.nombre_total, pluriel, pluriel];
        [mapView addAnnotation:annotation];
    }
}


#pragma mark - Méthodes utilitaires

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Localise la commune, département et région d'un point GPS
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSDictionary *) localiseAvecCoordonnees: (CLLocationCoordinate2D) centre {
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://gj.tetalab.org:42443/tools/localize"]];
    NSString *userUpdate =[NSString stringWithFormat:@"position=%f,%f", centre.longitude, centre.latitude, nil];
    [urlRequest setHTTPMethod:@"POST"];
    NSData *arg_post = [userUpdate dataUsingEncoding:NSUTF8StringEncoding];
    [urlRequest setHTTPBody:arg_post];
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    NSData * data = [self sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error];
    
    if(data != nil) {
        NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        //NSLog(@"JSON: %@", json);
        if([[json valueForKey:@"result"] isEqualToString:@"error"]) return nil;
        NSDictionary *results = [json valueForKey:@"args"];
        return results;
    }
    return nil;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Envoi une requète POST synchrone
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr {
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (errorPtr != NULL) {
                                             *errorPtr = error;
                                         }
                                         if (responsePtr != NULL) {
                                             *responsePtr = response;
                                         }  
                                         if (error == nil) {  
                                             result = data;  
                                         }  
                                         dispatch_semaphore_signal(sem);  
                                     }] resume];  
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);  
    
    return result;  
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Teste la connectivé à Internet
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (BOOL)hasConnectivity {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if (reachability != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                // If target host is not reachable
                return NO;
            }
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                // If target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                return YES;
            }
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs.
                
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                    // ... and no [user] intervention is needed
                    return YES;
                }
            }
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                return YES;
            }
        }
    }
    return NO;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Converti la date d'entrée en format français
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(NSString *)convertiDate:(NSString *)dateStr {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd' 'kk:mm:ss.SSSSSSZ"];
    NSDate *date = [dateFormatter dateFromString:dateStr];
    [dateFormatter setDateFormat:@"dd/MM/yyyy' à 'kk:mm:ss"];
    return [dateFormatter stringFromDate:date];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Calcule le SHA512 d'une chaine
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-(NSString*) sha512:(NSString*)input {
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(data.bytes, data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}


#pragma mark - Inscription d'un utilisateur

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Incrit un UUID sur le compteur des Gilets Jaunes
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (BOOL) inscriptionUUID: uuid avecLongitude:(NSString *) longitude etLatitude: (NSString *) latitude {
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://gj.tetalab.org:42443/protesters/add"]];
    NSString *userUpdate = [NSString stringWithFormat:@"uid=%@&position=%@,%@", uuid, longitude, latitude, nil];
    NSString *auth_token = [self calculeAuthTokendeURL:[NSString stringWithFormat:@"https://gj.tetalab.org:42443/protesters/add?%@", userUpdate]];
    userUpdate = [NSString stringWithFormat:@"%@&auth_token=%@", userUpdate, auth_token, nil];
    NSLog(@"Parametres envoyés: %@", userUpdate);
    [urlRequest setHTTPMethod:@"POST"];
    NSData *arg_post = [userUpdate dataUsingEncoding:NSUTF8StringEncoding];
    [urlRequest setHTTPBody:arg_post];
    NSError *error2 = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    NSData * data = [self sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error2];

    if(data != nil) {
        NSLog (@"RESULTAT : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error2];
        NSString *resultat = [json valueForKey:@"result"];
        if([resultat isEqualToString:@"success"]) {
            [self sauveChaine:uuid deLaCle:@"org.gilets-jaunes.compteur"];
            return TRUE;
        }
    }
    return FALSE;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Calcule le token d'authentification passé lors de l'inscription
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSString *) calculeAuthTokendeURL: (NSString *) url {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"secrets" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSString * cle_chiffrement = [dict objectForKey:@"cle_chiffrement"];
    return [self sha512:[NSString stringWithFormat:@"%@%@", cle_chiffrement, url, nil]];
}


#pragma mark - Récupération des informations d'un utilisateur

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Récupère les informations d'un UUID (date d'inscription et commune)
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSArray *) recupereInformationsUUID:(NSString *) uuid {
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://gj.tetalab.org:42443/protesters/get"]];
    NSString *userUpdate =[NSString stringWithFormat:@"uid=%@", uuid, nil];
    [urlRequest setHTTPMethod:@"POST"];
    NSData *arg_post = [userUpdate dataUsingEncoding:NSUTF8StringEncoding];
    [urlRequest setHTTPBody:arg_post];
    NSError *error2 = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    NSData * data = [self sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error2];
 
    NSString * date_inscription = @"";
    NSString * commune = @"";
    
    if(data != nil) {
        NSLog (@"RESULTAT : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error2];
        if([[json valueForKey:@"result"] isEqualToString:@"success"]) {
            NSDictionary *resultat = [json valueForKey:@"args"];
            date_inscription = [resultat valueForKey:@"last_seen"];
            NSLog(@"Date inscription: %@", date_inscription);
            date_inscription = [NSString stringWithFormat:@"Inscription: %@", [self convertiDate:date_inscription], nil];
            NSLog(@"date inscription après formatage: %@", date_inscription);
            
            if([[[resultat valueForKey:@"rgid"] stringValue] isEqualToString:@"-1"]) {
                commune = @"Position inconnue";
            }
            else if([[[resultat valueForKey:@"rgid"] stringValue] isEqualToString:@"-2"]) {
                commune = @"Hors France et DOM/TOM";
            }
            else if([resultat valueForKey:@"cgid"] != (id)[NSNull null]) {
                NSString * cgid = [[resultat valueForKey:@"cgid"] stringValue];
                NSLog(@"cgid: %@", cgid);
                NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://gj.tetalab.org:42443/communes/list"]];
                NSString *userUpdate =[NSString stringWithFormat:@"cgid=%@", cgid, nil];
                [urlRequest setHTTPMethod:@"POST"];
                NSData *arg_post = [userUpdate dataUsingEncoding:NSUTF8StringEncoding];
                [urlRequest setHTTPBody:arg_post];
                NSError *error2 = [[NSError alloc] init];
                NSHTTPURLResponse *responseCode = nil;
                NSData * data = [self sendSynchronousRequest:urlRequest returningResponse:&responseCode error:&error2];
                if(data != nil) {
                    NSLog (@"RESULTAT2 : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                    
                    NSMutableArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error2];
                    NSDictionary *resultat = [json valueForKey:@"args"];
                    commune = [[resultat objectForKey:cgid] valueForKey:@"nom"];
                    commune = [NSString stringWithFormat:@"Commune: %@", commune, nil];
                    NSLog(@"Commune: %@", commune);
                }
            }
            else {
                NSLog(@"+++ cgid NULL +++");
            }
        }
    }
    
    return [NSArray arrayWithObjects: date_inscription, commune, nil];
}


#pragma mark - Stockage de l'UID dans la KeyChain et récupération

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Stockage de l'UUID dans la KeyChain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) sauveChaine:(NSString*)chaine deLaCle:(NSString*)cle {
    
    // Create dictionary of search parameters
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassInternetPassword),  kSecClass, cle, kSecAttrServer, kCFBooleanTrue, kSecReturnAttributes, nil];
    
    // Remove any old values from the keychain
    OSStatus err = SecItemDelete((__bridge CFDictionaryRef) dict);
    
    // Create dictionary of parameters to add
    NSData* chaineData = [chaine dataUsingEncoding:NSUTF8StringEncoding];
    dict = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassInternetPassword), kSecClass, cle, kSecAttrServer, chaineData, kSecValueData, nil];
    
    // Try to save to keychain
    err = SecItemAdd((__bridge CFDictionaryRef) dict, NULL);
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Chargement de l'UUID stocké dans la KeyChain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSString *) recupereChaineDeLaCle:(NSString*)cle {
    
    // Create dictionary of search parameters
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassInternetPassword),  kSecClass, cle, kSecAttrServer, kCFBooleanTrue, kSecReturnAttributes, kCFBooleanTrue, kSecReturnData, nil];
    
    // Look up server in the keychain
    NSDictionary* found = nil;
    CFDictionaryRef foundCF;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef) dict, (CFTypeRef*)&foundCF);
    
    NSLog(@"%d",(int)err);
    // Not found
    if(err==-25300) return @"";
    
    found = (__bridge NSDictionary*)(foundCF);
    if (!found) return @"";
    
    // Found
    NSString* chaine = [[NSString alloc] initWithData:[found objectForKey:(__bridge id)(kSecValueData)] encoding:NSUTF8StringEncoding];
    
    NSLog(@"Chaine: %@",chaine);
    return chaine;
}


// Pour test
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Suppression de la chaine stockée dans la KeyChain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) supprimeChaineDeLaCle:(NSString*)cle {
    
    // Create dictionary of search parameters
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassInternetPassword),  kSecClass, cle, kSecAttrServer, kCFBooleanTrue, kSecReturnAttributes, kCFBooleanTrue, kSecReturnData, nil];
    
    // Remove any old values from the keychain
    OSStatus err = SecItemDelete((__bridge CFDictionaryRef) dict);
    NSLog(@"%d",(int)err);
}

@end
