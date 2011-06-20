//
//  peripheralpacingAppDelegate.h
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface peripheralpacingAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSWindow *cal_window;
	IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
	NSMenuItem * start_stop;
	NSMenuItem * recordBaseline;
	NSMenuItem * displayOff;
	NSMenuItem * displayScreen;
	NSMenuItem * displayMenu;
	NSMenuItem * displayBounce;
	NSMenuItem * calibrateToggle;
	int displaymode;
	bool running;
	float baseline_bpm;
	bool recording_baseline;
	float baseline_total;
	int baseline_iterations;
	bool calibrateMode;
}

- (void) set_brightness:(float) new_brightness;
- (void) set_brightness_screen:(float) new_brightness;
- (void) set_brightness_menu:(float) new_brightness;
- (void)set_bounce_position:(float)relativePos;

- (void) record_baseline:(id)sender;

- (void) toggle_on_off:(id)sender;
- (void) calibrate_on_off:(id)sender;

- (void) set_display_off:(id)sender;
- (void) set_display_screen:(id)sender;
- (void) set_display_menu:(id)sender;
- (void) set_display_bounce:(id)sender;
- (void) terminate:(id)sender;

- (void) mainloop:(NSConnection *)connection;

@property (assign) IBOutlet NSWindow *window;

@end
