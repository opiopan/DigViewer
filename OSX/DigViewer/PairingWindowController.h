//
//  ParingWindowController.h
//  DigViewer
//
//  Created by opiopan on 2015/11/29.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PairingWindowCompletionHandler)(BOOL isOK);

@interface PairingWindowController : NSObject <NSWindowDelegate>

@property NSString* modelName;
@property NSString* modelType;
@property NSInteger keyHash;

- (void) startPairingWithCompletionHandler: (PairingWindowCompletionHandler) handler;

@end
