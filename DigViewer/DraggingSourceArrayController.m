//
//  DraggingSourceArrayController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DraggingSourceArrayController.h"
#import "PathNode.h"

@implementation DraggingSourceArrayController

//-----------------------------------------------------------------------------------------
// table viewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    PathNode* current = self.selectedObjects[0];
    if (current.isImage){
        NSArray* array = @[[NSURL fileURLWithPath:current.imagePath]];
        [pboard writeObjects:array];
        return YES;
    }else{
        return NO;
    }
}

@end
