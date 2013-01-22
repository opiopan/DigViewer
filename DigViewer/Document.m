//
//  Document.m
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import "Document.h"
#import "LoadingSheetController.h"
#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"

@implementation Document{
    LoadingSheetController* loader;
    MainViewController* mainViewController;
}

@synthesize root;
@synthesize selectionIndexePathForTree;
@synthesize selectionIndexesForImages;
@synthesize isFitWindow;
@synthesize imageTreeController;
@synthesize imageArrayController;

//-----------------------------------------------------------------------------------------
// NSDocument クラスメソッド：ドキュメントの振る舞い
//-----------------------------------------------------------------------------------------
+ (BOOL)autosavesDrafts
{
    return NO;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

+ (BOOL)preservesVersions
{
    return NO;
}

+ (BOOL)usesUbiquitousStorage
{
    return NO;
}

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    mainViewController = [[MainViewController alloc] init];
    mainViewController.representedObject = self;
    [self.placeHolder associateSubViewWithController:mainViewController];
    
    [self performSelector:@selector(loadDocument) withObject:nil afterDelay:0.0f];
}

//-----------------------------------------------------------------------------------------
// ドキュメントロード
//-----------------------------------------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    return YES;
}

- (void)loadDocument
{
    loader = [[LoadingSheetController alloc] init];
    [loader loadPath:[self.fileURL path] forWindow:self.windowForSheet modalDelegate:self
            didEndSelector:@selector(didEndLoadingDocument:)];
}

- (void)didEndLoadingDocument:(PathNode*)node
{
    self.root = node;
    loader = nil;
}

//-----------------------------------------------------------------------------------------
// イメージツリー・ウォーキング
//-----------------------------------------------------------------------------------------
- (void)moveToNextImage:(id)sender
{
    [self moveToImageNode:[[self.imageArrayController selectedObjects][0] nextImageNode]];
}

- (void)moveToPreviousImage:(id)sender
{
    [self moveToImageNode:[[self.imageArrayController selectedObjects][0] previousImageNode]];
}

- (void)moveToImageNode:(PathNode*)next
{
    if (next){
        PathNode* current = [imageArrayController selectedObjects][0];
        if (current.parent != next.parent){
            NSIndexPath* indexPath = [next.parent indexPath];
            [imageTreeController setSelectionIndexPath:indexPath];
        }
        [imageArrayController setSelectionIndex:next.indexInParent];
    }
}

- (void)moveToNextFolder:(id)sender
{
    [self moveToFolderNode:[[imageTreeController selectedObjects][0] nextFolderNode]];
}

- (void)moveToPreviousFolder:(id)sender
{
    [self moveToFolderNode:[[imageTreeController selectedObjects][0] previousFolderNode]];
}

- (void)moveToFolderNode:(PathNode*)next
{
    if (next){
        NSIndexPath* indexPath = [next indexPath];
        [imageTreeController setSelectionIndexPath:indexPath];
    }
}

//-----------------------------------------------------------------------------------------
// 選択状態属性
//-----------------------------------------------------------------------------------------
- (NSArray*) selectionIndexePathForTree
{
    return selectionIndexePathForTree;
}

- (void)setSelectionIndexePathForTree:(NSArray *)indexPath
{
    selectionIndexePathForTree = indexPath;
    [imageArrayController setSelectionIndex:0];
}

- (NSIndexSet*) selectionIndexesForImages
{
    return selectionIndexesForImages;
}

- (void)setSelectionIndexesForImages:(NSIndexSet *)indexes
{
    selectionIndexesForImages = indexes;
    [mainViewController updateRepresentationObject];
}

//-----------------------------------------------------------------------------------------
// 表示形式属性
//-----------------------------------------------------------------------------------------
- (int) presentationViewType
{
    return mainViewController.presentationViewType;
}

- (void) setPresentationViewType:(int)type
{
    mainViewController.presentationViewType = type;
}

- (void) togglePresentationView:(id)sender
{
    self.presentationViewType = self.presentationViewType == typeImageView ? typeThumbnailView : typeImageView;
}

//-----------------------------------------------------------------------------------------
// イメージの拡大表示属性
//-----------------------------------------------------------------------------------------
- (BOOL) isFitWindow
{
    return isFitWindow;
}

- (void)setIsFitWindow:(BOOL)state
{
    isFitWindow = state;
    [mainViewController updateRepresentationObject];
}


@end
