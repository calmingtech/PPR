//
//  peripheralpacingAppDelegate.m
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "peripheralpacingAppDelegate.h"
#import "BreathRate.h"
#import "arduino-serial.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import "MGTransparentWindow.h"

@implementation peripheralpacingAppDelegate

@synthesize window;

//mode 1 = screen brightness, mode 2 = menu dimming, mode 3 = bouncing rect

#define SERIALPORTNAME "/dev/tty.usbmodem621"
#define max(a,b) (a>b)? a : b


/*
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	
	//Code for reading breath data from a csv file
	
	printf("testing\n");
	
    NSString *info = [[NSString alloc] initWithContentsOfFile:@"../../data.csv"];
    NSArray *arrayOfLines = [info componentsSeparatedByString:@"\n"];
	
	BreathRate *br = [[BreathRate alloc] init];
	
	for (int i=0; i<[arrayOfLines count]-1; i++)
	{
		//printf("%s",[[arrayOfLines objectAtIndex:i] UTF8String]);
		int num;
		float time;
		sscanf([[arrayOfLines objectAtIndex:i] UTF8String],"%f,%d\n",&time,&num);
		//printf("%d --- %f\n",num,time);
		[br add_sample:num :time];
		printf("Breath Rate at time %f: %f\n",time,[br getBreathRate]);
	}
	
}
*/






- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	displaymode = 0;
	running = false;
	baseline_bpm = 15.0;
	recording_baseline = false;
	calibrateMode = false;
	
	// Create transparent window.
	//NSRect screensFrame = [[NSScreen mainScreen] frame];
	//for (NSScreen *thisScreen in [NSScreen screens]) {
	//	screensFrame = NSUnionRect(screensFrame, [thisScreen frame]);
	//}
	int width = [[NSScreen mainScreen] frame].size.width;
	int height = [[NSScreen mainScreen] frame].size.height;
	
	NSRect screensFrame = NSMakeRect(0, height-22, width, 22);
	window = [[MGTransparentWindow windowWithFrame:screensFrame] retain];
	cal_window = [[MGTransparentWindow windowWithFrame:screensFrame] retain];

	
	// Configure window.
	[window setReleasedWhenClosed:YES];
	[window setHidesOnDeactivate:NO];
	[window setCanHide:NO];
	[window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[window setIgnoresMouseEvents:YES];
	[window setLevel:NSScreenSaverWindowLevel];
	[window setDelegate:self];
	
	// Configure cal_window.
	[cal_window setReleasedWhenClosed:YES];
	[cal_window setHidesOnDeactivate:NO];
	[cal_window setCanHide:NO];
	[cal_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[cal_window setIgnoresMouseEvents:YES];
	[cal_window setLevel:NSScreenSaverWindowLevel];
	[cal_window setDelegate:self];
	
	// Configure contentView.
	NSView *contentView = [window contentView];
	[contentView setWantsLayer:YES];
	CALayer *layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[window makeFirstResponder:contentView];
	
	contentView = [cal_window contentView];
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[cal_window makeFirstResponder:contentView];
	
	// Put this app into the background (the shade won't hide due to how its window is set up above).
	[NSApp hide:self];
	
	// Put window on screen.
	[window makeKeyAndOrderFront:self];
	[cal_window makeKeyAndOrderFront:self];
	
	
	//run dat looooop
	[NSThread detachNewThreadSelector:@selector(mainloop:) toTarget:self withObject:nil];
	//[self mainloop];
}




-(void)awakeFromNib{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];
	[statusItem setTitle:@"Last Score:N/A"];
	[statusItem setHighlightMode:YES];
	
	start_stop = [statusMenu addItemWithTitle:@"Start" action:@selector(toggle_on_off:) keyEquivalent:@""];
	recordBaseline = [statusMenu addItemWithTitle:@"Record Baseline" action:@selector(record_baseline:) keyEquivalent:@""];
	displayOff = [statusMenu addItemWithTitle:@"Feedback Off" action:@selector(set_display_off:) keyEquivalent:@""];
	displayScreen = [statusMenu addItemWithTitle:@"Screen Dim Feedback" action:@selector(set_display_screen:) keyEquivalent:@""];
	displayMenu = [statusMenu addItemWithTitle:@"Menu Dim Feedback" action:@selector(set_display_menu:) keyEquivalent:@""];
	displayBounce = [statusMenu addItemWithTitle:@"Bounce Feedback" action:@selector(set_display_bounce:) keyEquivalent:@""];
	calibrateToggle = [statusMenu addItemWithTitle:@"Turn Calibrate Viz On" action:@selector(calibrate_on_off:) keyEquivalent:@""];
	[statusMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
}

- (void) record_baseline:(id)sender
{
	if (recording_baseline==false)
	{
		recording_baseline = true;
		[recordBaseline setTitle:@"..Recording Baseline (press to stop)"];
		baseline_total = 0.0;
		baseline_iterations = 0;
		return;
	}
	if (recording_baseline==true)
	{
		recording_baseline = false;
		
		baseline_bpm = baseline_total/(float)baseline_iterations;
		
		[recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
		return;
	}
}

- (void) calibrate_on_off:(id)sender
{
	if (calibrateMode) {
		[calibrateToggle setTitle:@"Turn Calibrate Viz On"];
		calibrateMode = false;
		[[cal_window contentView] layer].opacity = 0.0;
		[cal_window display];
	}
	else {
		[calibrateToggle setTitle:@"Turn Calibrate Viz Off"];
		calibrateMode = true;
		[[cal_window contentView] layer].opacity = 0.2;
		[cal_window display];
	}

	
}


- (void) toggle_on_off:(id)sender
{
	running = !running;
	if (running) {
		[start_stop setTitle:@"Stop"];
		displaymode = 1;
		[self set_brightness_menu:1.0];
	}
	if (running==false)
	{
		[start_stop setTitle:@"Start"];
		displaymode = 0;
		[statusItem setTitle:@"Last Score:N/A"];
		[self set_brightness_screen:1.0];
		[self set_brightness_menu:1.0];
	}
}

- (void) set_display_off:(id)sender
{
	displaymode = 0;
	[statusItem setTitle:@"Last Score:N/A"];
	[self set_brightness_screen:1.0];
	[self set_brightness_menu:1.0];
}

- (void) set_display_screen:(id)sender
{
	if (running)
	{
		displaymode = 1;
		[self set_brightness_menu:1.0];
	}
}

- (void) set_display_menu:(id)sender
{
	if (running)
	{
		displaymode = 2;
		[self set_brightness_screen:1.0];
		
		int height = [[NSScreen mainScreen] frame].size.height;
		[window setFrameOrigin:NSMakePoint(0, height-22)];
	}
}

- (void) set_display_bounce:(id)sender
{
	if (running)
	{
		displaymode = 3;
		[self set_brightness_screen:1.0];
		[self set_brightness_menu:1.0];
		//[window setFrame:NSMakeRect(0, 0, 300, 300)];
	}
}

- (void) terminate:(id)sender
{
	[self set_brightness_screen:1.0];
	exit(1);
}



- (void) set_brightness:(float)new_brightness {
	if (displaymode==1)
		[self set_brightness_screen:new_brightness];
	
	if (displaymode==2)
		[self set_brightness_menu:new_brightness];
	
	if (displaymode==3)
	{
		[self set_brightness_menu:0.9];
		[self set_bounce_position:new_brightness];
	}

}


const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);

- (void) set_brightness_screen:(float) new_brightness {
	CGDirectDisplayID display[kMaxDisplays];
	CGDisplayCount numDisplays;
	CGDisplayErr err;
	err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
	
	if (err != CGDisplayNoErr)
		printf("cannot get list of displays (error %d)\n",err);
	for (CGDisplayCount i = 0; i < numDisplays; ++i) {
		
		
		CGDirectDisplayID dspy = display[i];
		CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
		if (originalMode == NULL)
			continue;
		io_service_t service = CGDisplayIOServicePort(dspy);
		
		float brightness;
		err= IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness,
										&brightness);
		if (err != kIOReturnSuccess) {
			fprintf(stderr,
					"failed to get brightness of display 0x%x (error %d)",
					(unsigned int)dspy, err);
			continue;
		}
		
		err = IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness,
										 new_brightness);
		if (err != kIOReturnSuccess) {
			fprintf(stderr,
					"Failed to set brightness of display 0x%x (error %d)",
					(unsigned int)dspy, err);
			continue;
		}
		
		if(brightness > 0.0){
		}else{
		}
	}		
}




- (void)set_brightness_menu:(float)newOpacity
{
	float normalisedOpacity = MIN(1, MAX(1-newOpacity, 0.0));
	[[window contentView] layer].opacity = normalisedOpacity;
	
	[window display];
}


- (void)set_bounce_position:(float)relativePos
{
	float normalisedPos;// = 300.0*MIN(1.0, MAX(1.0-relativePos, 0.0));
	if (relativePos<0.6) {
		relativePos-=0.2;
		relativePos*=(5.0/4.0);
		normalisedPos = (26.0*relativePos)*(26.0*relativePos);
	}
	else {
		//relativePos -= 0.6;
		relativePos = 1.0-relativePos;
		relativePos *= (5.0/4.0);
		//relativePos = 0.5-relativePos;
		normalisedPos = 318.0-(26.0*relativePos)*(26.0*relativePos);
	}

	
	NSRect theFrame = [window frame];
	NSPoint theOrigin = theFrame.origin;
	theOrigin.y = (int)normalisedPos;
	[window setFrameOrigin:theOrigin];
	//printf("%f\n",relativePos);
}


- (void) mainloop:(NSConnection *)connection
{
	//I don't know what this does, but it seems to help avoid error messages
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	NSString *serial_name = [[NSString alloc] initWithContentsOfFile:@"serialport.txt"];
	char serialportName[128];
	int percentAboveBaseline;
	int percentBelowBaseline;
	sscanf([serial_name UTF8String],"%s %d %d",&serialportName,&percentAboveBaseline,&percentBelowBaseline);
	printf("%s, %d, %d\n",serialportName,percentAboveBaseline,percentBelowBaseline);
	//int fd = serialport_init([serial_name UTF8String], 9600);
	int fd = serialport_init(serialportName, 9600);
	char buf[256];
	
	int val;
	//int baseline=0;
	
	// Get a current time for where you want to start measuring from
	NSDate *date = [NSDate date];
	
	// Find elapsed time
	// Use (-) modifier to conversion since receiver is earlier than now
	NSTimeInterval timePassed_s = [date timeIntervalSinceNow] * -1.0;
	
	BreathRate *br = [[BreathRate alloc] init];
	
	float bright = 0.2;
	[self set_brightness:bright];
	float direction = 1.5;
	float last_timePassed_s = 0.0;
	bool cycle = false;
	float cycle_started = 0;
	int cycles_since_interval = 0;
	float last_score = 1.0;
	float total_error = 0.0;
	int cycle_samples = 0;
	
	float time_to_log = 1.5;
	
	while(true)
	{
		//used for testing only
		//[NSThread sleepForTimeInterval:0.1];
		serialport_read_until(fd, buf, '\n');
		sscanf(buf,"%d\n",&val);
		//uncomment these lines (and "int baseline=0") to get the brightness to change directly with the sensor
		//if (baseline<400 || baseline>1000)
		//	baseline = val;
		//[self set_brightness:max(0,0.4+(val-baseline)/500.0)];
		timePassed_s = [date timeIntervalSinceNow] * -1.0;
		[br add_sample:val :timePassed_s];
		float breathrate = [br getBreathRate];
		printf("time: %f, read: %d, breath rate: %f\n",timePassed_s,val,breathrate);
		
		if (calibrateMode)
		{
			NSRect theFrame = [window frame];
			NSPoint theOrigin = theFrame.origin;
			theOrigin.y = 2*(val-400);
			[cal_window setFrameOrigin:theOrigin];
		}
		
		float time_delta = timePassed_s - last_timePassed_s;
		
		if (running)
		{
			//Log data here
			FILE* fp;
			fp = fopen("log.txt","a");
			
			fprintf(fp,"%f %d %f %d %f\n",timePassed_s,val,breathrate,cycle,baseline_bpm);
			
			fclose(fp);
			
		}
		
		time_to_log-=time_delta;
		if (time_to_log<0.0)
		{
			if (recording_baseline) {
				baseline_total += breathrate;
				baseline_iterations++;
			}
			
			time_to_log = 1.5;
		}
		
		
		if (!cycle)
		{
			if ((breathrate>baseline_bpm*((100+percentAboveBaseline)/100.0)) && (cycles_since_interval<2))
			{
				cycle = true;
				cycle_started = timePassed_s;
				total_error = 0.0;
				cycle_samples = 0;
				cycles_since_interval++;
			}
			if ((int)floor(timePassed_s)%360==0) //this assumes multiple samples come in per second, which might not be true, but if it isn't then nothing will work anyway
			{
				cycle = true;
				cycle_started = timePassed_s;
				total_error = 0.0;
				cycle_samples = 0;
				cycles_since_interval = 0;
			}
		}
		if (cycle)
		{
			float inc_duration = 30/(((100-percentBelowBaseline)/100.0)*baseline_bpm);
			bright+=(time_delta/inc_duration)*direction;
			if (bright>1 || bright<0.2)
			{
				if (bright>0.5)
					direction = -0.8;
				else
					direction = 0.8;
				total_error += abs(breathrate - baseline_bpm)/baseline_bpm;
				cycle_samples++;
			}
			[self set_brightness:bright];
			if ((timePassed_s - cycle_started)>120)
			{
				cycle = false;
				//calculate score
				int old_score = last_score;
				last_score = total_error/cycle_samples;
				
				if (displaymode>0)
				{
					NSString *str = [NSString stringWithFormat:@"Last Score:%d/100 (+%d)",(int)(100-100*last_score),(int)(100-100*last_score)-(int)(100-100*old_score)];
					[statusItem setTitle:str];
				}
			}
		}
		else
		{
			[self set_brightness:1.0];
		}
		
		
		last_timePassed_s = timePassed_s;
		
	}
	
	[pool release];

}


@end


