//
//  ppDatabaseManager.h
//  peripheralpacing
//
//  Created by Jim Zheng on 6/19/11.
//  Copyright 2011 Stanford University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ppUser.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"

@interface ppDatabaseManager : NSObject


/* DATABASE API
 * 
 * Encapsulates access and manipulation of information 
 * stored remotely on the Stanford server.
 * 
 * By Jim Zheng
 * 
 */
    
/* setting actions send requests to the server, and return YES on success */
+(BOOL) addUserWithName:(NSString *)name 
		 withInitialBPM:(CGFloat)bpm		
		   withImageURL:(NSString *)imageURL
		   withRestRate:(CGFloat)restingRate
			 withPoints:(int)points;

+(ppUser *)getUserInfo:(NSString *)name; // NOTE: ppUser returned is not retained
+(BOOL)changeUserRestRate:(NSString *)name toRestRate:(CGFloat)newRate;
+(BOOL)changeUserBPM:(NSString *)name toBPM:(CGFloat)newBPM;
+(BOOL)updatePointsForUser:(NSString*)name to:(NSInteger)newPoints;
+(BOOL)addMessagesForUser:(NSString*)name messages:(NSString *)message;
+(BOOL)addFriendUser:(NSString *)friendingUser newFriend:(NSString *)newFriend;
+(BOOL)addBPMData:(NSArray *)bpmData forUser:(NSString *)name;
// every time a user logs in, add a userLoggedIn call so we keep track
// of when a user last logs in.
+(BOOL)updateTimestamp:(NSString *)name;


/* 'get' functions return data into nested NSObjects 
 * If there is an error getting data from the database
 * these functions will return NO.
 * 
 * NOTE: Please retain each of these objects if you would them
 * to persist throughout the application.
 * 
 */
+(NSArray *)getBuddyList:(NSString *)name; // an NSArray of ppUsers
+(NSArray *)getAllUsers; // NSArray containing names (NSStrings) only
+(NSArray *)getBPMDataForUser:(NSString *)name;
+(NSDate *)getLastUpdate:(NSString*)name; // gets the most recent BPM data
+(NSArray *)getBPMLastDay:(NSString *)name; // gets all BPM data of a cetain day. 
+(NSDictionary *)getMessagesForUser:(NSString*)username; // gets a dictionary of keys as times and values as 


@end
