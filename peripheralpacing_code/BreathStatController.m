//
//  BreathStatController.m
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 7/29/11.
//  Copyright 2011 stanford university. All rights reserved.
/* 
	BreathStatController manages the following statistics related to the breathrate:
	1. notify user of moments of stress, calm,zen
	2. detect consistent highs and lows (>30secs) and record screenshots of desktop
	3. Set calm points based on milestone achieved so far (graduated points)
	4. Load calm images based on the calm points accrued.
	5. Record user's resting rate for checkin
*/

#import "BreathStatController.h"
#import "ScreenCapture.h"

@implementation BreathStatController
@synthesize default_baseline;
@synthesize calm_points;
-(void) dealloc { 
	for (Stat *s in statArray) 
		[s release];
	[statArray release];
	[calmRewardsArr release];
	[topHighs release]; 
	[topLows release];
	[super dealloc];

}
-(id) init { 
	[super init];
	/* moStress = [[[Stat alloc] initWithType :Stress trendType:Increasing time_to_notify:180 ldelta: 2 rdelta:2] autorelease];
	moCalm = [[[Stat alloc] initWithType :Calm trendType:Decreasing time_to_notify:180 ldelta: 0 rdelta:0] autorelease];
	moZen = [[[Stat alloc] initWithType :Zen trendType:Decreasing time_to_notify:600 ldelta: 0 rdelta:0] autorelease];
	moHigh = [[[Stat alloc] initWithType :High trendType:Increasing time_to_notify:10 ldelta: -1 rdelta:1] autorelease];
	moLow = [[[Stat alloc] initWithType :Low trendType:Decreasing time_to_notify:10 ldelta: -1 rdelta:1] autorelease];
	//statArray = [[NSMutableArray alloc] init];
	
	 [statArray addObject:moStress];
	 [statArray addObject:moZen];
	 [statArray addObject:moCalm];
	 [statArray addObject:moHigh];
	 [statArray addObject:moLow];
	 */
	fm = [NSFileManager defaultManager];

	statArray = [self ReadStatObjectsFromPropertyArray];
	last_calmpoint = 0;
	
	highs = lows = 0;
	topHighs = [[NSMutableArray alloc] init] ;
	topLows = [[NSMutableArray alloc] init] ;
	notify_reset = false;
	
	imagePath = [[@"~/Desktop/peripheralpacing/Images" stringByExpandingTildeInPath] copy];
	
	statLogger = [[myLogger alloc] initWithPath:[[@"~/Desktop/peripheralpacing/logs/" stringByExpandingTildeInPath] copy]
										logName:[@"statlog.txt" copy]]; 
	milestone = 25;
	last_calmIndex = 0;
	return self;
}
-(NSMutableArray *) ReadStatObjectsFromPropertyArray
{
	NSString *errorDesc = nil;
	NSPropertyListFormat format;
	NSString *plistPath;
	NSString *rootPath =[[@"~/Desktop/peripheralpacing/config/" stringByExpandingTildeInPath] copy];
	plistPath = [rootPath stringByAppendingPathComponent:@"config.plist"];
	if (![fm fileExistsAtPath:plistPath]) {
		plistPath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
	}

	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	NSArray *temp = (NSArray *)[NSPropertyListSerialization
										  propertyListFromData:plistXML
										  mutabilityOption:NSPropertyListMutableContainersAndLeaves
										  format:&format
										  errorDescription:&errorDesc];
	if (!temp) {
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
	}
	int stattype, trendtype,timetonotify,lDelta, rDelta;
	NSMutableArray *statArr = [[NSMutableArray alloc] init];
	calmRewardsArr = [[NSMutableArray arrayWithArray:[temp objectAtIndex:0]] retain];
	NSArray *statDesc = [NSArray arrayWithObjects:@"stress",@"calm",@"zen",@"high",@"low",@"calmpoint",nil ];
	NSArray *trendDesc = [NSArray arrayWithObjects:@"decreasing",@"increasing",nil];
	NSArray *configArr = [temp objectAtIndex:1];
	for (NSDictionary *dict in configArr) { 
		stattype = [statDesc indexOfObject:[[dict objectForKey:@"statType"] lowercaseString]];
		trendtype = [trendDesc indexOfObject:[[dict objectForKey:@"trendType"] lowercaseString]];
		timetonotify = [[dict objectForKey:@"timeToNotify"] intValue];
		lDelta = [[dict objectForKey:@"ldelta"] intValue];
		rDelta = [[dict objectForKey:@"rdelta"] intValue];
		Stat *statObj = [[[Stat alloc] initWithType :stattype trendType:trendtype time_to_notify:timetonotify ldelta: lDelta rdelta:rDelta] autorelease];
		[statArr addObject:statObj];
	}
	showBPM = [[temp objectAtIndex:2] objectForKey:@"ShowBreathRateAndBPM"];
	return statArr;
}
/* 
	Maintain top three highs and top three lows in a dictionary of Stats objects. 
	If a new high/low is detected,take a screenshot and store the path of the image
 */
-(void) updateDictionary:(Stat *)stat { 
	//create a clone of the stat object,and update its image.
	Stat *newStat;
	
	if (stat.stattype == High)
	{
		if ((highs  < statCount) || 
			([[self getMinRateStat:stat.stattype] breathrate] < stat.breathrate)) { 
			newStat = [Stat initWithObject:stat];
			[self setImage:newStat];
			++highs;
			
		}
	}
	
	
	if (stat.stattype == Low) 
	{
		if ((lows < statCount) || 
			([[self getMaxRateStat:stat.stattype] breathrate] > stat.breathrate)) { 
			
			newStat = [Stat initWithObject:stat];
			[self setImage :newStat];
			++lows;
			
		}
	}
}
/* 
	setImage removes the image associated with the lowest "high" stat, 
	when it is bumped off by a new high.
	It also captures a new screenshot and saves the file path in stat.imagePath
 */
-(void) setImage:(Stat *) stat
{ 
	NSString *imgfileName;
	NSMutableArray *topArr = (stat.stattype == High) ? topHighs : topLows;
	if (((stat.stattype == High) && (highs  >= statCount)) || 
		((stat.stattype == Low ) && (lows  >= statCount)))
	{
		Stat *s = (stat.stattype == High ) ? [self getMinRateStat:stat.stattype] : [self getMaxRateStat:stat.stattype];
		imgfileName = s.imagePath;
		[topArr removeObject:s];
		
		
	}
	else {
		imgfileName= [imagePath stringByAppendingFormat:@"/%@%d.jpg",(stat.stattype == High)?@"high":@"low",(stat.stattype == High)? highs:lows ];
	}
	
	
	[fm removeItemAtPath:imgfileName error:nil];
	
	
	[ScreenCapture grabScreenShot:imgfileName];
	stat.imagePath = imgfileName;
	[topArr addObject:stat];
	
	
}
/* 
	return the stat with highest breathrate from the array of topHighs or topLows
 */
-(Stat  *) getMaxRateStat:(enum STATTYPE) type
{	
	NSArray *topArr = (type == High) ? topHighs : topLows;
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"breathrate"	ascending:NO selector:@selector(compare:)];
	
	NSArray *array =[topArr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]]; 
	if ([array count ] > 0) 
		return [array objectAtIndex:0];
	else 
		return nil;
	
}
/* 
 return the stat with least breathrate from the array of topHighs or topLows
 */
-(Stat *) getMinRateStat:(enum STATTYPE) type
{
	NSArray *topArr = (type == High) ? topHighs : topLows;

	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"breathrate"	ascending:YES selector:@selector(compare:)];
	
	NSArray *array =[topArr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]]; 
	
	if ([array count ] > 0) 
		return [array objectAtIndex:0] ;
	else 
		return nil;
}
/*
	Returns an array of images associated with Highs or Lows
 */
-(NSMutableArray *) getImages:(enum STATTYPE) type 
{
	NSMutableArray *imgArray = [[[NSMutableArray alloc] init] autorelease];
	NSArray *topArr = (type == High) ? topHighs : topLows;
	for (int i = 0; i < [topArr count]; ++i) { 
		Stat *stat = [topArr objectAtIndex:i];
		if (stat.stattype == type) { 
			NSImage *image = [[NSImage alloc ]initByReferencingFile:stat.imagePath];
			[imgArray addObject:image];
			[image release];
		}
		
	}
	return imgArray;
}
/* 
	Returns the labels to be displayed for each image in the topHighs/topLows array
*/
-(NSMutableArray *) LabelsForStatType:(enum STATTYPE ) type
{
	NSMutableArray *lblArray = [[[NSMutableArray alloc] init] autorelease];
	NSArray *topArr = (type == High) ? topHighs : topLows;

	for (int i = 0; i < [topArr count]; ++i) { 
		Stat *stat = [topArr objectAtIndex:i];
		if (stat.stattype == type)
			[lblArray addObject:[NSString stringWithFormat:@"(%.1f)bpm at %@",stat.breathrate,stat.date ]];
	}
	return lblArray;
}

-(NSData*)getImagesFromFlickr {
	NSArray *tags = [NSArray arrayWithObjects:@"Stanford-Breathcast-2011",nil];
	NSArray *FlickrArray = [FlickrFetcher photosWithTags:tags];
	int index = rand() % 20;
	return [FlickrFetcher imageDataForPhotoWithFlickrInfo:[FlickrArray objectAtIndex:index]
											format:FlickrFetcherPhotoFormatLarge];
}

/* 
	Get the calm image associated with a milestone
 */
-(NSImage *) getCalmImage 
{
	
	NSImage *calmImage = nil; 
	if (last_calmpoint != calm_points) {
		if ((last_calmIndex < [calmRewardsArr count]) &&
			(calm_points >= [[calmRewardsArr objectAtIndex:last_calmIndex] intValue] )) { 
			//NSString *calmImagePath = [imagePath stringByAppendingFormat:@"/calmImages/image%d.jpg",last_calmIndex ];
			//calmImage  = [[NSImage alloc] initByReferencingFile: calmImagePath];
			calmImage = [[NSImage alloc] initWithData:[self getImagesFromFlickr]];
			[calmImage setName:[NSString stringWithFormat:@"%d-point milestone!",calm_points ]];
			last_calmpoint = calm_points;
			last_calmIndex++;
		}
		
	}
	
	return calmImage;
}
/* 
	This function determines the notifications that need to be displayed based 
	on milestone or duration of calmness/stress.
	stat.notify_duration holds minimum time a trend needs to be kept for a 
	notification, stat.now holds amount of time a trend has been observed so far.
 */
-(Notification *) notifyMoment 
{
	NSString *message = nil;
	Notification *notifier = nil;
	
	if (calm_points >= milestone) { 
		int increment = 25 * (milestone /100 + 1); //to provide tapering off notifications
		milestone += increment;
		notifier = [[Notification alloc] init];
		notifier.message = [NSString stringWithFormat:@"Nice job,you reached %d calm points!",calm_points ];
		return notifier;
	}
	for (Stat *stat in statArray)  { 
		
		if ((stat.now <= stat.notify_duration) ||
		   (((stat.stattype == Calm) || (stat.stattype == Zen)) && !stat.reset)) //calm or zen
			//notifications to be displayed only when the spell is broken.
			continue;
		
		double minutes = stat.now/ 60.0;

		float percentChange;
		if (showBPM) //whether bpm needs to be displayed on the notification
			percentChange = 100 * stat.breathrate/((user_bpm > 0) ? [self user_baseline_bpm] :default_baseline);
		
			switch (stat.stattype) {
			case CalmPoint:
			//1 point per 30secs of calm at base rate, more points if you are below the resting rate.
				calm_points += (percentChange < 100) ? ((100 - percentChange)/10) + 1 : 1; 
					break;
			case Calm:
				message = [NSString stringWithFormat:@"Very cool - %.1f min of calm!",minutes];
				break;
			case Stress:
				if (showBPM)
					message = [NSString stringWithFormat:@"Caution - watch your breath rate.Your breath rate is %.1f (%.1f%%)!",stat.breathrate,percentChange];
				else
					message = [NSString stringWithFormat:@"Caution - watch your breath rate.You've been breathing shallow for %.1f minutes!",minutes];
				break;
			case Zen:
				message = [NSString stringWithFormat:@"Great job! You just had a moment of Zen for %.1f min!",minutes];
				break;
			case Low:
			case High:
				[self updateDictionary:stat];
				break;
			default:
				break;
				
			}
	
		[stat Reset]; //Reset stat object
		
		if (message != nil) {
			notifier = [[[Notification alloc] init] retain];
			notifier.message = [message copy];
			if (stat.stattype == Stress) 
				notifier.sound = [NSSound soundNamed:@"Glass"];
			return notifier;
		};
	}
	return nil;
}
/* 
	Updates the duration of each trend, or resets the stat if the trend is broken
 */
-(void) updateBreathStats :(float) breath_rate :(double) time_delta: (NSString *)dateStr
{
	if (check_in_mode) { 
		checkin_baseline_total += breath_rate;
		checkin_baseline_iterations++;
	}
	NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
	for (Stat *stat in statArray) {
		[self UpdateStat:stat :breath_rate :time_delta:dateStr];
		[s appendFormat:@"%d : %.1f ,",stat.stattype,stat.now];
	}
	[statLogger log:s];
}
/* 
	UpdateStat compares the High and Low objects to their previous breath rate (with 
	a delta margin), and sees if there is a rising or decreasing trend of breathrate.
	For calm and zen stat objects, current breath rate is compared to baseline  
 */
-(void) UpdateStat :(Stat *) stat : (float ) breath_rate :(double) time_delta: (NSString *)dateStr 
{ 
	float compare_rate; //rate to compare current breath rate to.
	if ((stat.stattype == High) || (stat.stattype == Low))
		compare_rate = stat.prev_rate;
	else 
		compare_rate = (user_bpm > 0) ? [self user_baseline_bpm] :default_baseline; //stats based on baseline rate
	
	if (stat.trendType == Increasing) 
		if ((breath_rate >= (compare_rate + stat.rdelta)) ||
			(breath_rate >= (compare_rate + stat.ldelta))) {
			stat.now += time_delta; //duration of trend
			stat.date = dateStr;
		}
		else
			[stat Reset];
	
	if (stat.trendType == Decreasing) 	
		if ((breath_rate <= (compare_rate + stat.rdelta)) ||
			(breath_rate <= (compare_rate + stat.ldelta))) {
			stat.now += time_delta;
			stat.date = dateStr;
		}
		 else 
			{ 
				if ((stat.now <= stat.notify_duration) ||
					((stat.stattype != Calm) && 
					(stat.stattype != Zen)))
					[stat Reset]; 
				else 
					stat.reset = YES; //mark reset, then trigger notification
			} 
		 
		
	stat.breathrate = stat.prev_rate = breath_rate;
	
	
}
/* 
	record the baseline when user presses checkin button
*/
 
-(void) record_checkin_baseline :(BOOL) start 
{
	if (start) { 
		checkin_baseline_total = 0;
		checkin_baseline_iterations = 0;
		check_in_mode = YES;
	}
	else { 
		check_in_mode = NO;
		user_bpm = checkin_baseline_total/(float) checkin_baseline_iterations;
	}
}


-(float) user_baseline_bpm { 
/*
 Disabling use of checkin bpm in guiding user's breathing performance. Instead, use
 the default or recorded baseline with explicit "Record Baseline" option. Replicating 
 function checkin_bpm to just get the checked in bpm.
 */
	//return user_bpm; 
	return self.default_baseline;
}
- (float) checkin_bpm { 
	return user_bpm;
}
- (BOOL) isCheckInMode { 
	return check_in_mode;
}

-(void) setDefaultBaseline:(float) baseline
{ 
	self.default_baseline = baseline;
}
@end
