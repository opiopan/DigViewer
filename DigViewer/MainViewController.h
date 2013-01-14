//
//  MainViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseViewController.h"

enum RepresentationViewType {
    typeImageView,
    typeThumbnailView
};

@interface MainViewController : BaseViewController

@property (assign) enum RepresentationViewType presentationViewType;
@property (weak) IBOutlet NSView *outlinePlaceholder;
@property (weak) IBOutlet NSView *presentationPlaceholder;

@end
