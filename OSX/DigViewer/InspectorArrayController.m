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
    NSString* fmtPTA = @"%@ \t%@";
    NSString* fmtPTV = @"%@";
    for (NSUInteger i = indexes.firstIndex; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]){
        id current = self.arrangedObjects[i];
        NSString* key = [current valueForKey:@"key"];
        NSString* value = [current valueForKey:@"value"];
        key = key ? key : @"";
        value = value ? value : @"";
        if (writeOnlyValue){
            [plainText appendFormat:fmtPTV, value];
        }else{
            [plainText appendFormat:fmtPTA, key, value];
        }
        fmtPTA = @"\n%@ \t%@";
        fmtPTV = @"\n%@";
    }

    [pboard declareTypes:@[NSPasteboardTypeTabularText, NSPasteboardTypeString] owner:self];
    [pboard setString:plainText forType:NSPasteboardTypeTabularText];
    [pboard setString:plainText forType:NSPasteboardTypeString];
    
    return indexes.count > 0;
}

@end
