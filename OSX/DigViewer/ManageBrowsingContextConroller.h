//
//  ManageBrowsingContextConroller.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/06.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ManageBrowsingContextConroller : NSObject<NSWindowDelegate>
- (void) manageContexsforWindow:(NSWindow*)window array:(NSMutableArray*)array  modalDelegate:(id)deelegate didEndSelector:(SEL)didEndSelector;
@end

NS_ASSUME_NONNULL_END
