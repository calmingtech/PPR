//
//  Stat.m
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 7/29/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import "Stat.h"


@implementation Stat
@synthesize breathrate;
@synthesize imagePath, date;
@synthesize now;
@synthesize stattype;
@synthesize trendType;
@synthesize notify_duration,ldelta, rdelta,prev_rate, reset;

-(id) initWithType:(enum STATTYPE) type  trendType: (enum TRENDTYPE) trend time_to_notify: (double) notify_interval ldelta: (int) l_delta rdelta: (int) r_delta {
	breathrate = prev_rate = 0.0;
	now = [[NSDate date] timeIntervalSinceNow] * -1;
	self.stattype = type;
	self.trendType = trend;
	self.notify_duration = notify_interval;
	self.ldelta = l_delta;
	self.rdelta = r_delta;
	self.reset = NO;
	return self;
}

-(void) Reset 
{
//	NSLog(@"resetting stat for type=%d now=%.1f rate=%.1f",now, breathrate,stattype);
	now = 0.0;
	reset = NO;
	//prev_rate = breathrate = 0.0;
}
+(id) initWithObject: (Stat *) other

{
	Stat  *clone = [[Stat alloc] init];
	clone.breathrate = other.breathrate;
	clone.date = other.date;
	clone.imagePath = other.imagePath;
	clone.now = other.now;
	clone.trendType = other.trendType;
	clone.stattype = other.stattype;
	clone.notify_duration = other.notify_duration;
	clone.ldelta = other.ldelta;
	clone.rdelta = other.rdelta;
	clone.prev_rate = other.prev_rate;
	clone.reset = other.reset;
	return clone;
}


@end
