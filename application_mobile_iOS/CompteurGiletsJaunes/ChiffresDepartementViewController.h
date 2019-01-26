//
//  ChiffresDepartementViewController.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Deuxième Tab avec les chiffres par départements d'une région donnée
//

#import <UIKit/UIKit.h>
#import "Region.h"

@interface ChiffresDepartementViewController : UITableViewController

// L'objet région
@property (strong, nonatomic) Region *region;

@end
