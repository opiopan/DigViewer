//
//  ThumbnailViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "BaseViewController.h"

@interface ThumbnailViewController : BaseViewController

@property (assign) double zoomRethio;
@property (weak) IBOutlet IKImageBrowserView *thumbnailView;

- (IBAction)onDefaultSize:(id)sender;
- (IBAction)onUpFolder:(id)sender;

@end
