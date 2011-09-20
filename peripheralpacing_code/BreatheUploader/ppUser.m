//
//  ppUser.m
//  Test
//
//  Created by Jim Z Zheng on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ppUser.h"


@implementation ppUser

@synthesize name;
@synthesize bpm;
@synthesize color;
@synthesize image;
@synthesize restingRate;
@synthesize imageURL;
@synthesize points;
@synthesize lastUpdated;

-(NSData *)imageForURL:(NSString *)url
{	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]]; 
	[request setHTTPMethod: @"GET"];
	NSData *responseData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	return responseData;
}

-(ppUser *)initUserWithName:(NSString *)newName
					 withBPM:(CGFloat)newBPM
				  withColor:(UserColorMode)newColor
			 withRestingRate:(CGFloat)newRestingRate 
				withImageURL:(NSString *)newImageURL
				  withPoints:(CGFloat)newPoints
			withLastUpdated:(NSDate *)date;
{
	self.name = newName;
	self.bpm = newBPM;
	self.color = newColor;
	self.restingRate = newRestingRate;
	self.imageURL = newImageURL;
	self.points = newPoints;
	self.image = [self imageForURL:self.imageURL];
	self.lastUpdated = date;
	return [self autorelease];
}

+(void)logUserData:(ppUser *)user {
	NSString *colorString;
	switch(user.color)
	{
		case UCMGreen:
			colorString = @"green";
			break;
		case UCMYellow:
			colorString = @"yellow";
			break;
		case UCMRed:
			colorString = @"red";
			break;
		default:
			colorString = @"red";
			break;
	}
	NSLog(@"{%@: %g, %@, %g, %@}", 
		  user.name,
		  user.bpm,
		  colorString,
		  user.restingRate,
		  user.imageURL);
}

@end
