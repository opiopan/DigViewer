//
//  DraggingSourceTreeController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/14.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DraggingSourceTreeController.h"
#import "PathNode.h"

@implementation DraggingSourceTreeController

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
    NSMutableArray* plist = [NSMutableArray arrayWithCapacity:items.count];
    for (int i = 0; i < items.count; i++){
        PathNode* node = [items[0] representedObject];
        [plist addObject:node.originalPath];
    }
    [pboard declareTypes:@[NSFilenamesPboardType] owner:self];
    [pboard setPropertyList:plist forType:NSFilenamesPboardType];
    
    return YES;
}

@end
