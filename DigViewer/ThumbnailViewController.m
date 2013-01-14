//
//  ThumbnailViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ThumbnailViewController.h"

@implementation ThumbnailViewController

@synthesize thumbnailView;

- (id)init
{
    self = [super initWithNibName:@"ThumbnailView" bundle:nil];
    return self;
}

- (void)updateRepresentationObject
{
    [thumbnailView scrollIndexToVisible:[[thumbnailView selectionIndexes] firstIndex]];
}

@end
