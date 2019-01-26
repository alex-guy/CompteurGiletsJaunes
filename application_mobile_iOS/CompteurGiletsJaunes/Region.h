//
//  Region.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Objet représentant une région
//

#import <Foundation/Foundation.h>

@interface Region : NSObject {
    NSString * _unique_id;
    NSString * _nom;
    NSString * _nombre_total;
    NSString * _longitude;
    NSString * _latitude;
}

@property (nonatomic, copy) NSString * unique_id;
@property (nonatomic, copy) NSString * nom;
@property (nonatomic, copy) NSString * nombre_total;
@property (nonatomic, copy) NSString * longitude;
@property (nonatomic, copy) NSString * latitude;

- (id) initWithUniqueId:(NSString *)unique_id nom:(NSString *)nom nombreTotal:(NSString *)nombre_total longitude:(NSString *) longitude latitude:(NSString *) latitude;

@end
