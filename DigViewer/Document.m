//
//  Document.m
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import "Document.h"
#import "LoadingSheetController.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"

@implementation Document{
    LoadingSheetController* loader;
    MainViewController* mainViewController;
}

@synthesize root;
@synthesize selectionIndexPathsForTree;
@synthesize selectionIndexesForImages;
@synthesize isFitWindow;
@synthesize imageTreeController;
@synthesize imageArrayController;

static NSDictionary* rawSuffixes = nil;

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
    if (!rawSuffixes){
        rawSuffixes = @{
              @"cr2":@"raw",
              @"dng":@"raw",
              @"nef":@"raw",
              @"orf":@"raw",
              @"dcr":@"raw",
              @"raf":@"raw",
              @"mrw":@"raw",
              @"mos":@"raw",
              @"raw":@"raw",
              @"pef":@"raw",
              @"srf":@"raw",
              @"x3f":@"raw",
              @"erf":@"raw",
              @"sr2":@"raw",
              @"kdc":@"raw",
              @"mfw":@"raw",
              @"mef":@"raw",
              @"are":@"raw",
              @"rw2":@"raw",
              @"rwl":@"raw",
              @"psd":@"cpx",
              @"tif":@"cpx", @"tiff":@"cpx"};
    }
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"Document";
}

//-----------------------------------------------------------------------------------------
// ドキュメントロード & Window初期化
//-----------------------------------------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    mainViewController = [[MainViewController alloc] init];
    mainViewController.representedObject = self;
    [self.placeHolder associateSubViewWithController:mainViewController];
    
    // 環境設定で設定した除外リスト情報を元にロードをスケジュール
    NSUserDefaultsController* controller = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSNumber* ommitType = [controller valueForKey:@"imageSetType"];
    PathNodeOmmitingCondition* param = nil;
    if (ommitType.intValue){
        param = [[PathNodeOmmitingCondition alloc] init];
        param.suffixes = rawSuffixes;
    }
    [self performSelector:@selector(loadDocument:) withObject:param  afterDelay:0.0f];
}

- (void)loadDocument:(PathNodeOmmitingCondition*)cond
{
    loader = [[LoadingSheetController alloc] init];
    [loader loadPath:[self.fileURL path] forWindow:self.windowForSheet modalDelegate:self
            didEndSelector:@selector(didEndLoadingDocument:) condition:cond];
}

- (void)didEndLoadingDocument:(PathNode*)node
{
    if (node){
        self.root = node;
    }else{
        [self.windowForSheet close];
    }
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

- (void)moveUpFolder:(id)sender
{
    if (self.presentationViewType == typeImageView){
        self.presentationViewType = typeThumbnailView;
    }else{
        PathNode* selected = imageArrayController.selectedObjects[0];
        PathNode* current = selected.parent;
        PathNode* up = current.parent;
        if (up){
            NSUInteger index = current.indexInParent;
            [imageTreeController setSelectionIndexPath:up.indexPath];
            [imageArrayController setSelectionIndex:index];
        }
    }
}

- (void)moveDownFolder:(id)sender
{
    PathNode* selected = imageArrayController.selectedObjects[0];
    if (selected){
        if (selected.isImage){
            self.presentationViewType = typeImageView;
        }else{
            [imageTreeController setSelectionIndexPath:selected.indexPath];
        }
    }
}

//-----------------------------------------------------------------------------------------
// 選択状態属性
//-----------------------------------------------------------------------------------------
- (NSArray*) selectionIndexPathsForTree
{
    return selectionIndexPathsForTree;
}

- (void)setSelectionIndexPathsForTree:(NSArray *)indexPath
{
    selectionIndexPathsForTree = indexPath;
    [imageArrayController setSelectionIndex:0];
}

- (NSIndexSet*) selectionIndexesForImages
{
    return selectionIndexesForImages;
}

- (void)setSelectionIndexesForImages:(NSIndexSet *)indexes
{
    selectionIndexesForImages = indexes;
    [mainViewController performSelector:@selector(updateRepresentationObject) withObject:nil afterDelay:0.0f];
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

- (void)fitImageToScreen:(id)sender
{
    self.isFitWindow = ! self.isFitWindow;
    [sender setState:self.isFitWindow ? NSOnState : NSOffState];
}

@end
