//
//  ThumbnailViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface ThumbnailViewController : NSViewController

@property (assign) double zoomRatio;
@property (weak) IBOutlet IKImageBrowserView *thumbnailView;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSArrayController *imageArrayController;
@property (nonatomic) BOOL isMagnifiedThumbnail;

- (IBAction)onDefaultSize:(id)sender;
- (IBAction)onUpFolder:(id)sender;
- (IBAction)onDownFolder:(id)sender;

@end
