//
//  ClickableImageView.h
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ClickableImageView : NSImageView

@property (weak) id delegate;
@property (copy) NSColor* backgroundColor;

- (void)setCGImage:(CGImageRef)cgimage withRotation:(NSInteger)rotation;

@end
