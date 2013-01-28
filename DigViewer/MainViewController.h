//
//  MainViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

enum RepresentationViewType {
    typeImageView,
    typeThumbnailView
};

@interface MainViewController : NSViewController

@property (assign) enum RepresentationViewType presentationViewType;
@property (weak) IBOutlet NSView *outlinePlaceholder;
@property (weak) IBOutlet NSView *presentationPlaceholder;

@end
