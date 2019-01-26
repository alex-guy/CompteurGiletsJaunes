//
//  ChiffresCell.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  La cellule du tableau personnalisée utilisée par les tableaux du deuxième Tab
//

#import <UIKit/UIKit.h>

@interface ChiffresCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nomLabel;
@property (weak, nonatomic) IBOutlet UILabel *chiffreLabel;

@end
