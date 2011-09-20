//
//  myLogger.h
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 8/11/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface myLogger : NSObject {
	NSString *datapath;
	NSString *logFile;
	NSDate *date;
	NSDateFormatter *dateFormatter;
}
-(id) initWithPath:(NSString *) path logName :(NSString *) logname;

- (void) log:(NSString *)message;

@end
