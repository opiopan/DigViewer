//
//  EditLensSheetController.h
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LensLibrary.h"

@interface EditLensSheetController : NSObject <NSWindowDelegate>

@property (strong) IBOutlet NSPanel *panel;
@property (weak) IBOutlet NSButton *okButton;

@property (strong, nonatomic) NSString* profileName;
@property (strong, nonatomic) NSString* lensMaker;
@property (strong, nonatomic) NSString* lensName;
@property (strong, nonatomic) NSNumber* focalLengthMin;
@property (strong, nonatomic) NSNumber* focalLengthMax;
@property (strong, nonatomic) NSNumber* apertureMin;
@property (strong, nonatomic) NSNumber* apertureMax;
@property (strong, nonatomic) NSNumber* fovMin;
@property (strong, nonatomic) NSNumber* fovMax;
@property (strong, nonatomic) NSNumber* sensorHorizontal;
@property (strong, nonatomic) NSNumber* sensorVertical;
@property (strong, nonatomic) NSNumber* matchingType;

@property (nonatomic) BOOL isSingleFocalLength;

- (IBAction)onOk:(id)sender;
- (IBAction)onCancel:(id)sender;

- (void) editLensEntity:(Lens*)lens forWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
