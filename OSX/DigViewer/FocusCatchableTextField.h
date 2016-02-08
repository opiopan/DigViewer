//
//  FocusCatchableTextField.h
//  DigViewer
//
//  Created by opiopan on 2015/06/22.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FocusCatchableTextField : NSTextField

@property (assign, nonatomic) SEL notifyFocusChangeSelector;

@end
