//
//  CustomAnnotationView.h
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 12/01/2019.
//  Copyright © 2019 Alexandre GUY. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CustomAnnotationView : MKAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation
         reuseIdentifier:(NSString *)reuseIdentifier
                   image:(UIImage *)image;

@end
