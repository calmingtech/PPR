//
//  BreatheUploaderAppDelegate.h
//  BreatheUploader
//
//  Created by Poorna Krishnamoorthy on 9/4/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BreatheUploaderAppDelegate : NSObject <NSApplicationDelegate> {
	NSString *data_dir;
	NSString *userName;
}
- (void) terminate :(id) sender;

- (void) uploadData;

@end
