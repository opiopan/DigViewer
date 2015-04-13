//
//  DraggingSourceArrayController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "DraggingSourceArrayController.h"
#import "PathNode.h"

@implementation DraggingSourceArrayController

//-----------------------------------------------------------------------------------------
// NSTableViewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    PathNode* current = self.selectedObjects[0];
    if (current.isImage){
        NSArray* array = @[current.imagePath];
        [pboard declareTypes:@[NSFilenamesPboardType] owner:self];
        [pboard setPropertyList:array forType:NSFilenamesPboardType];
        return YES;
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// IKImageBrowserViewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (NSUInteger)imageBrowser:(IKImageBrowserView *)aBrowser
       writeItemsAtIndexes:(NSIndexSet *)itemIndexes
              toPasteboard:(NSPasteboard *)pasteboard
{
    PathNode* current = self.selectedObjects[0];
    if (current.isImage){
        NSArray* array = @[current.imagePath];
        [pasteboard declareTypes:@[NSFilenamesPboardType] owner:self];
        [pasteboard setPropertyList:array forType:NSFilenamesPboardType];
        return 1;
    }else{
        return 0;
    }
}

@end
