//
//  InspectorArrayController.m
//  DigViewer
//
//  Created by opiopan on 2015/08/13.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "InspectorArrayController.h"

@implementation InspectorArrayController

//-----------------------------------------------------------------------------------------
// NSTableViewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard
{
    return [self writeItemsAtIndexes:indexes toPasteboard:pboard withOnlyValue:NO];
}

//-----------------------------------------------------------------------------------------
// Pasteboardへの書き込み
//-----------------------------------------------------------------------------------------
- (BOOL)writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard withOnlyValue:(BOOL)writeOnlyValue
{
    NSMutableString* plainText = [NSMutableString string];
    for (NSUInteger i = indexes.firstIndex; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]){
        id current = self.arrangedObjects[i];
        NSString* key = [current valueForKey:@"key"];
        NSString* value = [current valueForKey:@"value"];
        key = key ? key : @"";
        value = value ? value : @"";
        if (writeOnlyValue){
            [plainText appendFormat:@"%@\n", value];
        }else{
            [plainText appendFormat:@"%@ \t%@\n", key, value];
        }
    }

    [pboard declareTypes:@[NSPasteboardTypeString, NSPasteboardTypeTabularText] owner:self];
    [pboard setString:plainText forType:NSPasteboardTypeString];
    [pboard setString:plainText forType:NSPasteboardTypeTabularText];
    
    return indexes.count > 0;
}

@end
