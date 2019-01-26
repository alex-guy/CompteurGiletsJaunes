//
//  Commune.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Objet représentant une commune
//

#import "Commune.h"

@implementation Commune

@synthesize unique_id = _unique_id;
@synthesize nom = _nom;
@synthesize nombre_total = _nombre_total;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// initWithUniqueId
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (id) initWithUniqueId:(NSString *)unique_id nom:(NSString *)nom nombreTotal:(NSString *)nombre_total  longitude:(NSString *) longitude latitude:(NSString *) latitude {
    if((self = [super init])) {
        self.unique_id = unique_id;
        self.nom = nom;
        self.nombre_total = nombre_total;
        self.longitude = longitude;
        self.latitude = latitude;
    }
    return self;
}

@end
