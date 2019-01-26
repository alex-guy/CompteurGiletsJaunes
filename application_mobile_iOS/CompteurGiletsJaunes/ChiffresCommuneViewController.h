//
//  ChiffresCommuneViewController.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Deuxième Tab avec les chiffres par communes d'un département donné
//

#import <UIKit/UIKit.h>
#import "Departement.h"

@interface ChiffresCommuneViewController : UITableViewController

// L'objet département
@property (strong, nonatomic) Departement *departement;

@end
