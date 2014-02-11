//
//  ChildProcess.h
//  Pathfinder
//
//  Created by opiopan on 2012/12/05.
//
//

#import <Foundation/Foundation.h>
#import <stdarg.h>

@interface ChildProcess : NSObject

@property (readonly) NSMutableString* command;

+ (NSString*)escapedString:(NSString*)str;

- (id)init;
- (id)initWithFormat:(NSString*)fmt, ...;
+ (ChildProcess*)childProcessWithFormat:(NSString*)fmt, ...;

- (void)appendCommandWithString:(NSString*)str;
- (void)appendCommandWithFormat:(NSString*)fmt arguments:(va_list)argList;
- (void)appendCommandWithFormat:(NSString*)fmt, ...;

- (int) execute;

- (BOOL) executeForInput;
- (NSString*)nextLine;
- (int) result;

@end
