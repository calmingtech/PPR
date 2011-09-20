//
//  BreatheUploaderAppDelegate.m
//  BreatheUploader
//
//  Created by Poorna Krishnamoorthy on 9/4/11.
//  Copyright 2011 stanford university. All rights reserved.
/* This app is launched from peripheralpacing.app whenever upload.txt
   fills up with 100 bpms for an user.The bpms are uploaded to the web
   server by this app
   App location : ~/Desktop/peripheralpacing
 */

#import "BreatheUploaderAppDelegate.h"
#import "ppDatabaseManager.h"

@implementation BreatheUploaderAppDelegate
#define DATA_PATH @"/peripheralpacing/"
#define LOG_FILE @"upload.txt"
#define MAXLEN 200
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	NSString *dtop_path = [@"~/Desktop" stringByExpandingTildeInPath];
	data_dir = [dtop_path stringByAppendingString:DATA_PATH];
	
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	userName = [args objectAtIndex:1]; //get username as command line arg
	[self uploadData];
}
- (void) uploadData
{ 
	FILE* fp;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *brData = [[[NSMutableArray alloc] initWithCapacity:100] retain];
	
	float timePassed_s;
	int val, running,realtime,cycle,calmpoints,recording_baseline;
	float breathrate,baseline_bpm;
	char dateAbs[80];
	char line[MAXLEN + 1];
	
	fp = fopen([[data_dir stringByAppendingString:LOG_FILE] UTF8String],"r");
	while (fgets(line,MAXLEN,fp)) { 
		//sscanf(line,"%f %d %f %f %d %d %d %d %s %d\n",&timePassed_s,&val,&breathrate,&baseline_bpm,&recording_baseline,&running,&realtime,&cycle,dateAbs,&calmpoints );
		sscanf(line,"%f\n",&breathrate);
		[brData addObject:[NSString stringWithFormat:@"%f", breathrate]];
	}
		
	int rc; 
	if ([brData count] > 0) { 
		rc =[ppDatabaseManager addBPMData:brData forUser:userName];
		NSLog(@"loaded rc=%d for %d records",rc,[brData count]); 
		[brData release];
		fclose(fp);
		//empty upload.txt 
		fopen([[data_dir stringByAppendingString:LOG_FILE] UTF8String],"w");
		fclose(fp);
	}
	
	[pool release];
	[NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0]; 
}

- (void) terminate :(id) sender
{
	exit(1);
}

@end
