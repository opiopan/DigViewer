//
//  MainViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"
#import "FolderOutlineView.h"
#import "ImageViewController.h"
#import "ThumbnailViewController.h"

@implementation MainViewController {
    NSArray*                   viewControllers;
    BaseViewController*        outlineViewController;
    BaseViewController* __weak representationViewController;
}

@synthesize presentationViewType;
@synthesize outlinePlaceholder;
@synthesize presentationPlaceholder;

- (id)init
{
    self = [super initWithNibName:@"MainView" bundle:nil];
    if (self) {
        [self performSelector:@selector(setupSubView) withObject:nil afterDelay:0.0f];
    }
    return self;
}

- (void)setupSubView
{
    outlineViewController = [[FolderOutlineView alloc] init];
    outlineViewController.representedObject = self.representedObject;
    [outlinePlaceholder associateSubViewWithController:outlineViewController];

    viewControllers = [NSArray arrayWithObjects:[[ImageViewController alloc] init],
                       [[ThumbnailViewController alloc] init], nil];
    for (int i = 0; i < viewControllers.count; i++){
        BaseViewController* controller = viewControllers[i];
        controller.representedObject = self.representedObject;
    }
    self.presentationViewType = typeImageView;
}

- (enum RepresentationViewType) presentationViewType
{
    return presentationViewType;
}

- (void) setPresentationViewType:(enum RepresentationViewType)type
{
    if (representationViewController){
        [representationViewController.view removeFromSuperview];
    }
    presentationViewType = type;
    representationViewController = viewControllers[type];
    [presentationPlaceholder associateSubViewWithController:representationViewController];
}

- (void)updateRepresentationObject
{
    [outlineViewController updateRepresentationObject];
    [representationViewController updateRepresentationObject];
}

@end
