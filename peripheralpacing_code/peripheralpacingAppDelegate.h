//
//  peripheralpacingAppDelegate.h
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define NUM_USERS 6

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface peripheralpacingAppDelegate : NSObject
#else
@interface peripheralpacingAppDelegate : NSObject <NSApplicationDelegate>
#endif
{
	IBOutlet NSMenu *statusMenu;
	NSWindow *interval_window;
	NSWindow *window;
	NSWindow *cal_window;
	NSWindow *notify_window;
	NSWindow *graph_window;
	NSStatusItem * statusItem;
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
	NSMenuItem * increaseBaselineItem;
	
	NSMenuItem * SendModeItem;
	NSMenuItem * graphItem;
	
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
	float display_interval;
	
	NSString *graphics_dir;
	NSString *data_dir;
	
	NSImage *blankImage;

	NSImageView *notify_imview;
	NSTextField *notifyTextField;
	NSTextField *intervalTextField;
	
	NSImageView *bar_imview1;
	NSImageView *bar_imview2;
	NSImageView *bar_imview3;
	NSImageView *bar_imview4;
	NSImageView *bar_imview5;
	
	NSButton *updt_button;
	//the (fake) user whose calmness is being sent to the test subject
	NSString *userSyncingFrom;
	NSImage *userSyncingFromIcon;
	
	//the (fake) user who is being sent calmness from the test subject
	NSString *userSyncingTo;
	NSImage *userSyncingToIcon;
	
	float notification_time;
	
	//all the image/name data for (fake) users
	NSString *users[NUM_USERS];
	NSImage *usersIcons[NUM_USERS];

	//User name+icon
	NSString *myName;
	NSImage *myImage;
	FILE    *uilogfp;
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
- (void) set_interval:(id) sender;
- (void) set_display_off:(id)sender;
- (void) set_display_screen:(id)sender;
- (void) set_display_menu:(id)sender;
- (void) set_display_bounce:(id)sender;
- (void) terminate:(id)sender;
- (void) viewGraph:(id)sender;
- (void) uilog:(NSString *)message;


- (void) mainloop:(NSConnection *)connection;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *interval_window;
@property (assign) IBOutlet NSTextField *intervalTextField;

@end
