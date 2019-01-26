//
//  CustomAnnotationView.m
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 12/01/2019.
//  Copyright © 2019 Alexandre GUY. All rights reserved.
//

#import "CustomAnnotationView.h"


@interface CustomAnnotationView()
{
    UIImageView *_imageView;
}

@end

@implementation CustomAnnotationView

/*
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"CustomAnnotationView initWithFrame");
        // make sure the x and y of the CGRect are half it's
        // width and height, so the callout shows when user clicks
        // in the middle of the image
        CGRect  viewRect = CGRectMake(-16, -16, 32, 32);
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:viewRect];
        
        // keeps the image dimensions correct
        // so if you have a rectangle image, it will show up as a rectangle,
        // instead of being resized into a square
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _imageView = imageView;
        
        [self addSubview:imageView];
    }
    return self;
}
*/
- (id)initWithAnnotation:(id <MKAnnotation>)annotation
         reuseIdentifier:(NSString *)reuseIdentifier
                   image:(UIImage *)image {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBackgroundColor:[UIColor redColor]];
        //CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
        CGRect frame = CGRectMake(0, 0,32, 32);
        [self setFrame:frame];
        [self setCenterOffset:CGPointMake(0, -CGRectGetHeight(frame) / 2)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        _imageView = imageView;
        [self addSubview:imageView];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image
{
    // when an image is set for the annotation view,
    // it actually adds the image to the image view
    NSLog(@"CustomAnnotationView setImage");
    _imageView.image = image;
}

@end
