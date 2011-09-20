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
#import "wirelessHdr.h"
#import "BreathStatController.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import "MGTransparentWindow.h"
#import <Carbon/Carbon.h>
#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import <objc/objc-class.h>
#import "ScreenCapture.h"
#import "Notification.h"

@implementation peripheralpacingAppDelegate

@synthesize window, setBaseline_window, baselinePopup,profile_window;
@synthesize perf_window,notification_window,calm_window, calmImageView;
@synthesize nTextField, userNameTF, profile_button,imageurlTF;
@synthesize highView1,highView2,highView3,lowView1,lowView2, lowView3;
@synthesize highLabel1,highLabel2,highLabel3,lowLabel1,lowLabel2, lowLabel3;

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

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self uilog:@"Application terminating" :YES];
}
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
	sscanf([usernamef UTF8String],"%s",buffer);
	[usernamef release];
	printf("%s\n",buffer);
	myName = [NSString stringWithFormat:@"%s",buffer];
	
	myImage = [[NSImage alloc] initWithContentsOfFile:[data_dir stringByAppendingString:@"/me.png"]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
	snapId = 0;
	NSString *dtop_path = [@"~/Desktop" stringByExpandingTildeInPath];
	graphics_dir = [dtop_path stringByAppendingString:GRAPHICS_PATH];
	[graphics_dir retain];
	data_dir = [dtop_path stringByAppendingString:DATA_PATH];
	[data_dir retain];

	[self ReadAppSettingsFromPropertyFile]; //loads preferences on social and wireless usb

	//remove upload.txt at launch of this app.
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@upload.txt",data_dir] error:nil]; 

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
	//baseline_bpm = 15.0;
	recording_baseline = false;
	calibrateMode = false;
	colorMode = false;
	cycle = false;
	pprMode = false;
	warmupTime = 0;
	display_interval = 1.0;
	upload_interval = 2.0;
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
	// Configure perf window.
	[perf_window setReleasedWhenClosed:NO];
	[perf_window setHidesOnDeactivate:NO];
	[perf_window setCanHide:YES];
	[perf_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[perf_window setLevel:NSScreenSaverWindowLevel];
	[perf_window setDelegate:self]; 
	
	[calm_window setReleasedWhenClosed:NO];
	[calm_window setHidesOnDeactivate:NO];
	[calm_window setCanHide:YES];
	[calm_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[calm_window setLevel:NSScreenSaverWindowLevel];
	[calm_window setDelegate:self]; 
	[calmImageView setImageFrameStyle:NSImageFrameGroove];
	[calmImageView setImageScaling:NSScaleProportionally];
	[calmImageView setAnimates:YES];
	
	[notification_window setReleasedWhenClosed:NO];
	[notification_window setHidesOnDeactivate:NO];
	[notification_window setCanHide:YES];
	[notification_window setDelegate:self]; 
	[notification_window setBackgroundColor:[NSColor blackColor]];
	[nTextField setTextColor:[NSColor blueColor]];
	
	[profile_window setReleasedWhenClosed:NO];
	[profile_window setHidesOnDeactivate:NO];
	[profile_window setCanHide:YES];
	[profile_window setBackgroundColor:[NSColor whiteColor]];
	[profile_window setDelegate:self];
	[profile_window setLevel:NSScreenSaverWindowLevel];
	[profile_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];


	[setBaseline_window setReleasedWhenClosed:NO];
	[setBaseline_window setHidesOnDeactivate:NO];
	[setBaseline_window setCanHide:YES];
	[setBaseline_window setLevel:NSScreenSaverWindowLevel];
	[setBaseline_window setDelegate:self];
	[setBaseline_window setBackgroundColor:[NSColor whiteColor]];
	
	
	[nTextField setBackgroundColor:[NSColor whiteColor]];
	[baselinePopup removeAllItems];
	for (int i = 0; i <=10; ++i) { 
		int index = i - 5;
		[baselinePopup addItemWithTitle:[NSString stringWithFormat:@"%d",index ]];
	}
	[baselinePopup selectItemAtIndex:5];

/*	NSRect checkinFrame = NSMakeRect(width-200,height-200,300, 80);
	notification_window = [[[NSWindow alloc ]initWithContentRect:checkinFrame styleMask:15													backing:NSBackingStoreBuffered
													  defer:NO] retain];
	//confgure notification_window
//	[notification_window setBackgroundColor:[NSColor blueColor]];
	//[window makeKeyAndOrderFront:NSApp];
	[notification_window setReleasedWhenClosed:NO];
	[notification_window setHidesOnDeactivate:NO];
	[notification_window setCanHide:YES];
	[notification_window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	//	[notification_window setIgnoresMouseEvents:YES];
	[notification_window setLevel:NSScreenSaverWindowLevel];
	[notification_window setDelegate:self]; 
	
	// Configure contentView for checkin window
	NSView *contentView = [notification_window contentView];
	[contentView setWantsLayer:YES];
	CALayer *layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[notification_window makeFirstResponder:contentView];
	NSRect tfRect = NSMakeRect(width - 220, height - 220, 200, 100.f);
	notifyTextField = [[NSTextField alloc] initWithFrame:tfRect];
	[notifyTextField setEditable:NO];
	[notifyTextField setStringValue:@"Checking in"];
	[notifyTextField setBackgroundColor:[NSColor blackColor]];
	[notifyTextField setTextColor:[NSColor whiteColor]];
	[notifyTextField setFont:[NSFont fontWithName:@"Helvetica" size:20]];
	[notifyTextField setBordered:false];
	[contentView addSubview:notifyTextField];
	[notifyTextField release];
	*/
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
	// Configure contentView for graph window
	contentView = [graph_window contentView];
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[graph_window makeFirstResponder:contentView];
	
	
	// Configure contentView for notification window
	contentView = [notify_window contentView];
	[contentView setWantsLayer:YES];
	layer = [contentView layer];
	layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	layer.opacity = 0.0;
	[window makeFirstResponder:contentView];
	
		
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
	[profile_window retain];
	if (social) 
	[NSThread detachNewThreadSelector:@selector(loadUserProfile:) toTarget:self withObject:nil];
	//run dat looooop
	[NSThread detachNewThreadSelector:@selector(mainloop:) toTarget:self withObject:nil];
}
/* 
	Load user profile from user.plist in the DATA_DIR. If not,launch a window to 
	allow user to create profile.
 */
- (void) loadUserProfile :(NSConnection *) connection
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
	user = [self ReadUserFromPropertyDictionary];
	if (!user)
	{
		[userNameTF setEditable:YES];
		[imageurlTF setEditable:YES];
		[profile_window makeKeyAndOrderFront:self];
		[profile_window setOrderedIndex:0];
	}
	else {
		BOOL ok =[ppDatabaseManager updateTimestamp:user.userName];
		if (!ok) { 
			[ppDatabaseManager addUserWithName:user.userName
								withInitialBPM:0.0
								  withImageURL:user.image
								  withRestRate:15.0 
									withPoints:0];
		}
	}
	[pool release];
	
}
-(void) setUserProfile :(id) sender;
{
	baseline_bpm = 15.0;  //default setting
	user = [[User alloc] init];
	user.userName = [userNameTF stringValue];
	user.image = [imageurlTF stringValue];
	[profile_window close];
	NSDictionary *dict;
	NSString *profileFile = [NSString stringWithFormat:@"%@config/user.plist",data_dir];
	dict = [NSDictionary dictionaryWithObjectsAndKeys:user.userName,@"userName",user.image,@"image",[NSNumber numberWithFloat:baseline_bpm],@"baseline",nil]; 
	[recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
	[dict writeToFile:profileFile atomically:true];
	[ppDatabaseManager addUserWithName:user.userName
						withInitialBPM:0
						  withImageURL:user.image
						  withRestRate:baseline_bpm 
							withPoints:0];

	return;  
	
} 
-(void) updateUserProfileWithBaseline
{
	NSMutableDictionary *profile;
	NSString *profileName = [NSString stringWithFormat:@"%@config/user.plist",data_dir];
	profile  = [NSMutableDictionary dictionaryWithContentsOfFile:profileName];
	[profile setValue:[NSNumber numberWithFloat:baseline_bpm] forKey:@"baseline"];
	
	[profile writeToFile:profileName atomically:true];
}
-(User *) ReadUserFromPropertyDictionary
{
	NSDictionary *profile;
	NSString *profileName = [NSString stringWithFormat:@"%@config/user.plist",data_dir];
	profile  = [NSDictionary dictionaryWithContentsOfFile:profileName];
	if (profile)
	{
		user = [[User alloc]init];
		user.userName = [profile objectForKey:@"userName"];
		user.image = [profile objectForKey:@"image"];
		baseline_bpm = [[profile objectForKey:@"baseline"] floatValue]; // use previously recorded baseline for subsequent sessions
		[recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];

	}
	else {
		user = nil;
	}
	return user;
	
	}
-(void) ReadAppSettingsFromPropertyFile 
{
	NSDictionary *settings;
	NSString *fileName = [NSString stringWithFormat:@"%@config/appSettings.plist",data_dir];
	settings  = [NSDictionary dictionaryWithContentsOfFile:fileName];
	if (settings)
	{
		arduino = [[settings objectForKey:@"arduino"] boolValue];
		social = [[settings objectForKey:@"social"] boolValue];
	}
	else {
		arduino = YES;
		social = NO;
	}	
	NSLog(@"read arduino = %d social=%d",arduino,social);

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

/*
	Log user interactions to uilog.txt. toLog is YES when interactions are relevant 
	to user such as checkin/system notifications on breath performance etc
 */
-(void) uilog:(NSString *) message :(BOOL )toLog 

{
	uilogfp = fopen([[data_dir stringByAppendingString:@"logs/UIlog.txt"] UTF8String],"a");
	if (uilogfp) { 
		float userbpm = [brStatController user_baseline_bpm];
		fprintf(uilogfp,"%s, %.1f,%.1f,\"%s\"\n",[[dateFormatter stringFromDate:now] UTF8String],breathrate,(userbpm > 0) ?userbpm:baseline_bpm,[message UTF8String]);
		fclose(uilogfp);
	}
	if (!toLog && social)
		[ppDatabaseManager addMessagesForUser:user.userName messages:message];
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
	[statusItem setTitle:@"<Breathe>"];
	[statusItem setHighlightMode:YES];
	[statusItem setAction:@selector(ShowUsers:)];
	start_stop = [statusMenu addItemWithTitle:@"Starting up..." action:@selector(toggle_on_off:) keyEquivalent:@""];
	[start_stop setEnabled:NO];
	checkinItem =[statusMenu addItemWithTitle:@"Check-in" action:@selector(checkIn:) keyEquivalent:@""];
	//	SendModeItem = [statusMenu addItemWithTitle:@"Turn Realtime Off" action:@selector(toggle_send:) keyEquivalent:@""];
	recordBaseline = [statusMenu addItemWithTitle:@"Record Baseline" action:@selector(record_baseline:) keyEquivalent:@""];
	baselineItem = [statusMenu addItemWithTitle:@"Set New Baseline" action:@selector(showBaselineWindow:) keyEquivalent:@""];

	//increaseBaselineItem = [statusMenu addItemWithTitle:@"Increase Baseline" action:@selector(increaseBaseline:) keyEquivalent:@""];
	//decreaseBaselineItem = [statusMenu addItemWithTitle:@"Decrease Baseline" action:@selector(decreaseBaseline:) keyEquivalent:@""];
	graphItem = [statusMenu addItemWithTitle:@"Today's Highs and Lows" action:@selector(viewPerformance:) keyEquivalent:@""];
	[graphItem setEnabled:NO];
	//displayOff = [statusMenu addItemWithTitle:@"Feedback Off" action:@selector(set_display_off:) keyEquivalent:@""];
	//displayScreen = [statusMenu addItemWithTitle:@"Screen Dim Feedback" action:@selector(set_display_screen:) keyEquivalent:@""];
	//displayMenu = [statusMenu addItemWithTitle:@"Menu Dim Feedback" action:@selector(set_display_menu:) keyEquivalent:@""];
	//displayBounce = [statusMenu addItemWithTitle:@"Bounce Feedback" action:@selector(set_display_bounce:) keyEquivalent:@""];
	calibrateToggle = [statusMenu addItemWithTitle:@"Turn Calibration On" action:@selector(calibrate_on_off:) keyEquivalent:@""];
	intervalItem = [statusMenu addItemWithTitle:@"Change Update Interval..." action:@selector(set_interval_menu:) keyEquivalent:@""];
	colorToggle = [statusMenu addItemWithTitle:@"Change Color based on Rate On" action:@selector(color_on_off:) keyEquivalent:@""];
	pprToggleItem = [statusMenu addItemWithTitle:@"Turn PPR bar On" action:@selector(ppr_on_off:) keyEquivalent:@""];
	[checkinItem setEnabled:NO];
	[pprToggleItem setEnabled:NO];
	[statusMenu addItemWithTitle:@"My breath.fm" action:@selector(viewHistory:) keyEquivalent:@""];
	[statusMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	[updt_button setKeyEquivalent:@"\r"];
  	brStatController = [[BreathStatController alloc] init];
	[self fileNotifications];
	userCount = 0;  //maintain list of users added to the menu bar

}

- (void) viewPerformance:(id) sender
{
	NSArray *imArray = [brStatController getImages:High ];
	NSArray *labelArray = [brStatController LabelsForStatType:High];
	[self setLabelView:highLabel1:labelArray:0];
	[self setLabelView:highLabel2:labelArray:1];
	[self setLabelView:highLabel3:labelArray:2];
	labelArray = [brStatController LabelsForStatType:Low ];
	[self setLabelView:lowLabel1:labelArray:0];
	[self setLabelView:lowLabel2:labelArray:1];
	[self setLabelView:lowLabel3:labelArray:2];

	[self setImageView:highView1:imArray:0];
	[self setImageView:highView2:imArray:1];
	[self setImageView:highView3:imArray:2]; 
	imArray = [brStatController getImages:Low];
	[self setImageView:lowView1:imArray:0];
	[self setImageView:lowView2:imArray:1];
	[self setImageView:lowView3:imArray:2]; 
	[perf_window makeKeyAndOrderFront:self];
	
	[perf_window display];
	[self uilog :[NSString stringWithFormat:@"View Breath Performance"]:YES];
	timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(captureScreen:) userInfo:nil repeats:NO];

}
-(void) captureScreen:(id) sender
{
	NSString *filePath = [NSString stringWithFormat:@"%@snapshots/snapshot%d.jpg",data_dir,snapId ];
	[ScreenCapture grabScreenShot:filePath];
	snapId++;
}

/* Record new user baseline for 30 secs when checkin button is pressed */
-(void) checkIn:(id)sender { 
/*	this is previous logic where progress animation was used to display checkin
	indicator = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)] autorelease];
	[indicator setStyle:NSProgressIndicatorSpinningStyle];
	[indicator setIndeterminate:YES];
	[indicator setUsesThreadedAnimation:YES];
	[statusItem setView:indicator];
 */
	[brStatController record_checkin_baseline:YES];
	[statusItem setTitle:@"<checking in>"];
	[checkinItem setEnabled:NO];
	timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(showCheckInProgress:) userInfo:nil repeats:NO];
	//[indicator startAnimation:self];
	

}
-(void) showCheckInProgress:(id) sender { 
	[brStatController record_checkin_baseline:NO];
	[timer invalidate];
	[checkinItem setEnabled:YES];
	//[indicator stopAnimation:sender];
	//[statusItem setView:nil];
	[statusItem setTitle:@"<Breathe>"];
	[recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",[brStatController checkin_bpm]]];

	[self uilog :[NSString stringWithFormat:@"User checked in, user baseline bpm = %.1f",[brStatController checkin_bpm]]:NO];
	if (social)
	[ppDatabaseManager changeUserRestRate:user.userName 
							   toRestRate:[brStatController checkin_bpm]]; 
	NSString *message = [NSString stringWithFormat:@"You checked in at %.1f bpm",[brStatController checkin_bpm]];
	[nTextField setStringValue:message];
	[self uilog:[NSString stringWithFormat:@"Notified user with message: %@" ,message] :NO ];
	[self fadeOutWindow:notification_window];
	

}

- (void) viewHistory:(id) sender 
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.stanford.edu/~jimzheng/cgi-bin/Breathcast"]];
}
/* Tack on list of users who used the app in the last 24 hrs when the menu is clicked
 */
-(void)menuWillOpen:(NSMenu *)menu
{
	if (!social) 
		return;
	NSArray *allUsers = [[ppDatabaseManager getAllUsers] retain];
	userCount = 0;
	int index = [statusMenu numberOfItems];
/*	for (NSString *username in allUsers) 
	{
		if ([username isEqualToString:user.userName])
			continue;
		NSDate *lastUpdate = [[ppDatabaseManager getLastUpdate:username] retain];
		double timediff = [[NSDate date] timeIntervalSinceDate:lastUpdate];
		if (timediff > 86400) //ignore history more than a day old
			continue;
		ppUser *pUser = [[ppDatabaseManager getUserInfo:username] retain];
		NSString *userStr = [NSString stringWithFormat:@"%@ (%d pts) %.1fbpm",username,pUser.points,pUser.bpm];
		[statusMenu insertItemWithTitle:userStr action:nil keyEquivalent:@"" atIndex:index++];
		userCount++;

	}
 */
	for (ppUser *ppuser in allUsers)
	{
		if ([ppuser.name isEqualToString:user.userName])
			continue;
		NSDate *lastUpdate = ppuser.lastUpdated;
		double timediff = [[NSDate date] timeIntervalSinceDate:lastUpdate];
		//if (timediff > 86400) //ignore history more than a day old
		//	continue;
		NSString *userStr = [NSString stringWithFormat:@"%@ (%d pts) %.1fbpm",ppuser.name,ppuser.points,ppuser.bpm];
	[statusMenu insertItemWithTitle:userStr action:nil keyEquivalent:@"" atIndex:index++];
	userCount++;
						
	}
}

-(void)menuDidClose:(NSMenu *)menu
{
	int menucount = [statusMenu numberOfItems];
	int num = 1;
	while (num <= userCount) {
		[statusMenu removeItemAtIndex:menucount - num];
		num++;
	}
	userCount = 0;
}

-(void) setLabelView:(NSTextField *) forLabel :(NSArray *) fromArray :(int)aindex {
	if ([fromArray count] > aindex) {
		NSString *s = [fromArray objectAtIndex:aindex];
		[forLabel setStringValue:s];
	}

}
-(void) setImageView:(NSImageView *) forImageView :(NSArray *) fromArray :(int)aindex 
{
	NSImage *newImage;
	if ([fromArray count] > aindex) { 
		newImage = [fromArray objectAtIndex:aindex];
		[forImageView setImage:newImage];
		[forImageView setImageScaling:NSScaleToFit];
	}
}
- (void) record_baseline:(id)sender
{
	[self uilog :[NSString stringWithFormat:@"Recording baseline =%s",(recording_baseline == true) ? "true" : "false"] :YES];
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
		[brStatController setDefaultBaseline:baseline_bpm];

		[recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
		if (social)
		[ppDatabaseManager changeUserRestRate:user.userName 
								   toRestRate:baseline_bpm];
		[self updateUserProfileWithBaseline];
		return;
	}
}
-(void) showBaselineWindow: (id) sender 
{
	[setBaseline_window makeKeyAndOrderFront:self];
	[setBaseline_window setOrderedIndex:0];
	[setBaseline_window display];

	
	
}
- (void) setBaseline:(id) sender 
{
	int index = [baselinePopup indexOfSelectedItem];
	
	baseline_bpm = baseline_bpm + (index - 5);
	printf("%f\n",baseline_bpm);
    [recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
	[self uilog :[NSString stringWithFormat:@"%@ Baseline to %d",(index - 5) < 0 ? @"Decrease":@"Increase",baseline_bpm] :YES];
	[setBaseline_window orderOut:nil];
	[brStatController setDefaultBaseline:baseline_bpm];
	if (social)
		[ppDatabaseManager changeUserRestRate:user.userName 
								   toRestRate:baseline_bpm];
	[self updateUserProfileWithBaseline];

}
- (void) increaseBaseline:(id)sender
{
	baseline_bpm = baseline_bpm+1;
	printf("%f\n",baseline_bpm);
    [recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
	[self uilog :[NSString stringWithFormat:@"Increase Baseline to %d",baseline_bpm] :YES];

}

- (void) decreaseBaseline:(id)sender
{
	baseline_bpm = baseline_bpm-1;
	printf("%f\n",baseline_bpm);
    [recordBaseline setTitle:[NSString stringWithFormat:@"Record Baseline (=%f)",baseline_bpm]];
	[self uilog :[NSString stringWithFormat:@"Decrease Baseline to %d",baseline_bpm] :YES];

}

- (void) toggle_send:(id)sender
{
    realtime=!realtime;
	[self uilog :[NSString stringWithFormat:@"Turn Realtime %s",(realtime)?"On":"Off"] :YES];

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
	[self uilog :[NSString stringWithFormat:@"Turn Calibration %s",(calibrateMode)?"On":"Off"] :YES];

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
- (void) ppr_on_off: (id) sender
{
	if (pprMode) {
		[pprToggleItem setTitle:@"Turn PPR bar On"];
		[window orderOut:nil];
	}
	else {
		[pprToggleItem setTitle:@"Turn PPR bar Off"];
		[window makeKeyAndOrderFront:self];
	}
	
	pprMode = !pprMode;

}
/* 
	Show set interval window when menu option is clicked
 */
- (void) set_interval_menu:(id) sender 
{
	[interval_window makeKeyAndOrderFront:self];
	[interval_window setOrderedIndex:0];
	[interval_window display];
}
/* Just for debugging app 
 
- (BOOL) respondsToSelector:(SEL) aSelector
{
	NSString *methodName = NSStringFromSelector(aSelector);
	NSLog(@"responds to selector %@",methodName);
	return [super respondsToSelector:(SEL)aSelector];	
}
 */

- (void) set_interval:(id) sender 
{
	
	BOOL editingEnded = [interval_window makeFirstResponder:interval_window];
	
	if(!editingEnded) {
		NSLog(@"unable to end editing");
		return;
	}
	
	display_interval = [intervalTextField floatValue];
	if ((display_interval < 0) || (display_interval > 3600))
		display_interval = 10;  //default interval 10 seconds.
	[interval_window orderOut:nil];
	[intervalItem setTitle:[NSString stringWithFormat:@"Change Update Interval(=%.1f)...",display_interval]];

}
- (BOOL)control: (NSControl*)control didFailToFormatString:
(NSString*)str errorDescription: (NSString*)errDescription
{
	NSError *error = [NSError errorWithDomain: NSCocoaErrorDomain
										 code: NSFormattingError userInfo: nil]; // Add custom description later
    [control presentError: error modalForWindow: [self window]
				 delegate: nil
	   didPresentSelector: nil
              contextInfo: nil];
	
    return YES;
}
/* toggle color display on the system tray */
- (void) color_on_off:(id) sender
{
	[self uilog :[NSString stringWithFormat:@"Change Color based on Rate %s",colorMode ? "On" : "Off"] :YES];

	if (colorMode) {  
		[colorToggle setTitle:@"Change Color based on Rate On"];
		colorMode = false;
	}
	else { 
		[colorToggle setTitle:@"Change Color based on Rate Off"];
		colorMode = true;
	}
	[self set_breath_rate_view : breathrate :baseline_bpm];	
}
- (void) toggle_on_off:(id)sender
{
	//int randomint = rand()%NUM_USERS;
	//userSyncingFromIcon = usersIcons[randomint];
	//userSyncingFrom = users[randomint];
	running = !running;
	[self uilog :[NSString stringWithFormat:@"Start/Pause = %s",running ? "Start" : "Pause"] :YES];

	if (running) {
		[self pickRandomUserTo];
		[self pickRandomUserFrom];
		[start_stop setTitle:@"Pause"];
		displaymode = 3;
		[self set_brightness_menu:1.0];
		[graphItem setEnabled:YES];
		[checkinItem setEnabled:YES];
		[pprToggleItem setEnabled:YES];
	}
	if (running==false)
	{
		[start_stop setTitle:@"Start"];
		displaymode = 0;
		//[statusItem setTitle:@"Last Score:N/A"];
		//[self set_brightness_screen:1.0];
		[self set_brightness_menu:1.0];
		[graphItem setEnabled:NO];
		[checkinItem setEnabled:NO];
		[pprToggleItem setEnabled:NO];
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
	[self uilog:@"Quit application" :YES];
	exit(1);
}



- (void) set_brightness:(float)new_brightness progress:(float)prog{
	
	if (!pprMode) { 
		[window orderOut:nil];
		return;
	}
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
}
//@poorna - june22,2011
- (void)set_breath_rate_view:(float) br_rate :(float) base_rate
{
	float user_bpm = [brStatController user_baseline_bpm];
	float override_bpm = (user_bpm > 0) ? user_bpm : base_rate;
	float percentChange = (br_rate) * 100/override_bpm;

	NSString *trend = [NSString stringWithFormat:@"%dpts (%.1fbpm,%.1f%%)",[brStatController calm_points],br_rate,percentChange];
	NSMutableAttributedString *statusDisplay = [[NSMutableAttributedString alloc] init];
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
	[statusDisplay release];
	[trendAttr release];

}
/* Show calm image when user has earned sufficient points */
- (void) LoadImage:(NSImage *) image 
{
	[calmImageView setImage:image];
	[calmImageView setImageScaling:NSScaleToFit];
	[calm_window setTitle:[image name]];

	[calm_window makeKeyAndOrderFront:self];
	[calm_window setOrderedIndex:0];
	[calm_window display];
	
}

- (void) mainloop:(NSConnection *)connection
{
	//I don't know what this does, but it seems to help avoid error messages
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//provide quality random numbers for this thread
	srand(time(NULL));
	
	printf("%s\n",[[data_dir stringByAppendingString:@"serialport.txt"] UTF8String]);
	char serialportName[128];
	int percentAboveBaseline;
	int percentBelowBaseline;
	NSString *serial_name = [[NSString alloc] initWithContentsOfFile:[data_dir stringByAppendingString:@"/serialport.txt"]];
	sscanf([serial_name UTF8String],"%s %d %d",&serialportName,&percentAboveBaseline,&percentBelowBaseline);
	printf("%s, %d, %d\n",serialportName,percentAboveBaseline,percentBelowBaseline);
	[serial_name release];
	int fd;
	//wireless *serialUSB;
	NSLog(@"main arduino = %d social=%d",arduino,social);
	[self uilog:[NSString stringWithFormat:@"Using arduino=%@, social=%@",arduino?@"YES":@"NO",social?@"YES":@"NO"]:YES];
	if (arduino)
		fd = autoDetect_Arduino_port(9600);
	else { 
		//serialUSB = [[wireless alloc] init];
		//fd = [serialUSB autoDetect_Arduino_port :9600];
		fd = autoDetect_wireless_port(9600);

	}
	
	//int fd = serialport_init([serial_name UTF8String], 9600);
	
	
	//char buf[256];
	
	int val;
	// Get a current time for where you want to start measuring from
	NSDate *date = [NSDate date];
	dateFormatter = [[[NSDateFormatter alloc] init] autorelease]; // = [[NSDateFormatter alloc] initWithDateFormat:@"%y-%m-%d %H:%M:%S:%F" allowNaturalLanguage:YES];
	[dateFormatter setDateFormat:@"yyyy-MM-dd,HH:mm:ss:SSS"];
	// Find elapsed time
	// Use (-) modifier to conversion since receiver is earlier than now
	NSTimeInterval timePassed_s =  [date timeIntervalSinceNow] * -1.0;
		
	BreathRate *br = [[BreathRate alloc] initWithTime:timePassed_s];
	[brStatController setDefaultBaseline:baseline_bpm];
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
	float last_display = 0.0, last_upload = 0.0;
	vis_duration = 60.0;
	int samplecount = 0;
	BOOL logged  = NO, warm_up = YES;
	int points = 0;
	int uploadCount = 0;
	while(true)
	{
		timePassed_s = [date timeIntervalSinceNow] * -1.0;
		float time_delta = timePassed_s - last_timePassed_s;
		now  = [[NSDate dateWithTimeInterval:timePassed_s sinceDate:date] autorelease];
		
		char header[240];
		int rc;
		//used for testing only
		//[NSThread sleepForTimeInterval:0.1];
		if (arduino)
			rc = getNextVal(fd, &val, header);
		else
			//rc = [serialUSB getNextVal:&val];
			rc = getNextWVal(fd, &val, header);

	//	int rc = serialport_read_until(fd, buf, '\n',&numRead);
		
		//if arduino not detected,retry every 30 secs
		if (rc == -1) { 
			if (!logged) { 
				[self uilog:@"No wireless connection" :YES];
				[statusItem setTitle:@"<Breathe>"];
				[window orderOut:nil];
				logged = YES;
			}
			[NSThread sleepForTimeInterval:10];
			if (arduino) 
				fd = autoDetect_Arduino_port(9600);
			else {
			//	[serialUSB release];
		//		serialUSB = [[wireless alloc] init];
		//		fd = [serialUSB autoDetect_Arduino_port:9600];
				fd = autoDetect_wireless_port(9600);
			}
			last_timePassed_s = timePassed_s;
			continue;
		}
		//sscanf(buf,"%d\n",&val);
		//code to detect if user left computer 
		if ((rc == -2) || (rc == -3)) {
			if (!logged) { 
				if (rc == -2)
					[self uilog:@"User left computer" :YES];
				else 
					[self uilog:@"Wireless belt switched off":YES];
				logged = YES;
				[statusItem setTitle:@"<Breathe>"];
				[window orderOut:nil];

			}
			last_timePassed_s = timePassed_s;
			continue;
			
		}
		if (logged) {
			[self uilog:@"Application resumed" :YES];
			logged = NO;
		}
		
		if ( !([br isWarmUp]) && (warm_up) &&
			((social && user) || (!social && !user))) //wait until user profile set up
		{	//and warm up finish to start app
		
			warm_up = NO;
			[self toggle_on_off:self];
			[start_stop setEnabled:YES];
		}
		//uncomment these lines (and "int baseline=0") to get the brightness to change directly with the sensor
		//if (baseline<400 || baseline>1000)
		//	baseline = val;
		//[self set_brightness:max(0,0.4+(val-baseline)/500.0)];
		samplecount = samplecount++%NUM_SAMPLES;

		[br add_sample:val :timePassed_s];
		
		breathrate = [br getBreathRate];
		if (recording_baseline)
		{
			baseline_total += breathrate;
			baseline_iterations++;
		}
		printf("time: %f, read: %d, breath rate: %f, calm_points: %d\n", timePassed_s,val,breathrate,[brStatController calm_points]);
		if (calibrateMode)
		{
			NSRect theFrame = [window frame];
			NSPoint theOrigin = theFrame.origin;
//			theOrigin.y = 2*(val-400);
			theOrigin.y = 200 + val/2;
			[cal_window setFrameOrigin:theOrigin];
		}
		
		
		
		//Log data here
		FILE* fp;
		fp = fopen([[data_dir stringByAppendingString:@"logs/log.txt"] UTF8String],"a");
		//fprintf(fp,"%s, %.2f %d %.2f %.2f %.2f %.2f %.2f %d %d %d %d\n",[[dateFormatter stringFromDate:now] UTF8String] ,timePassed_s,val,breathrate,baseline_bpm,[br getInhaleExhaleRatio], [br getInhaleRestPerMinute],[br getExhaleRestPerMinute],recording_baseline,running,realtime,cycle);
		fprintf(fp,"%.2f, %d, %.2f, %.2f, %d, %d, %d, %d, %s, %d\n",timePassed_s,val,breathrate,baseline_bpm,recording_baseline,running,realtime,cycle,[[dateFormatter stringFromDate:now] UTF8String],[brStatController calm_points] );

		fclose(fp);
		

		if (running)
		{
			[brStatController updateBreathStats:breathrate:time_delta:[dateFormatter stringFromDate:now]];
			if (social) {
				if ((last_upload += time_delta) > upload_interval) { //log breathrate every 2 secs				
					fp = fopen([[data_dir stringByAppendingString:@"upload.txt"] UTF8String],"a");
					//fprintf(fp,"%.2f %d %.2f %.2f %d %d %d %d %s %d\n",timePassed_s,val,breathrate,baseline_bpm,recording_baseline,running,realtime,cycle,[[dateFormatter stringFromDate:now] UTF8String],[brStatController calm_points] );
					fprintf(fp,"%.2f\n",breathrate);

					fclose(fp);
					uploadCount++;
					last_upload = 0.0;
				}
				if (uploadCount == 100) { //launch separate app to upload bpms
					[self launchUpload];
					uploadCount = 0;
				}
			}
			if (points != [brStatController calm_points]) { 
				points = [brStatController calm_points];
				if (social)
					[ppDatabaseManager updatePointsForUser:user.userName to:points];
			}
			if ((last_display += time_delta) > display_interval) { //update system tray
				if (![brStatController isCheckInMode]) 
					[self set_breath_rate_view: breathrate :baseline_bpm];
				last_display = 0;
			}
			Notification *notifier = [brStatController notifyMoment];
			
			NSString *message = notifier.message;
			if (message != nil)
			{
				[nTextField setStringValue:message];
				[self uilog:[NSString stringWithFormat:@"Notified user with message: %@" ,message] :NO ];
				[self fadeOutWindow:notification_window];
				if (notifier.sound) 
					[notifier.sound play];
				[notifier release];
			}
			NSImage *calmImage = nil;
			if ((calmImage = [brStatController getCalmImage]))
			{
				[self LoadImage:calmImage];
				[self uilog:[NSString stringWithFormat:@"Popped up calm image :%@",[calmImage name]] :NO];
				[calmImage autorelease];
			}
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
					[window makeKeyAndOrderFront:self];

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
				[window makeKeyAndOrderFront:self];

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
			if (cycle && pprMode)  //poorna - to turn ppr bar off optionally
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
					[window orderOut:nil];
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
/* Display a fading notification window that closes after 5 secs
 */
- (void)fadeOutWindow:(NSWindow*)mywindow{
	float alpha = 1.0;
	[mywindow setAlphaValue:alpha];
	[mywindow makeKeyAndOrderFront:self];
	[mywindow setOrderedIndex:0];
	for (int x = 0; x < 3; x++) {
		alpha -= 0.1;
		[mywindow setAlphaValue:alpha];
		[NSThread sleepForTimeInterval:2.00];
	}
	[mywindow orderOut:nil];
}

- (void) receiveSleepNote: (NSNotification*) note
{
    [self uilog:@"Computer about to sleep" :YES];
}

- (void) receiveWakeNote: (NSNotification*) note
{
    [self uilog:@"Computer woke up from sleep" :YES];
}

- (void) fileNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default 
    // notification center. You will not receive sleep/wake notifications if you file 
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
														   selector: @selector(receiveSleepNote:) 
															   name: NSWorkspaceWillSleepNotification object: NULL];
	
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
														   selector: @selector(receiveWakeNote:) 
															   name: NSWorkspaceDidWakeNotification object: NULL];
} 
/* not used .. just in case something along this line needs to be written again
 */
- (void) updateStartDisplay : (BreathRate *) br{ 
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	while ([br isWarmUp]) { 
		[start_stop setTitle:[NSString stringWithFormat:@"Starting up...(%d sec)",WARMUP_SEC - warmupTime]];
		warmupTime++;
		[NSThread sleepForTimeInterval:1];
	}
	[start_stop setTitle:@"Start"];
	[start_stop setEnabled:YES];
	[pool release];
}
/* Launches BreatheUploader which will use the update.txt to upload data to server */
- (void) launchUpload { 
	
	NSTask *task = [[NSTask alloc] init];
	NSArray *args = [NSArray arrayWithObjects:user.userName,nil];
	[task setLaunchPath:[NSString stringWithFormat:@"%@/BreatheUploader.app/Contents/MacOS/BreatheUploader",data_dir]];
	[task setArguments:args];
	[task launch];
	[task release];
}
@end


