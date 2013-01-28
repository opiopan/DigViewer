//
//  ThumbnailViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface ThumbnailViewController : NSViewController

@property (assign) double zoomRethio;
@property (weak) IBOutlet IKImageBrowserView *thumbnailView;

- (IBAction)onDefaultSize:(id)sender;
- (IBAction)onUpFolder:(id)sender;
- (IBAction)onDownFolder:(id)sender;

@end
