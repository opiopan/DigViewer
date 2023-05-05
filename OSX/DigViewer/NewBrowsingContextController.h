//
//  NewBrowsingContextController.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/05.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewBrowsingContextController : NSObject<NSWindowDelegate>
@property (nonatomic, strong) IBOutlet NSPanel* panel;
@property (nonatomic, strong) IBOutlet NSString* contextName;
@property (nonatomic) BOOL isEnableOKButton;

- (void) inputContextNameforWindow:(NSWindow*)window  modalDelegate:(id)deelegate didEndSelector:(SEL)didEndSelector;
@end

NS_ASSUME_NONNULL_END
