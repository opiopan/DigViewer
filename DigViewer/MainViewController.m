//
//  MainViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"
#import "NSViewController+Nested.h"
#import "FolderOutlineViewController.h"
#import "ImageViewController.h"
#import "ThumbnailViewController.h"
#import "NSWindow+TracingResponderChain.h"

@implementation MainViewController {
    NSArray*          viewControllers;
    NSViewController* outlineViewController;
    NSViewController* representationViewController;
}

@synthesize presentationViewType;
@synthesize outlinePlaceholder;
@synthesize presentationPlaceholder;

- (id)init
{
    self = [super initWithNibName:@"MainView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    outlineViewController = [[FolderOutlineViewController alloc] init];
    outlineViewController.representedObject = self.representedObject;
    [outlinePlaceholder associateSubViewWithController:outlineViewController];

    viewControllers = [NSArray arrayWithObjects:[[ImageViewController alloc] init],
                       [[ThumbnailViewController alloc] init], nil];
    for (int i = 0; i < viewControllers.count; i++){
        NSViewController* controller = viewControllers[i];
        controller.representedObject = self.representedObject;
    }
    self.presentationViewType = typeImageView;
    [self performSelector:@selector(configureOnInit) withObject:nil afterDelay:0.0];
}

- (void)configureOnInit
{
    [self.view.window makeFirstResponder:representationViewController.representationView];
}

- (enum RepresentationViewType) presentationViewType
{
    return presentationViewType;
}

- (void) setPresentationViewType:(enum RepresentationViewType)type
{
    BOOL needToResetFirstResponder = NO;
    if (representationViewController){
        needToResetFirstResponder = [self.view.window isBelongToResponderChain:representationViewController.view];
        [representationViewController.view removeFromSuperview];
    }
    presentationViewType = type;
    representationViewController = viewControllers[type];
    [presentationPlaceholder associateSubViewWithController:representationViewController];
    [self.view.window recalculateKeyViewLoop];
    if (needToResetFirstResponder){
        [self.view.window makeFirstResponder:representationViewController.representationView];
    }
}

@end
