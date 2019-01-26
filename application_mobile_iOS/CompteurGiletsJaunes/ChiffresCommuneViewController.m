//
//  ChiffresCommuneViewController.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Deuxième Tab avec les chiffres par communes d'un département donné
//

#import "ChiffresCommuneViewController.h"
#import "Brain.h"
#import "ChiffresCell.h"
#import "Commune.h"
#import "MBProgressHUD.h"

@interface ChiffresCommuneViewController ()

@end

@implementation ChiffresCommuneViewController {
    Brain * brain;
}

@synthesize departement;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewDidLoad
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewDidLoad {
    [super viewDidLoad];
    
    brain = [Brain sharedInstance];

    //NSLog(@"Département: %@ - %@", departement.unique_id, departement.nom);
    
    [[self tableView] registerNib:[UINib nibWithNibName:@"ChiffresCell" bundle:nil] forCellReuseIdentifier:@"ChiffresCell"];
   
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
- (void) viewWillAppear:(BOOL)animated {
    
    brain = [Brain sharedInstance];
 
    if([brain hasConnectivity]) {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
        // Chargement des communes
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        
            brain = [Brain sharedInstance];
            [brain chargeCommunesDuDepartement: departement.unique_id];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [hud hideAnimated:YES];
            });
        });
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
// didReceiveMemoryWarning
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// numberOfSectionsInTableView
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// numberOfRowsInSection
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [brain.ListeDesCommunes count];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// cellForRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChiffresCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChiffresCell"];
    if(!cell) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChiffresCell"];
    }
    
    return cell;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// willDisplayCell
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) tableView:(UITableView *)tableView willDisplayCell:(ChiffresCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Commune * commune = nil;
    commune = [brain.ListeDesCommunes objectAtIndex:indexPath.row];
    NSLog(@"Commune: %@", commune);
    cell.nomLabel.text = commune.nom;
    cell.chiffreLabel.text = commune.nombre_total;
    cell.nomLabel.numberOfLines = 2;
    cell.backgroundColor = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// heightForRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

@end
