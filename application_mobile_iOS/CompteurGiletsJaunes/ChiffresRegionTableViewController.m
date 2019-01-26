//
//  ChiffresRegionTableViewController.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Deuxième Tab avec les chiffres par régions
//

#import "ChiffresRegionTableViewController.h"
#import "Brain.h"
#import "ChiffresCell.h"
#import "Region.h"
#import "ChiffresDepartementViewController.h"
#import "MBProgressHUD.h"

@interface ChiffresRegionTableViewController () {

    Brain * brain;
}

@end

@implementation ChiffresRegionTableViewController


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// viewDidLoad
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)viewDidLoad {
    [super viewDidLoad];
    
    brain = [Brain sharedInstance];
    
    [[self tableView] registerNib:[UINib nibWithNibName:@"ChiffresCell" bundle:nil] forCellReuseIdentifier:@"ChiffresCell"];
    
    UIColor *jaune = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:0/255.0f alpha:1.0f];
    UIColor *gris = [UIColor colorWithRed:153/255.0f green:153/255.0f blue:153/255.0f alpha:1.0f];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:jaune}];
    
    //[self.navigationController.navigationBar setBackgroundColor:[UIColor blackColor]];
    //[self.navigationController.navigationBar setBackgroundColor:gris];
    self.navigationController.navigationBar.barTintColor = gris;
    
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
    
    // On remet à zéro la liste des départements (pour le rafraichissement)
    brain.ListeDesDepartements = nil;
    
    if([brain hasConnectivity]) {
    
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
        // Chargement des régions
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        
            brain = [Brain sharedInstance];
            [brain chargeRegion];
        
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
    return [brain.ListeDesRegions count];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// cellForRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChiffresCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChiffresCell"];
    if(!cell) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChiffresCell"];
    }
    Region * region = nil;
    region = [brain.ListeDesRegions objectAtIndex:indexPath.row];
    if([region.unique_id isEqualToString:@"-1"] || [region.unique_id isEqualToString:@"-2"]) {
        cell.nomLabel.textColor = [UIColor blackColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.nomLabel.textColor = [UIColor colorWithRed:0x33/255.0 green:0x66/255.0 blue:0xff/255.0 alpha:1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// willDisplayCell
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) tableView:(UITableView *)tableView willDisplayCell:(ChiffresCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Region * region = nil;
    region = [brain.ListeDesRegions objectAtIndex:indexPath.row];
    NSLog(@"Région: %@", region.nom);
    cell.nomLabel.text = region.nom;
    cell.chiffreLabel.text = region.nombre_total;
    cell.nomLabel.numberOfLines = 2;
    cell.backgroundColor = [UIColor clearColor];
    
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// heightForRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


#pragma mark - click

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// didSelectRowAtIndexPath
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"didSelectRowAtIndexPath: %d", (int) indexPath.row);
    [self performSegueWithIdentifier:@"GoDepartement" sender:self];
}


#pragma mark - Navigation

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// shouldPerformSegueWithIdentifier
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender
{
    //NSLog(@"--- shouldPerformSegueWithIdentifier ---");
    Region * region = nil;
    region = brain.ListeDesRegions[self.tableView.indexPathForSelectedRow.row];
    if([region.unique_id isEqualToString:@"-1"] || [region.unique_id isEqualToString:@"-2"]) {
        return NO;
    }
    return YES;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// performSegueWithIdentifier
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([self shouldPerformSegueWithIdentifier:identifier sender:sender] == NO) {
        return;
    }
    [super performSegueWithIdentifier:identifier sender:sender];
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// prepareForSegue
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //NSLog(@"Segue: %@", segue.identifier);
    if([segue.identifier  isEqual: @"GoDepartement"]) {
        Region * region = nil;
        region = brain.ListeDesRegions[self.tableView.indexPathForSelectedRow.row];
        ChiffresDepartementViewController *departementvc = segue.destinationViewController;
        departementvc.region = region;
    }
}

@end
