//
//  MainViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

enum RepresentationViewType {
    typeImageView,
    typeThumbnailView
};

@interface MainViewController : NSViewController <NSSplitViewDelegate>

@property (assign) enum RepresentationViewType presentationViewType;
@property (readonly, nonatomic) NSViewController* presentationViewController;
@property (readonly, nonatomic) NSViewController* imageViewController;
@property (assign) BOOL isCollapsedOutlineView;
@property (assign) BOOL isCollapsedInspectorView;

@end
