//
//  Stat.h
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 7/29/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum TRENDTYPE { Decreasing,Increasing } ;
enum STATTYPE  { Stress , Calm, Zen, High, Low ,CalmPoint} ;
@interface Stat : NSObject {
	NSString *date;
	float	 breathrate;
	NSString *imagePath;
	double now;
	enum TRENDTYPE trendType;
	double notify_duration;
	double prev_rate;
	enum STATTYPE stattype;
	int ldelta, rdelta;
	BOOL reset;
}
@property (assign) float breathrate;
@property (copy) NSString *imagePath;
@property (assign) double now;
@property (assign) enum STATTYPE stattype;
@property (assign) enum TRENDTYPE trendType;
@property (assign) double notify_duration;
@property (assign) double prev_rate;
@property (assign) int ldelta,rdelta;
@property (copy) NSString *date;
@property (assign) BOOL reset;
-(void) Reset;

+(id) initWithObject: (Stat *) other;
-(id) initWithType:(enum STATTYPE) type trendType: (enum TRENDTYPE) trend time_to_notify: (double) notify_interval ldelta: (int) l_delta rdelta: (int) r_delta ;
@end
