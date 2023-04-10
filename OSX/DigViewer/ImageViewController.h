//
//  ImageViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RelationalImageAccessor.h"

@interface ImageViewController : NSViewController

@property (weak) NSArrayController* IBOutlet imageArrayController;
@property (nonatomic) CGFloat zoomRatio;

- (void)moveToDirection:(RelationalImageDirection)direction withTransition:(id)transition;
- (void)beginSlideshow;
- (void)endSlideshow;
- (void)onDoubleClickableImageView:(id)sender;

@end
