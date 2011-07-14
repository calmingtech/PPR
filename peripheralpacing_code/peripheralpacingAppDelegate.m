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
#import <Carbon/Carbon.h>
#import <QuartzCore/QuartzCore.h>
#import <CorePlot/CorePlot.h>
#import "plotGraph.h"

@implementation peripheralpacingAppDelegate

@synthesize window;

//mode 1 = screen brightness, mode 2 = menu dimming, mode 3 = bouncing rect

#define SERIALPORTNAME "/dev/tty.usbmodem621"
#define max(a,b) (a>b)? a : b

#define GRAPHICS_PATH @"/peripheralpacing/graphics/"
#define DATA_PATH @"/peripheralpacing/"

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


- (void)setupAvatars
{
	srand(time(NULL));
	char* names[] = {"@trevor", "@lester", "@copeland", "@eamonn", "@april_l", "@julie", "@gremlin404", "@iso64000", "@its_amy",\
		"@isabel", "@deansmall", "@maribel", "@price", "@LisaHansen", "@desertsol", "@j0n", "@MadisoN", "@dianna", "@fisforfrank",\
		"@plinnet", "@velo_nut", "@ErinRG", "@its__Alive", "@AlexCC", "@chefJune", "@snorkjuice", "@crindy", "@wallace"};
	
	//int ids[NUM_USERS];
	//for (int i=0; i<NUM_USERS; i++)
	//	ids[i] = -1;
	
    int ids[] = {17,18,9,10,2,13};
    
	int allocated = 0;
	while(allocated<NUM_USERS)
	{
		//int id = rand()%28;
		
		//bool alreadyChosen = false;
		//for (int i=0; i<NUM_USERS; i++)
		//	if (ids[i] == id)
		//		alreadyChosen = true;
		//if (alreadyChosen)
		//	continue;
		
        int id = ids[allocated];
		users[allocated] = [[NSString stringWithFormat:@"%s",names[id]] retain];
		usersIcons[allocated] = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:\
								[NSString stringWithFormat:@"/Image%d.png",id]]];
		printf("%s\n",[users[allocated] UTF8String]);
		
		allocated++;
	}
	
	char buffer[128];
	NSString *usernamef = [[NSString alloc] initWithContentsOfFile:[data_dir stringByAppendingString:@"/username.txt"]];
	sscanf([usernamef UTF8String],"%s",&buffer);
	printf("%s\n",buffer);
	myName = [NSString stringWithFormat:@"%s",buffer];
	
	myImage = [[NSImage alloc] initWithContentsOfFile:[data_dir stringByAppendingString:@"/me.png"]];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSString *dtop_path = [@"~/Desktop" stringByExpandingTildeInPath];
	graphics_dir = [dtop_path stringByAppendingString:GRAPHICS_PATH];
	[graphics_dir retain];
	data_dir = [dtop_path stringByAppendingString:DATA_PATH];
	[data_dir retain];
	
	blankImage = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:@"/blankg.png"]];
	
	userSyncingFrom = @"Snork Juice";
	userSyncingFromIcon = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:@"/me.png"]];
	
	userSyncingTo = @"Bert Macklin";
	userSyncingToIcon = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:@"/me.png"]];
	
	
	notification_time = -1.0;
    
    realtime = true;
	
	
	[self setupAvatars];
	
		
	displaymode = 0;
	running = false;
	baseline_bpm = 15.0;
	recording_baseline = false;
	calibrateMode = false;
	colorMode = false;
	cycle = false;
	
	// Create transparent window.
	//NSRect screensFrame = [[NSScreen mainScreen] frame];
	//for (NSScreen *thisScreen in [NSScreen screens]) {
	//	screensFrame = NSUnionRect(screensFrame, [thisScreen frame]);
	//}
	int width = [[NSScreen mainScreen] frame].size.width;
	int height = [[NSScreen mainScreen] frame].size.height;
	
	NSRect screensFrame = NSMakeRect(0, height-22, width, 22);
	//NSRect screensFrame = NSMakeRect(0, height-22, 400, 22);
	window = [[MGTransparentWindow windowWithFrame:screensFrame] retain];
	cal_window = [[MGTransparentWindow windowWithFrame:screensFrame] retain];
	
	NSRect notifyFrame = NSMakeRect(width-280,height-202, 272, 172);
	notify_window = [[MGTransparentWindow windowWithFrame:notifyFrame] retain];
	
//	NSRect graphFrame = NSMakeRect(0,height-100, 100, 100);
//	graph_window = [[plotGraph windowWithFrame:graphFrame] retain];
					
	[notify_window setReleasedWhenClosed:YES];
	[notify_window setHidesOnDeactivate:NO];
	[notify_window setCanHide:NO];
	[notify_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[notify_window setIgnoresMouseEvents:YES];
	[notify_window setLevel:NSScreenSaverWindowLevel];
	[notify_window setDelegate:self]; 
	
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
	// @poorna 
	// Configure interval_window.
	[ interval_window setReleasedWhenClosed:YES];
	[interval_window  setHidesOnDeactivate:NO];
	[interval_window  setCanHide:NO];
	[interval_window  setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[interval_window  setIgnoresMouseEvents:NO];
	[interval_window  setLevel:NSScreenSaverWindowLevel];
	[interval_window  setDelegate:self];
	// Configure color_window.
	[color_window setReleasedWhenClosed:YES];
	[color_window setHidesOnDeactivate:NO];
	[color_window setCanHide:NO];
	[color_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[color_window setIgnoresMouseEvents:YES];
	[color_window setLevel:NSScreenSaverWindowLevel];
	[color_window setDelegate:self];
	// @poorna
	// Configure graph window.
	/* [graph_window setReleasedWhenClosed:YES];
		[graph_window setHidesOnDeactivate:NO];
		[graph_window setCanHide:NO];
		[graph_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		[graph_window setIgnoresMouseEvents:YES];
		[graph_window setLevel:NSScreenSaverWindowLevel];
		[graph_window setDelegate:self]; */
	
	// Configure contentView for pacing bar
	NSView *contentView = [window contentView];
	[contentView setWantsLayer:YES];
	CALayer *layer = [contentView layer];
	layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.4, 0.0, 1.0);;
	layer.opacity = 0.0;
	[window makeFirstResponder:contentView];
	
	bar_imview1 =  [[NSImageView alloc] initWithFrame:NSMakeRect(24, 0, 22, 22)];
	bar_imview2 =  [[NSImageView alloc] initWithFrame:NSMakeRect(72, 0, 22, 22)];
	bar_imview3 =  [[NSImageView alloc] initWithFrame:NSMakeRect(120, 0, 22, 22)];
	bar_imview4 =  [[NSImageView alloc] initWithFrame:NSMakeRect(168, 0, 22, 22)];
	bar_imview5 =  [[NSImageView alloc] initWithFrame:NSMakeRect(216, 0, 22, 22)];
	
	[bar_imview1 setImage:usersIcons[0]];
	[bar_imview2 setImage:blankImage];
	[bar_imview3 setImage:blankImage];
	[bar_imview4 setImage:blankImage];
	[bar_imview5 setImage:blankImage];

	[contentView addSubview:bar_imview1];
	[contentView addSubview:bar_imview2];
	[contentView addSubview:bar_imview3];
	[contentView addSubview:bar_imview4];
	[contentView addSubview:bar_imview5];
	
	// Configure contentView for calibration bar
	contentView = [cal_window contentView];
	[contentView setWantsLayer:YES];
		layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[cal_window makeFirstResponder:contentView];

	
	// Configure contentView for notification window
	contentView = [notify_window contentView];
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[window makeFirstResponder:contentView];
	
	// Configure contentView for graph window
	contentView = [graph_window contentView];
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[graph_window makeFirstResponder:contentView];
	
	//configure intervalView for update interval 
	contentView = [interval_window contentView];
	NSRect intRect = NSMakeRect(400.f, 400.f, 20.f, 20.f);
	intervalTextField = [[NSTextField alloc] initWithFrame:intRect];
	[intervalTextField setEditable:YES];
	[intervalTextField setStringValue:@"--update time interval"];
	[intervalTextField setBackgroundColor:[NSColor blackColor]];
	[intervalTextField setTextColor:[NSColor whiteColor]];
	[intervalTextField setFont:[NSFont fontWithName:@"Helvetica" size:20]];
	[intervalTextField setBordered:TRUE];
	[contentView addSubview:intervalTextField];
	[intervalTextField release];
	
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[interval_window makeFirstResponder:contentView];
		
	//configure colorView to toggle color changes 
	contentView = [color_window contentView];
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[color_window makeFirstResponder:contentView];
	
		
	NSRect myRect = NSMakeRect(38.f, -10.f, 220.f, 160.f);
	notifyTextField = [[NSTextField alloc] initWithFrame:myRect];
	[notifyTextField setEditable:NO];
	[notifyTextField setStringValue:@"You just re-breathcast @fakeuser's calmness for 3:12. Now breathcasting your calm."];
	[notifyTextField setBackgroundColor:[NSColor blackColor]];
	[notifyTextField setTextColor:[NSColor whiteColor]];
	[notifyTextField setFont:[NSFont fontWithName:@"Helvetica" size:20]];
	[notifyTextField setBordered:false];
	[contentView addSubview:notifyTextField];
	[notifyTextField release];
	 
	NSImage *notify_avatar = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:@"/me.png"]];
	notify_imview =  [[NSImageView alloc] initWithFrame:NSMakeRect(8, 75, 22, 22)];
	[notify_imview setImage:notify_avatar];
	[contentView addSubview:notify_imview];
	[notify_imview release];
	[notify_avatar release];
	
	// Put this app into the background (the shade won't hide due to how its window is set up above).
	[NSApp hide:self];
	
	// Put window on screen.
	[window makeKeyAndOrderFront:self];
	[cal_window makeKeyAndOrderFront:self];
	[notify_window makeKeyAndOrderFront:self];
	[interval_window makeKeyAndOrderFront:self];
	[color_window makeKeyAndOrderFront:self];
	//[graph_window makeKeyAndOrderFront:self];
	
	//run dat looooop
	[NSThread detachNewThreadSelector:@selector(mainloop:) toTarget:self withObject:nil];
}



- (void) notify:(NSString*)message duration:(float) time icon:(NSImage*)avatar
{
	//Log data here, add timestamp (change time_passed thing to be global[er])
	//FILE* fp;
	//fp = fopen([[data_dir stringByAppendingString:@"notifylog.txt"] UTF8String],"a");
	//fprintf(fp,"%s [shown for %f seconds]\n",[message UTF8String],time);
	//fclose(fp);
	
	
	if (notification_time>0.0)
		return;
	notification_time = time;
	[self changeNotificationIcon:avatar];
	//[NSThread detachNewThreadSelector:@selector(showNotification:) toTarget:self withObject:message];
}


- (void) showNotification:(NSString*)message
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	printf("%s for %f\n",[message UTF8String],notification_time);
	NSView *contentView = [notify_window contentView];
	CALayer *layer = [contentView layer];
	layer.opacity = 0.8;
	
	[notifyTextField setStringValue:message];
	
	[notify_window display];
	while(notification_time>0.0)
	{
		[NSThread sleepForTimeInterval:0.1];
		//printf("noti time: %f\n",notification_time);
		notification_time -= 0.1;
	}
	
	layer.opacity = 0.0;
	[notify_window display];
	//[pool release];
	[pool drain];
}

- (void) changeNotificationIcon:(NSImage*) avatar
{
	[notify_imview setImage:avatar];
	[notify_window display];
}


- (void) waitAndNotifyOfRB
{
	//provide me with (more) randomly generated random numbers
	srand(time(NULL));
	float durationOfRB = 0;
	
	const int iters = 4;
	for (int i=0; i<iters; i++)
		durationOfRB += 540*(rand()%1000/(1000.0*iters));
	durationOfRB -= 270;
	durationOfRB = 30 + fabs(durationOfRB);
	
	printf("duration of RB from a fake user: %f\n",durationOfRB);
	
	float wait_time = durationOfRB+8.0;
	
	while(wait_time>0.0)
	{
		//used for testing only
		[NSThread sleepForTimeInterval:2.0];
		//printf("noti time: %f\n",notification_time);
		wait_time -= 2.0;
	}
	
	[self pickRandomUserTo];
	[self notify:[NSString stringWithFormat:@"%@ just rebreathed your calm for %d seconds! You're Winner!", \
				  userSyncingTo,(int)durationOfRB,userSyncingFromIcon] duration:7.0 icon:userSyncingToIcon];
	
	if (rand()%5==3)
	{
		[NSThread detachNewThreadSelector:@selector(waitAndNotifyOfRB) toTarget:self withObject:nil];
	}
}


- (void) pickRandomUserFrom {
	
	//weight tables derived from looking at "real" data
	int rtable1[] = {0,0,0,0,0,0,1,1,2,2};
	int rtable2[] = {0,0,0,0,1,1,1,1,2,2};
	int rtable3[] = {0,0,0,1,1,1,2,2,2,2};
	int rtable4[] = {0,0,0,1,1,1,1,2,2,2};
	int *rtable = rtable1;
	
	int t=time(NULL);
	
	if (t%2400>=600 && t%2400<1200)
		rtable = rtable2;
	if (t%2400>=1200 && t%2400<1800)
		rtable = rtable3;
	if (t%2400>=1800 && t%2400<2400)
		rtable = rtable4;
	

    int offset = 0;
    if (realtime)
        offset=3;
    int randomint;
	do {
		//uniform selection
		//randomint = rand()%NUM_USERS;
		//weighted selection
		randomint = rtable[rand()%10];
		//printf("USER_FROM: %d - %s\n",randomint,[users[randomint] UTF8String]);

		userSyncingFrom = users[randomint+offset];
		userSyncingFromIcon = usersIcons[randomint+offset];
	} while (userSyncingTo==userSyncingFrom);

	//come up with a duration for the visualization based on the random tables
	int totalWeight = 0;
	for (int i=0; i<10; i++)
		if (rtable[i]==randomint)
			totalWeight++;
	vis_duration = 60.0 + (rand()%totalWeight*10) + (rand()%1000)/100.0;
	printf("vis_duration: %f totalWeight: %d \n",vis_duration, totalWeight);
	
	[bar_imview1 setImage:blankImage];
	[bar_imview2 setImage:blankImage];
	[bar_imview3 setImage:blankImage];
	[bar_imview4 setImage:blankImage];
	[bar_imview5 setImage:blankImage];
	
	//add additional users to bar randomly
	randomint = rand()%10;
	if (randomint<=2)
		return;
    if (randomint>=3 && randomint<=7)
        [bar_imview1 setImage:userSyncingFromIcon];
	if (randomint>=8 && randomint<=9)
	{
        [bar_imview1 setImage:userSyncingFromIcon];
		NSImage* seconduser = userSyncingFromIcon;
		do {
			int rando = rand()%3;
			//printf("%d - rando\n",rando);
			seconduser = usersIcons[rando+offset];
		} while (!(seconduser!=userSyncingFromIcon));
		[bar_imview2 setImage:seconduser];
	}
	if (randomint>=100000)
	{
		int additionalusers = 2;// + rand()%3;
		NSImage *seconduser = userSyncingFromIcon;
		NSImage *thirduser = userSyncingFromIcon;
		NSImage *fourthuser = userSyncingFromIcon;
		NSImage *fifthuser = userSyncingFromIcon;
		if (additionalusers>=2)
		{
			do {
				int rando1 = rand()%NUM_USERS;
				int rando2 = rand()%NUM_USERS;
				//printf("%d - rando1, %d - rando2\n",rando1,rando2);
				if (rando1==rando2)
					continue;
				seconduser = usersIcons[rando1];
				thirduser = usersIcons[rando2];
			} while (!(seconduser!=userSyncingFromIcon && thirduser!=userSyncingFromIcon));
			[bar_imview2 setImage:seconduser];
			[bar_imview3 setImage:thirduser];
		}
		if (additionalusers>=3)
		{
			do {
				int rando = rand()%NUM_USERS;
				fourthuser = usersIcons[rando];
			} while (!(fourthuser!=userSyncingFromIcon && fourthuser!=seconduser && fourthuser!=thirduser));
			[bar_imview4 setImage:fourthuser];
		}
		if (additionalusers>=4)
		{
			do {
				int rando = rand()%NUM_USERS;
				fifthuser= usersIcons[rando];
			} while (!(fifthuser!=userSyncingFromIcon && fifthuser!=seconduser && fifthuser!=thirduser && fifthuser!=fourthuser));
			[bar_imview5 setImage:fifthuser];
		}
	}
}


- (void) pickRandomUserTo {
	do 
	{
		int randomint = rand()%NUM_USERS;
		//printf("USER_TO: %d - %s\n",randomint,[users[randomint] UTF8String]);
		userSyncingTo = users[randomint];
		userSyncingToIcon = usersIcons[randomint];
	} while (userSyncingTo==userSyncingFrom);
}


-(void)awakeFromNib{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];
	[statusItem setTitle:@"Breathcast"];
	[statusItem setHighlightMode:YES];
	
	start_stop = [statusMenu addItemWithTitle:@"Start" action:@selector(toggle_on_off:) keyEquivalent:@""];
	SendModeItem = [statusMenu addItemWithTitle:@"Turn Realtime Off" action:@selector(toggle_send:) keyEquivalent:@""];
	recordBaseline = [statusMenu addItemWithTitle:@"Record Baseline" action:@selector(record_baseline:) keyEquivalent:@""];
	increaseBaselineItem = [statusMenu addItemWithTitle:@"Increase Baseline" action:@selector(increaseBaseline:) keyEquivalent:@""];
	decreaseBaselineItem = [statusMenu addItemWithTitle:@"Decrease Baseline" action:@selector(decreaseBaseline:) keyEquivalent:@""];
	graphItem = [statusMenu addItemWithTitle:@"View Breath Performance" action:@selector(viewGraph:) keyEquivalent:@""];
	//displayOff = [statusMenu addItemWithTitle:@"Feedback Off" action:@selector(set_display_off:) keyEquivalent:@""];
	//displayScreen = [statusMenu addItemWithTitle:@"Screen Dim Feedback" action:@selector(set_display_screen:) keyEquivalent:@""];
	//displayMenu = [statusMenu addItemWithTitle:@"Menu Dim Feedback" action:@selector(set_display_menu:) keyEquivalent:@""];
	//displayBounce = [statusMenu addItemWithTitle:@"Bounce Feedback" action:@selector(set_display_bounce:) keyEquivalent:@""];
	calibrateToggle = [statusMenu addItemWithTitle:@"Turn Calibration On" action:@selector(calibrate_on_off:) keyEquivalent:@""];
	intervalItem = [statusMenu addItemWithTitle:@"Change Update Interval" action:@selector(set_interval:) keyEquivalent:@""];
	colorToggle = [statusMenu addItemWithTitle:@"Change Color based on Rate On" action:@selector(color_on_off:) keyEquivalent:@""];
	[statusMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
}
- (void) viewGraph:(id) sender
{
	//placeholder for now
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

- (void) increaseBaseline:(id)sender
{
	baseline_bpm = baseline_bpm+1;
	printf("%f\n",baseline_bpm);
    [recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
}

- (void) decreaseBaseline:(id)sender
{
	baseline_bpm = baseline_bpm-1;
	printf("%f\n",baseline_bpm);
    [recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
}

- (void) toggle_send:(id)sender
{
    realtime=!realtime;
    if (realtime==false)
    {
        NSView *contentView = [window contentView];
        [contentView setWantsLayer:YES];
        CALayer *layer = [contentView layer];
        layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.6, 1.0);
        layer.opacity = 0.0;
		blankImage = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:@"/blankb.png"]];
        [SendModeItem setTitle:@"Turn Realtime On"];
    }
    if (realtime==true)
    {
        NSView *contentView = [window contentView];
        [contentView setWantsLayer:YES];
        CALayer *layer = [contentView layer];
        layer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.4, 0.0, 1.0);
        layer.opacity = 0.0;
		blankImage = [[NSImage alloc] initWithContentsOfFile:[graphics_dir stringByAppendingString:@"/blankg.png"]];
        [SendModeItem setTitle:@"Turn Realtime Off"];
    }
}


- (void) calibrate_on_off:(id)sender
{
	//[self pickRandomUserFrom];
	//[self notify:[NSString stringWithFormat:@"moo %@",userSyncingFrom] duration:2.1 icon:userSyncingFromIcon];
	
	if (calibrateMode) {
		[calibrateToggle setTitle:@"Turn Calibration On"];
		calibrateMode = false;
		[[cal_window contentView] layer].opacity = 0.0;
		[cal_window display];
	}
	else {
		[calibrateToggle setTitle:@"Turn Calibration Off"];
		calibrateMode = true;
		[[cal_window contentView] layer].opacity = 0.2;
		[cal_window display];
	}


}
- (void) set_interval:(id) sender 
{
	last_display = [intervalTextField floatValue];
	if ((last_display < 0) || (last_display > 3600))
		last_display = 10;  //default interval 10 seconds.
}
- (void) color_on_off:(id) sender
{
	if (colorMode) {  
		[colorToggle setTitle:@"Change Color based on Rate On"];
		colorMode = false;
	//	[[color_window contentView] layer].opacity = 0.0;
	//	[color_window display];
	}
	else { 
		[colorToggle setTitle:@"Change Color based on Rate Off"];
		colorMode = true;
	//	[[color_window contentView] layer].opacity = 0.2;
	//	[color_window display];
	}
	[self set_breath_rate_view : breathrate :baseline_bpm];	
}
- (void) toggle_on_off:(id)sender
{
	//int randomint = rand()%NUM_USERS;
	//userSyncingFromIcon = usersIcons[randomint];
	//userSyncingFrom = users[randomint];
	running = !running;
	if (running) {
		[self pickRandomUserTo];
		[self pickRandomUserFrom];
		[start_stop setTitle:@"Stop"];
		displaymode = 3;
		[self set_brightness_menu:1.0];
	}
	if (running==false)
	{
		[start_stop setTitle:@"Start"];
		displaymode = 0;
		//[statusItem setTitle:@"Last Score:N/A"];
		//[self set_brightness_screen:1.0];
		[self set_brightness_menu:1.0];
	}
}

- (void) set_display_off:(id)sender
{
	displaymode = 0;
	//[statusItem setTitle:@"Last Score:N/A"];
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
		//[self set_brightness_screen:1.0];
		
		int height = [[NSScreen mainScreen] frame].size.height;
		[window setFrameOrigin:NSMakePoint(0, height-22)];
	}
}

- (void) set_display_bounce:(id)sender
{
	if (running)
	{
		displaymode = 3;
		//[self set_brightness_screen:1.0];
		[self set_brightness_menu:1.0];
		//[window setFrame:NSMakeRect(0, 0, 300, 300)];
	}
}

- (void) terminate:(id)sender
{
	//[self set_brightness_screen:1.0];
	exit(1);
}



- (void) set_brightness:(float)new_brightness progress:(float)prog{
	if (displaymode==1)
		[self set_brightness_screen:new_brightness];
	
	if (displaymode==2)
		[self set_brightness_menu:new_brightness];
	
	if (displaymode==3)
	{
        if (prog<0.75)
            prog = 0;
        else
            prog = (prog-0.75)/0.25;
		if (cycle)
			[self set_brightness_menu:0.8 + 0.2*prog];
		else
			[self set_brightness_menu:1.0];

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
		normalisedPos = 342.0-(26.0*relativePos)*(26.0*relativePos);
	}

	
	NSRect theFrame = [window frame];
	NSPoint theOrigin = theFrame.origin;
	theOrigin.y = (int)normalisedPos;
	[window setFrameOrigin:theOrigin];
	//printf("%f\n",relativePos);
}
//@poorna - june22,2011
- (void)set_breath_rate_view:(float) br_rate :(float) base_rate
{
	int percentChange = (int)(br_rate) * 100/base_rate;

	NSString *trend = [NSString stringWithFormat:@"%d%% (%.1f bpm)",percentChange,br_rate];
	NSMutableAttributedString *statusDisplay = [[NSMutableAttributedString alloc] initWithString:@"Breathcast "];
	NSFont *font = [NSFont fontWithName:@"Helvetica" size:14.0];
	NSRange range = NSMakeRange(0, [statusDisplay length]);
	[statusDisplay addAttribute:NSFontAttributeName value:font range:range];

    NSMutableAttributedString *trendAttr = [[NSMutableAttributedString alloc] initWithString:trend];
	range = NSMakeRange(0, [trendAttr length]);
	NSColor *showColor;
	if (colorMode)
		showColor =(percentChange > 100) ? [NSColor redColor] : [NSColor blueColor];
	else 
		showColor = [NSColor blackColor];

	
	[trendAttr addAttribute:NSForegroundColorAttributeName value:showColor range:range];
	[statusDisplay appendAttributedString:trendAttr];
	
	[statusItem setTitle:statusDisplay];

}

- (void) mainloop:(NSConnection *)connection
{
	//I don't know what this does, but it seems to help avoid error messages
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//provide quality random numbers for this thread
	srand(time(NULL));
	
	printf("%s\n",[[data_dir stringByAppendingString:@"serialport.txt"] UTF8String]);
	NSString *serial_name = [[NSString alloc] initWithContentsOfFile:[data_dir stringByAppendingString:@"/serialport.txt"]];
	char serialportName[128];
	int percentAboveBaseline;
	int percentBelowBaseline;
	sscanf([serial_name UTF8String],"%s %d %d",&serialportName,&percentAboveBaseline,&percentBelowBaseline);
	printf("%s, %d, %d\n",serialportName,percentAboveBaseline,percentBelowBaseline);
	[serial_name release];
	//int fd = serialport_init([serial_name UTF8String], 9600);
	int fd = serialport_init(serialportName, 9600);
	char buf[256];
	
	int val;
	//int baseline=0;
	
	// Get a current time for where you want to start measuring from
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; // = [[NSDateFormatter alloc] initWithDateFormat:@"%y-%m-%d %H:%M:%S:%F" allowNaturalLanguage:YES];
	[dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm:ss"];
	// Find elapsed time
	// Use (-) modifier to conversion since receiver is earlier than now
	NSTimeInterval timePassed_s;
	
	BreathRate *br = [[BreathRate alloc] init];
	
	float bright = 0.2;
	[self set_brightness:bright progress:0.0];
	float direction = 1.5;
	float last_timePassed_s = 0.0;
	
	float cycle_started = 0;
	int cycles_since_interval = 0;
	//float last_score = 1.0;
	float total_error = 0.0;
	int cycle_samples = 0;
	
	float calm_duration = 0.0;
	last_display = 0.0;
	
	vis_duration = 60.0;
	int samplecount = 0;
	
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
		samplecount = samplecount++%NUM_SAMPLES;
		//printf("adding %dth sample=%d ",samplecount,val); 
		[br add_sample:val :timePassed_s];
		breathrate = [br getBreathRate];
		//NSDate *now = [NSDate dateWithTimeIntervalSinceNow:timePassed_s];
		NSDate *now = [NSDate date];

		NSString *dateString = [dateFormatter stringFromDate:now];
		NSNumber *milliSecs = [NSNumber numberWithLongLong:timePassed_s * 1000];
		NSString *timestamp = [NSString stringWithFormat:@"%@:%.2i",dateString,milliSecs];
		if (recording_baseline)
		{
			baseline_total += breathrate;
			baseline_iterations++;
		}
	//	printf("logtime:%s ,time: %f, read: %d, breath rate: %f, calm_moment: %d\n",[timestamp UTF8String], timePassed_s,val,breathrate,calm_moment);
		NSLog(@"logtime:%@, time: %f,read : %d, breath rate: %f ,calm_moment: %d\n",timestamp,timePassed_s,val,breathrate,calm_moment);
		if (calibrateMode)
		{
			NSRect theFrame = [window frame];
			NSPoint theOrigin = theFrame.origin;
			theOrigin.y = 2*(val-400);
			[cal_window setFrameOrigin:theOrigin];
		}
		
		float time_delta = timePassed_s - last_timePassed_s;
		
		
		//Log data here
		FILE* fp;
		//printf("%s\n",[[data_dir stringByAppendingString:@"log.txt"] UTF8String]);
		fp = fopen([[data_dir stringByAppendingString:@"log.txt"] UTF8String],"a");
		//printf("opened\n");
		fprintf(fp,"%.2f %d %.2f %.2f %.2f %.2f %.2f %d %d %d %d\n",timePassed_s,val,breathrate,baseline_bpm,[br getInhaleExhaleRatio], [br getInhaleRestPerMinute],[br getExhaleRestPerMinute],recording_baseline,running,realtime,cycle);
		//printf("appended\n");
		fclose(fp);
		if ((last_display += time_delta) > 10) { 
			[self set_breath_rate_view: breathrate :baseline_bpm];
			last_display = 0;
		}

		if (running)
		{
			if (calm_moment)
			{
				calm_duration += time_delta;
				if (breathrate>(1.1*(100-percentBelowBaseline)/100.0)*baseline_bpm)
				{
					calm_moment = false;
					if (calm_duration<60.0) {
					}
					else {
						[self notify:[NSString stringWithFormat:@"You just achieved calm for %d seconds! Breathcasting to other users", \
									  (int)calm_duration] duration: 10.0 icon:myImage];
						[NSThread detachNewThreadSelector:@selector(waitAndNotifyOfRB) toTarget:self withObject:nil];
					}
				}
			}
			if (!cycle)
			{
				if ((breathrate>baseline_bpm*((100+percentAboveBaseline)/100.0)) && (cycles_since_interval<3))
				{
					cycle = true;
					
					calm_moment_rb = true;
					
					[self pickRandomUserFrom];
					
					calm_duration = 0.0;
					
					cycle_started = timePassed_s;
					total_error = 0.0;
					cycle_samples = 0;
					cycles_since_interval++;
				}
			}	
			if ((int)floor(timePassed_s)%360==0) //this assumes multiple samples come in per second, which might not be true, but if it isn't then nothing will work anyway
			{
				cycles_since_interval = 0;
                cycle = true;
                
                calm_moment_rb = true;
                
                [self pickRandomUserFrom];
                
                calm_duration = 0.0;
                
                cycle_started = timePassed_s;
                total_error = 0.0;
                cycle_samples = 0;
                cycles_since_interval++;
                
			}
			if (breathrate<baseline_bpm*((100-percentBelowBaseline)/100.0) && !calm_moment && !calm_moment_rb)
			{
				calm_moment = true;
				calm_duration = 0.0;
			}
			if (calm_moment_rb)
			{
				calm_duration += time_delta;
				//give user/program 15 free seconds to adjust
				if ((timePassed_s - cycle_started)>15)
				{
					if (breathrate>(1.1*(100-percentBelowBaseline)/100.0)*baseline_bpm)
					{
						calm_moment_rb = false;
						if (calm_duration<60.0)
						{
							if (calm_duration>16.0)
								[self notify:[NSString stringWithFormat:@"You just breathsynced with %@ for %d seconds!", \
											  userSyncingFrom, (int)calm_duration] duration: 8.0 icon:userSyncingFromIcon];
						}
						else {
							[self notify:[NSString stringWithFormat:@"You just breathsynced with %@ for %d seconds! ReBreathcasting to other users", \
										  userSyncingFrom, (int)calm_duration] duration: 10.0 icon:userSyncingFromIcon];
							[NSThread detachNewThreadSelector:@selector(waitAndNotifyOfRB) toTarget:self withObject:nil];
						}
					}
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
				[self set_brightness:bright progress:((timePassed_s - cycle_started)/vis_duration)];
				if ((timePassed_s - cycle_started)>vis_duration)
				{
					cycle = false;
					//calculate score
					//int old_score = last_score;
					//last_score = total_error/cycle_samples;
					
					if (displaymode>0)
					{
						//NSString *str = [NSString stringWithFormat:@"Last Score:%d/100 (+%d)",(int)(100-100*last_score),(int)(100-100*last_score)-(int)(100-100*old_score)];
						//[statusItem setTitle:str];
					}
				}
			}
			else
			{
				[self set_brightness:1.0 progress:0.0];
			}
			
			
			
			
		}
		
		last_timePassed_s = timePassed_s;
		
	}
	
	[pool release];

}


@end


