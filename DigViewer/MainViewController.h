//
//  MainViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InspectorViewController.h"

enum RepresentationViewType {
    typeImageView,
    typeThumbnailView
};

@interface MainViewController : NSViewController <NSSplitViewDelegate>

@property (assign) enum RepresentationViewType presentationViewType;
@property (readonly, nonatomic) NSViewController* presentationViewController;
@property (readonly, nonatomic) NSViewController* imageViewController;
@property (readonly, nonatomic) InspectorViewController* inspectorViewController;
@property (assign) BOOL isCollapsedOutlineView;
@property (assign) BOOL isCollapsedInspectorView;

- (void)detachSubviews;
- (BOOL)cleanSubView:(NSInteger)index;

@end
