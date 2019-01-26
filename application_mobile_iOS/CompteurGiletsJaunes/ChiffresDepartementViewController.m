//
//  ChiffresDepartementViewController.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Deuxième Tab avec les chiffres par départements d'une région donnée
//

#import "ChiffresDepartementViewController.h"
#import "Brain.h"
#import "ChiffresCell.h"
#import "Departement.h"
#import "ChiffresCommuneViewController.h"
#import "MBProgressHUD.h"

@interface ChiffresDepartementViewController ()
@end

@implementation ChiffresDepartementViewController {
    Brain * brain;
}

@synthesize region;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewDidLoad
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewDidLoad {
    [super viewDidLoad];
    
    brain = [Brain sharedInstance];

    //NSLog(@"Région: %@ - %@", region.unique_id, region.nom);
    
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
    
    // On remet à zéro la liste des communes (pour le rafraichissement)
    brain.ListeDesCommunes = nil;
    
    if([brain hasConnectivity]) {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
        // Chargement des départements
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        
            brain = [Brain sharedInstance];
            [brain chargeDepartementDeLaRegion: region.unique_id];

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
    return [brain.ListeDesDepartements count];
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
    Departement * departement = nil;
    departement = [brain.ListeDesDepartements objectAtIndex:indexPath.row];
    NSLog(@"Département: %@", departement);
    cell.nomLabel.text = departement.nom;
    cell.chiffreLabel.text = departement.nombre_total;
    cell.nomLabel.numberOfLines = 2;
    cell.backgroundColor = [UIColor clearColor];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// heightForRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


#pragma mark - click

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// didSelectRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath: %d", (int) indexPath.row);
    [self performSegueWithIdentifier:@"GoCommune" sender:self];
}


#pragma mark - Navigation

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// prepareForSegue
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Segue: %@", segue.identifier);
    if([segue.identifier  isEqual: @"GoCommune"]) {
        ChiffresCommuneViewController *communevc = segue.destinationViewController;
        Departement * departement = nil;
        departement = brain.ListeDesDepartements[self.tableView.indexPathForSelectedRow.row];
        communevc.departement = departement;
    }
}

@end
