//
//  ppUser.h
//  
//  Created by Jim Z Zheng on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//  Representative of a typical user. This class handles the 
//  remote interaction of gettting/retrieving data.
//	Usage:
//  Initialize this class using its initUserWithName method
//  and change properties using getters/setters.


#import <Cocoa/Cocoa.h>

// UserColorMode defines how "well" the user is breathing; green = optimal, red = alarming
typedef enum {
    UCMRed,
    UCMGreen,
    UCMYellow
} UserColorMode;

// Common model used for storing information about usrs
// in our remote and local databases. 
@interface ppUser : NSObject {
	NSString *name;
	CGFloat bpm;
	UserColorMode color;
	NSData *image;
	CGFloat restingRate;
	NSString *imageURL;
	NSInteger points;
	NSDate *lastUpdated;
}

@property (nonatomic, retain) NSString *name;	
@property (nonatomic) CGFloat bpm;
@property (nonatomic) UserColorMode color;
@property (nonatomic, retain) NSData *image;
@property (nonatomic) CGFloat restingRate;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic) NSInteger points;
@property (nonatomic, retain) NSDate* lastUpdated;

// gets the NSData for this user based on the stored data
-(NSData *)imageForURL:(NSString *)url;

-(ppUser *)initUserWithName:(NSString *)name
					withBPM:(CGFloat)bpm
				  withColor:(UserColorMode)color
			withRestingRate:(CGFloat)restingRate 
			   withImageURL:(NSString *)imageURL
				 withPoints:(CGFloat)newPoints
			withLastUpdated:(NSDate *)date;

// prints out a user's information in easy-to-read form
+(void)logUserData:(ppUser *)user;

@end
