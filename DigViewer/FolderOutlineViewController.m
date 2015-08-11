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

@implementation FolderOutlineViewController

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
    [imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndEnable"
                                                                 options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndMultiple"
                                                                 options:nil context:nil];

    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    imageTableView.menu = controller.contextMenu;
    folderOutlineView.menu = controller.contextMenu;
    
    [self reflectDnDSettings];

    // Dragging sourceの登録
    [imageTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [folderOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
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
    NSArray* items = [self targetItemsOfContextMenu];
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
    NSArray* items = [self targetItemsOfContextMenu];
    if (items && items.count == 1){
        menuItem.submenu = [controller openWithApplicationMenuForURL:items[0] withTarget:controller
                                                              action:@selector(performOpenWithApplication:)];
        if (menuItem.submenu != nil){
            menuItem.representedObject = items[0];
        }
        return menuItem.submenu != nil;
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
    NSArray* items = [self targetItemsOfContextMenu];
    if (items && items > 0){
        menuItem.submenu = [controller sharingMenuForItems:items withTarget:controller
                                                              action:@selector(performSharing:)];
        if (menuItem.submenu != nil){
            menuItem.representedObject = items;
        }
        return menuItem.submenu != nil;
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー対象アイテムの特定
//-----------------------------------------------------------------------------------------
- (NSArray*)targetItemsOfContextMenu
{
    NSInteger indexInTable = imageTableView.clickedRow;
    NSInteger indexInOutline = folderOutlineView.clickedRow;
    NSArray* rc = nil;
    if (indexInOutline >= 0){
        PathNode* target = [[folderOutlineView itemAtRow:indexInOutline] representedObject];
        rc = @[[NSURL fileURLWithPath:target.originalPath]];
    }else if (indexInTable >= 0){
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
