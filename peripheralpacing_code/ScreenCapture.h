//
//  ScreenCapture.h
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 7/18/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ScreenCapture : NSObject {
/* 
	IBOutlet NSImageView *outputView;
	IBOutlet NSArrayController *arrayController;
	CGWindowListOption listOptions;
	CGWindowImageOption imageOptions;
	CGRect imageBounds; */
}

// Simple screen shot mode!
+grabScreenShot:(NSString *)fileName;

@end