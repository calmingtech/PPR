//
//  myLogger.m
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 8/11/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import "myLogger.h"


@implementation myLogger
-(id) initWithPath:(NSString *) path logName :(NSString *) logname
{
	datapath = path;
	logFile = [[datapath stringByAppendingFormat:@"/%@",logname] copy];
	dateFormatter = [[NSDateFormatter alloc] init]; // = [[NSDateFormatter alloc] initWithDateFormat:@"%y-%m-%d %H:%M:%S:%F" allowNaturalLanguage:YES];
	[dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm:ss:SSS"];
	return self;
}
-(void) dealloc 
{
	[dateFormatter release];
	[datapath release];
	[logFile release];
	[super dealloc];
}
-(void) log:(NSString *) message 
{
	FILE *logfp = fopen([logFile UTF8String],"a");
	NSDate *now  = [[NSDate date] autorelease];

	if (logfp) { 
		fprintf(logfp,"%s: %s\n",[[dateFormatter stringFromDate:now] UTF8String],[message UTF8String]);
		fclose(logfp);
	}
}
@end
