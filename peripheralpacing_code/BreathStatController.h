//
//  BreathStatController.h
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 7/29/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Stat.h"
#import "ScreenCapture.h"
#import "myLogger.h"
#import "Notification.h"
#import "FlickrAPIKey.h"
#import "FlickrFetcher.h"
#define statCount 3
#define NUM_IMAGES 10
@interface BreathStatController : NSObject {
	NSMutableArray  *topHighs, *topLows;
	NSMutableDictionary *topStats;
	int highs, lows;
	NSString *imagePath;
	NSFileManager *fm;
	NSMutableArray *statArray;
	BOOL check_in_mode;
	float checkin_baseline_iterations;
	float checkin_baseline_total;
	float user_bpm,default_baseline;
	int calm_points;
	NSArray *calmRewardsArr;
	int last_calmpoint ;
	Stat *moStress, *moCalm, *moZen, *moHigh, *moLow;
	myLogger *statLogger;
	BOOL notify_reset, showBPM;
	int milestone;
	int last_calmIndex;
}
-(void) updateBreathStats :(float) breath_rate :(double) time_delta :(NSString *)dateStr ;
-(void) UpdateStat :(Stat *)stat :(float ) breath_rate : (double) time_delta :(NSString *)dateStr ;
-(void) updateDictionary:(Stat *)stat;

-(NSMutableArray *) LabelsForStatType:(enum STATTYPE ) type;
-(void) setImage:(Stat *) stat;
-(Stat  *) getMaxRateStat:(enum STATTYPE) type;
-(Stat  *) getMinRateStat:(enum STATTYPE) type;
-(NSMutableArray *) getImages:(enum STATTYPE) type;
-(NSImage *) getCalmImage;


-(void) record_checkin_baseline :(BOOL) start;
-(float) user_baseline_bpm;
- (float) checkin_bpm;
-(void) setDefaultBaseline:(float) baseline;
- (BOOL) isCheckInMode;
-(Notification *) notifyMoment;
-(NSMutableArray *) ReadStatObjectsFromPropertyArray;
-(NSData*)getImagesFromFlickr;
@property(assign) float default_baseline;
@property(assign) int calm_points;
@end
