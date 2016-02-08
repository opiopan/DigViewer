//
//  EditImageSetSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/05/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditImageSetSheetController.h"
#import "NSImage+CapabilityDetermining.h"

//-----------------------------------------------------------------------------------------
// ExtentionEntity
//   拡張子一つを表現するオブジェクト
//-----------------------------------------------------------------------------------------
@interface ExtentionEntity : NSObject <NSCopying>
@property (readonly, nonatomic) ExtentionEntity* me;
@property (strong, readonly, nonatomic) NSString* name;
@property (readonly, nonatomic) NSImage* icon;
@property (readonly, nonatomic) NSString* remarks;
- (id) initWithName:(NSString*)name;
@end

@implementation ExtentionEntity

- (id)initWithName:(NSString *)name
{
    self = [self init];
    if (self){
        _name = [name copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSComparisonResult)compare:(ExtentionEntity*) dest
{
    return [_name compare:dest->_name];
}

- (ExtentionEntity *)me
{
    return self;
}

- (NSImage *)icon
{
    return [[NSWorkspace sharedWorkspace] iconForFileType:_name.lowercaseString];
}

- (NSString *)remarks
{
    return [[NSImage supportedSuffixes] valueForKey:_name.lowercaseString];
}

@end

//-----------------------------------------------------------------------------------------
// EditImageSetSheetControllerクラスの実装
//-----------------------------------------------------------------------------------------
@implementation EditImageSetSheetController{
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"EditImageSetSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
        _okButtonIsEnable = NO;
    }
    
    return self;
}

- (void) awakeFromNib
{
    NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"me" ascending:YES]];
    _displayableListController.sortDescriptors = sortDescriptors;
    _omittingListController.sortDescriptors = sortDescriptors;
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"remarks" ascending:YES comparator:^(id o1, id o2){
        return [(NSString*)o1 compare:o2 options:NSCaseInsensitiveSearch];
    }];
    ((NSTableColumn*)_displayableListView.tableColumns[1]).sortDescriptorPrototype = sortDescriptor;
    ((NSTableColumn*)_omittingListView.tableColumns[1]).sortDescriptorPrototype = sortDescriptor;
}

//-----------------------------------------------------------------------------------------
// 編集シート開始
//-----------------------------------------------------------------------------------------
- (void)editOmittingExtentions:(NSArray *)extentions forWindow:(NSWindow *)window
                 modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
    // リスト生成
    NSMutableArray* displayableList = [NSMutableArray array];
    NSMutableArray* omittingList = [NSMutableArray array];
    NSDictionary* all = [NSImage supportedSuffixes];
    for (NSString* extention in [all keyEnumerator]){
        BOOL isOmitting = NO;
        for (NSString* omitting in extentions){
            if ([extention isEqualToString:omitting]){
                isOmitting = YES;
                break;
            }
        }
        ExtentionEntity* entity = [[ExtentionEntity alloc] initWithName:extention.uppercaseString];
        if (isOmitting){
            [omittingList addObject:entity];
        }else{
            [displayableList addObject:entity];
        }
    }
    self.displayableList = displayableList;
    self.omittingList = omittingList;
    
    [[NSApplication sharedApplication] beginSheet:self.panel
                                   modalForWindow:_window
                                    modalDelegate:self
                                   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                      contextInfo:nil];
}

//-----------------------------------------------------------------------------------------
// シート終了
//-----------------------------------------------------------------------------------------
- (void) didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == NSOKButton){
        NSMutableArray* array = [NSMutableArray arrayWithCapacity:_omittingList.count];
        for (ExtentionEntity* extention in _omittingList){
            [array addObject:extention.name.lowercaseString];
        }
        [_delegate performSelector:_didEndSelector withObject:array afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// 追加・削除ボタン応答
//-----------------------------------------------------------------------------------------
- (void)onAdd:(id)sender
{
    if (_displayableListController.selectedObjects.count > 0){
        [self willChangeValueForKey:@"displayableList"];
        [self willChangeValueForKey:@"omittingList"];
        NSArray* selectedObjects = [NSArray arrayWithArray:_displayableListController.selectedObjects];
        [_displayableList removeObjectsInArray:selectedObjects];
        [_omittingList addObjectsFromArray:selectedObjects];
        [self didChangeValueForKey:@"displayableList"];
        [self didChangeValueForKey:@"omittingList"];
        _omittingListController.selectedObjects = selectedObjects;
        self.okButtonIsEnable = YES;
    }
}

- (void)onRemove:(id)sender
{
    if (_omittingListController.selectedObjects.count > 0){
        [self willChangeValueForKey:@"displayableList"];
        [self willChangeValueForKey:@"omittingList"];
        NSArray* selectedObjects = [NSArray arrayWithArray:_omittingListController.selectedObjects];
        [_omittingList removeObjectsInArray:selectedObjects];
        [_displayableList addObjectsFromArray:selectedObjects];
        [self didChangeValueForKey:@"displayableList"];
        [self didChangeValueForKey:@"omittingList"];
        _displayableListController.selectedObjects = selectedObjects;
        self.okButtonIsEnable = YES;
    }
}

//-----------------------------------------------------------------------------------------
// OKボタン・キャンセルボタン応答
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSOKButton];
}

- (IBAction)onCancel:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSCancelButton];
}

@end
