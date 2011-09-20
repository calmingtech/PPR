//
//  peripheralpacingAppDelegate.h
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "BreathRate.h"
#import "BreathStatController.h"
#import "User.h"
#import "SBJson.h"
#import "ppUser.h"
#import "ppDatabaseManager.h"


#define NUM_USERS 6
#define WARMUP_SEC 33

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface peripheralpacingAppDelegate : NSObject
#else
@interface peripheralpacingAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate> 
#endif
{
	IBOutlet NSMenu *statusMenu;

	NSWindow *interval_window, *notification_window, *perf_window, *setBaseline_window;
	NSWindow *window , *profile_window;
	NSWindow *cal_window;
	NSWindow *notify_window;
	NSWindow *graph_window;
	IBOutlet NSStatusItem * statusItem;
	NSMenuItem * start_stop;
	NSMenuItem * recordBaseline;
	NSMenuItem * displayOff;
	NSMenuItem * displayScreen;
	NSMenuItem * displayMenu;
	NSMenuItem * displayBounce;
	NSMenuItem * calibrateToggle;
	NSMenuItem * colorToggle;
	NSMenuItem * intervalItem;
	
	NSMenuItem * decreaseBaselineItem;
	NSMenuItem * increaseBaselineItem , *baselineItem;
	
	NSMenuItem * SendModeItem;
	NSMenuItem * graphItem, *checkinItem, *pprToggleItem;
	NSPopUpButton *baselinePopup;
	NSTextField *userNameTF, *imageurlTF;
	NSButton *profile_button;
	
	int displaymode;
	bool running;
	float baseline_bpm;
	float breathrate;
	bool recording_baseline;
	float baseline_total;
	int baseline_iterations;
	bool calibrateMode;
	bool colorMode;
	bool cycle;
	bool calm_moment_rb;
	bool calm_moment;
    bool realtime;
	float vis_duration;
	float display_interval, upload_interval;
	bool windowIsKey;
	bool arduino, social;
	NSString *graphics_dir;
	NSString *data_dir;
	
	NSImage *blankImage;

	NSImageView *notify_imview;
	NSTextField *notifyTextField;
	NSTextField *intervalTextField, *nTextField;
	NSTimer *timer;
	
	NSImageView *bar_imview1;
	NSImageView *bar_imview2;
	NSImageView *bar_imview3;
	NSImageView *bar_imview4;
	NSImageView *bar_imview5;
	NSMutableArray *highImgArray;
	NSButton *updt_button;
	//the (fake) user whose calmness is being sent to the test subject
	NSString *userSyncingFrom;
	NSImage *userSyncingFromIcon;
	BreathStatController *brStatController;
	//the (fake) user who is being sent calmness from the test subject
	NSString *userSyncingTo;
	NSImage *userSyncingToIcon;
	
	float notification_time;
	int userCount;
	int snapId;
	//all the image/name data for (fake) users
	NSString *users[NUM_USERS];
	NSImage *usersIcons[NUM_USERS];
    NSImageView *highView1, *highView2, *highView3,*lowView1, *lowView2, *lowView3;
	NSTextField *highLabel1, *highLabel2, *highLabel3, *lowLabel1, *lowLabel2, *lowLabel3;
	//User name+icon
	NSString *myName;
	NSImage *myImage;
	FILE    *uilogfp;
	NSProgressIndicator *indicator;
	NSDateFormatter *dateFormatter;
	NSDate *now;
	NSImageView *calmImageView;
	NSWindow *calm_window;
	bool pprMode;
	int warmupTime;
	User *user;
	
}

- (void) setupAvatars;

- (void) notify:(NSString*)message duration:(float) time icon:(NSImage*)avatar;
- (void) showNotification:(NSString*)message;

- (void) changeNotificationIcon:(NSImage*) avatar;
 
- (void) waitAndNotifyOfRB;
- (void) pickRandomUserFrom;
- (void) pickRandomUserTo;

- (void) set_brightness:(float) new_brightness progress:(float)prog;
- (void) set_brightness_screen:(float) new_brightness;
- (void) set_brightness_menu:(float) new_brightness;
- (void) set_bounce_position:(float)relativePos;
- (void) set_breath_rate_view:(float)br_rate :(float) base_rate;
- (void) set_interval:(id)sender;
- (void) set_interval_menu:(id) sender;
- (void) record_baseline:(id)sender;

- (void) decreaseBaseline:(id)sender;
- (void) increaseBaseline:(id)sender;

- (void) toggle_send:(id)sender;

- (void) toggle_on_off:(id)sender;
- (void) calibrate_on_off:(id)sender;
- (void) color_on_off:(id)sender;
- (void) ppr_on_off :(id) sender;
- (void) set_interval:(id) sender;
- (void) set_display_off:(id)sender;
- (void) set_display_screen:(id)sender;
- (void) set_display_menu:(id)sender;
- (void) set_display_bounce:(id)sender;
- (void) terminate:(id)sender;
- (void) viewPerformance:(id)sender;
- (void) checkIn:(id) sender;
- (void) showCheckInProgress:(id) sender; 
- (void) viewHistory:(id) sender;
-(void)menuWillOpen:(NSMenu *)menu;
-(void)menuDidClose:(NSMenu *)menu;
-(void) captureScreen:(id) sender;

- (void) uilog:(NSString *)message :(BOOL )toLog;
- (void) setImageView:(NSImageView *) forImageView :(NSArray *)fromArray :(int)aindex;
-(void) setLabelView:(NSTextField *) forLabel :(NSArray *) fromArray :(int)aindex;
- (void) mainloop:(NSConnection *)connection;
-(void) LoadImage:(NSImage *)image;
- (void) fileNotifications;
- (void) receiveSleepNote: (NSNotification*) note;
- (void) receiveWakeNote: (NSNotification*) note;
- (void) updateStartDisplay : (BreathRate *)br;
-(void) setBaseline: (id) sender ;
- (void) setUserProfile :(id) sender;
- (void) loadUserProfile:(NSConnection *)connection;
- (void) WriteUserToPropertyDictionary;
-(User *) ReadUserFromPropertyDictionary;
-(void) ReadAppSettingsFromPropertyFile;

-(void) showBaselineWindow: (id) sender; 
- (void) launchUpload;
@property (assign) IBOutlet NSWindow *window,*profile_window;
@property (assign) IBOutlet NSWindow *interval_window;
@property (assign) IBOutlet NSWindow *notification_window;
@property (assign) IBOutlet NSTextField *notifyTextField;

@property (assign) IBOutlet NSWindow *perf_window;
@property (assign) IBOutlet NSTextField *intervalTextField,*nTextField;

@property (assign) IBOutlet NSImageView *highView1, *highView2, *highView3;
@property (assign) IBOutlet NSImageView *lowView1, *lowView2, *lowView3;
@property (assign) IBOutlet NSTextField *highLabel1, *highLabel2, *highLabel3;
@property (assign) IBOutlet NSTextField *lowLabel1,*lowLabel2, *lowLabel3;
@property (retain) IBOutlet NSTextField *userNameTF,*imageurlTF;

@property (assign) IBOutlet NSButton  *updt_button,*profile_button;
@property (assign) IBOutlet NSWindow *calm_window, *setBaseline_window;
@property (assign) IBOutlet NSImageView *calmImageView;
@property (assign) IBOutlet NSPopUpButton *baselinePopup;
@end
