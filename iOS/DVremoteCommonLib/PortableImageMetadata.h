//
//  PortableImageMetadata.h
//  DigViewerRemote
//
//  Created by opiopan on 2016/01/01.
//  Copyright © 2016年 opiopan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PortableImageMetadata : NSObject

@property (readonly) NSData* imageData;
@property (readonly) NSString* name;
@property (readonly) NSString* type;
@property NSString* documentName;
@property NSArray* path;
@property NSInteger indexInParent;
@property BOOL namespaceChanged;
@property BOOL entityChanged;

- (id) initWithImage:(NSData*)imageData name:(NSString*)name type:(NSString*)type;
- (NSDictionary*) portableData;

@end
