//
//  FolderOutlineView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "FolderOutlineViewController.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "Document.h"
#import "DocumentWindowController.h"
#import "PathNode.h"
#import "DraggingSourceTreeController.h"
#import "DraggingSourceArrayController.h"

@implementation FolderOutlineViewController {
    NSMenu* contextMenuForTableView;
    NSMenu* contextMenuForOutlineView;
}

@synthesize imageTableView;
@synthesize imageArrayController;
@synthesize folderOutlineView;

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super initWithNibName:@"FolderOutlineView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    [imageTableView setTarget:self];
    [imageTableView setDoubleAction:@selector(onDoubleClickImageTableView:)];
    [imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndEnable"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndMultiple"
                                                                 options:0 context:nil];
    
    [self reflectDnDSettings];

    // Dragging sourceの登録
    [imageTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [folderOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    
    // コンテキストメニューを生成
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    contextMenuForTableView = [[NSMenu alloc] initWithTitle:@"Context Menu for Table View"];
    contextMenuForOutlineView = [[NSMenu alloc] initWithTitle:@"Context Menu for Outline View"];
    for (NSMenuItem* item in controller.contextMenu.itemArray){
        [contextMenuForTableView addItem:[item copy]];
        [contextMenuForOutlineView addItem:[item copy]];
    }
    imageTableView.menu = contextMenuForTableView;
    folderOutlineView.menu = contextMenuForOutlineView;
}

//-----------------------------------------------------------------------------------------
// クローズ準備
//-----------------------------------------------------------------------------------------
- (void)prepareForClose
{
    [imageArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.dndEnable"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.dndMultiple"];
}

//-----------------------------------------------------------------------------------------
// テーブルビュー上でのダブルクリック
//-----------------------------------------------------------------------------------------
- (void)onDoubleClickImageTableView:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    PathNode* current = controller.imageArrayController.selectedObjects[0];
    if (current.isImage){
        controller.presentationViewType = typeImageView;
    }else{
        [controller moveToFolderNode:current];
    }    
}

//-----------------------------------------------------------------------------------------
// キー値監視
//-----------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == imageArrayController && [keyPath isEqualToString:@"selectionIndexes"]){
        [imageTableView scrollRowToVisible:[imageTableView selectedRow]];
    }else if ([keyPath isEqualToString:@"values.dndMultiple"] || [keyPath isEqualToString:@"values.dndEnable"]){
        [self reflectDnDSettings];
    }
}

//-----------------------------------------------------------------------------------------
// ドラッグ＆ドロップ設定の反映
//-----------------------------------------------------------------------------------------
- (void)reflectDnDSettings
{
    NSNumber* enable = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"dndEnable"];
    NSNumber* multiple = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"dndMultiple"];
    imageTableView.allowsMultipleSelection = enable.boolValue && multiple.boolValue;
    [DraggingSourceArrayController setEnableDragging:enable.boolValue];
    [DraggingSourceTreeController setEnableDragging:enable.boolValue];
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー処理: コピー
//-----------------------------------------------------------------------------------------
- (void)copy:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller copyItems:[[sender parentItem] representedObject]];
    [[sender parentItem] setRepresentedObject:nil];
}

- (BOOL)validateForCopy:(NSMenuItem*)menuItem
{
    NSArray* items = [self targetItemsOfContextMenuForMenuItem:menuItem];
    if (items){
        menuItem.representedObject = items;
        return YES;
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー処理: アプリケーションで開く
//-----------------------------------------------------------------------------------------
- (void)performOpenWithApplicationSubMenu:(id)sender
{
}

- (BOOL)validateForPerformOpenWithApplicationSubMenu:(NSMenuItem*)menuItem
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    NSArray* items = [self targetItemsOfContextMenuForMenuItem:menuItem];
    if (items && items.count == 1){
        return [controller addOpenWithApplicationMenuForURL:items[0] toMenuItem:menuItem];
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー処理: 共有
//-----------------------------------------------------------------------------------------
- (void)performSharingSubMenu:(id)sender
{
}

- (BOOL)validateForPerformSharingSubMenu:(NSMenuItem*)menuItem
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    NSArray* items = [self targetItemsOfContextMenuForMenuItem:menuItem];
    if (items && items > 0){
        return [controller addSharingMenuForItems:items toMenuItem:menuItem];
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー対象アイテムの特定
//-----------------------------------------------------------------------------------------
- (NSArray*)targetItemsOfContextMenuForMenuItem:(NSMenuItem*)menuItem
{
    NSInteger indexInTable = imageTableView.clickedRow;
    NSInteger indexInOutline = folderOutlineView.clickedRow;
    NSArray* rc = nil;
    if (menuItem.menu == contextMenuForOutlineView && indexInOutline >= 0){
        PathNode* target = [[folderOutlineView itemAtRow:indexInOutline] representedObject];
        rc = @[[NSURL fileURLWithPath:target.originalPath]];
    }else if (menuItem.menu == contextMenuForTableView && indexInTable >= 0){
        PathNode* target = imageArrayController.arrangedObjects[indexInTable];
        NSArray* selected = imageArrayController.selectedObjects;
        if ([selected indexOfObject:target] != NSNotFound){
            NSMutableArray* array = [NSMutableArray array];
            for (PathNode* current in selected){
                [array addObject:[NSURL fileURLWithPath:current.originalPath]];
            }
            rc = array;
        }else{
            rc = @[[NSURL fileURLWithPath:target.originalPath]];
        }
    }
    return rc;
}

@end
