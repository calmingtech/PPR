//
//  ScreenCapture.m
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 7/18/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import "ScreenCapture.h"

@implementation ScreenCapture
-(id) init { 
	[super init];
	return self;
}
+grabScreenShot:(NSString *)fileName
{
	NSTask *task = [[NSTask alloc] init];
	NSArray *args = [NSArray arrayWithObjects:@"-t",@"jpg",@"-x",fileName,nil];
	[task setLaunchPath:@"/usr/sbin/screencapture"];
	[task setArguments:args];
	[task launch];
	[task release];
}
@end