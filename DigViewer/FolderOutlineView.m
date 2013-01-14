//
//  FolderOutlineView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "FolderOutlineView.h"

@implementation FolderOutlineView

@synthesize imageTableView;

- (id)init
{
    self = [super initWithNibName:@"FolderOutlineView" bundle:nil];
    return self;
}

- (void)updateRepresentationObject
{
    [imageTableView scrollRowToVisible:[imageTableView selectedRow]];
}

@end
