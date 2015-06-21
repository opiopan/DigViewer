//
//  ClickableImageView.h
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageViewConfigController.h"
#import "RelationalImageAccessor.h"

@interface ClickableImageView : NSImageView

@property (weak) id delegate;

@property (nonatomic) id relationalImage;
@property (nonatomic) RelationalImageAccessor* relationalImageAccessor;
@property (nonatomic) SEL notifySwipeSelector;

@property (copy, nonatomic) NSColor* backgroundColor;
@property (nonatomic) BOOL isDrawingByLayer;
@property (nonatomic) ImageViewFilterType magnificationFilter;
@property (nonatomic) ImageViewFilterType minificationFilter;
@property (nonatomic) CGFloat zoomRatio;

- (void)moveToDirection:(RelationalImageDirection)direction withTransition:(id)transition;

@end
