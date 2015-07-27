//
//  InputCameraNameController.h
//  DigViewer
//
//  Created by opiopan on 2015/07/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InputCameraNameController : NSObject <NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSPanel* panel;
@property (nonatomic, strong) IBOutlet NSString* cameraName;
@property (nonatomic) BOOL isEnableOKButton;

- (void) inputCameraNameforWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
