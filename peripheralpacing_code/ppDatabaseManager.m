//
//  ppDatabaseManager.m
//  peripheralpacing
//
//  Created by Jim Zheng on 6/19/11.
//  Copyright 2011 Stanford University. All rights reserved.
//

#import "ppDatabaseManager.h"
#import "SBJson.h"

/* Path configurations for remote server;*/
#define ROOT @"http://www.stanford.edu/~jimzheng/cgi-bin/Breathcast/"
#define USERPATH @"UserInteraction.php"
#define DATAPATH @"DataInteraction.php"
#define FRIENDPATH @"FriendInteraction.php"
#define UPDATEPATH @"UpdateInteraction.php"
#define MESSAGEPATH @"MessageInteraction.php"
#define USERINFOPATH @"GetUserInfo.php"
#define FRIENDINFOPATH @"GetFriendInfo.php"
#define BPMINFOPATH @"GetBPMData.php"
#define LASTPATH @"GetLast.php"
#define MESSAGEINFOPATH @"GetMessages.php"


#define DEFAULT_BPM 0
#define DEFAULT_REST_RATE 13.0
#define MEGABYTE (1024*1024)

@implementation ppDatabaseManager

// need to write a logger function containing errors from the database
// writes the errors out to a log called "db-errors.txt"
+(void)Logger:(NSString *)errorString {
	/*NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
     NSString *file_path = @"student.txt"; 
     NSString *hello_world = @"Hello World!!\n"; 
     [hello_world writeToFile:file_path atomically:YES encoding:NSUnicodeStringEncoding error:nil]; 
     
     [pool drain];*/
}

/* wrapper function on top of NSURL that posts data to remote server.
 * this function takes what's set up between the remote server and the current application
 * and transmits and handles binary data over requests following HTTP standards. 
 *
 * @param type must be @"POST" or @"GET" 
 * Note however note that this only really posts data onto the server
 * 
 * @param uploadURL is the complete url to which the information is to be uploaded not including query strings
 * @param paramString is a string formatted for uploading
 * @param data is any additional data which should be held in the request body
 *
 * the remote source must be designed to return a "0" if execution succeeds, and an error msg upon failure
 * Returns "YES" on success 
 *
 */
+(NSString *)sendHTTPRequest:(NSString *)type 
			   toDestination:(NSString *)uploadURL
			 withParamString:(NSString *)paramString 
					withBody:(NSString *)dataStr
{
	// just adds the data as a last field to the paramstring
	NSString *newParamString;
	if(dataStr) {
		newParamString = [paramString stringByAppendingFormat:@"&data=%@", dataStr];
	}
	else newParamString = paramString;
	
	// init a URL request and encode the param strings in the body
	NSData *requestData = [NSData dataWithBytes: [newParamString UTF8String] length: [newParamString length]];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: uploadURL]]; 
	[request setHTTPMethod: type];
	[request setHTTPBody: requestData];
	NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	NSString* newStr = [[NSString alloc] initWithData:returnData
											 encoding:NSUTF8StringEncoding];
	return newStr;
}

//set various fields; sends the information over as one http request with query strings 
+(BOOL) addUserWithName:(NSString *)name 
			withInitialBPM:(CGFloat)bpm		
			withImageURL:(NSString *)imageURL
			withRestRate:(CGFloat)restingRate
			 withPoints:(int)points
{
	// set up and check the parameters 
    if(!name || !restingRate) return false;
    CGFloat initBPM = (bpm) ? bpm : DEFAULT_BPM;
	CGFloat initRestingRate = (restingRate) ? restingRate : DEFAULT_REST_RATE;
	int initialPoints;
	if(!points) initialPoints = 1;
	else initialPoints = points;
	
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@&bpm=%g&imageurl=%@&restingrate=%g&points=%d",
						  name,	
						  initBPM,
						  imageURL,
						  initRestingRate,
						  initialPoints];
	NSString *rootpath = ROOT;
	NSString *subpath = USERPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	
    NSString *result = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	else {
		NSLog(@"ERROR: %@", result);
		return NO;
	}
}

+(BOOL)changeUserBPM:(NSString *)name 
			   toBPM:(CGFloat)newBPM
{
	NSString *paramStr = [NSString stringWithFormat:@"&field=%@&name=%@&bpm=%g",
						  @"bpm",
						  name,
						  newBPM];
	NSString *rootpath = ROOT;
	NSString *subpath = UPDATEPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *result = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	else {
		NSLog(@"ERROR: %@", result);
		return NO;
	}
}



+(BOOL)updateTimestamp:(NSString *)name {
    if(!name) return FALSE;
    
	NSString *paramStr = [NSString stringWithFormat:@"&field=%@&name=%@",
						  @"timestamp",
						  name];
    NSString *rootpath = ROOT;
	NSString *subpath = UPDATEPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
    NSString *result = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	else {
		NSLog(@"ERROR: %@", result);
		return NO;
	}
}


+(BOOL)changeUserRestRate:(NSString *)name 
			   toRestRate:(CGFloat)newRate
{
	NSString *paramStr = [NSString stringWithFormat:@"&field=%@&name=%@&restingrate=%g",
						  @"restingrate",
						  name,
						  newRate];
	NSString *rootpath = ROOT;
	NSString *subpath = UPDATEPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *result = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	else {
		NSLog(@"ERROR: %@", result);
		return NO;
	}
}

// adds one user by name to the other friend
// returns YES on success
+(BOOL)addFriendUser:(NSString *)friendingUser newFriend:(NSString *)newFriend
{
	NSString *rootpath = ROOT;
	NSString *subpath = FRIENDPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *paramStr = [NSString stringWithFormat:@"&user1=%@&user2=%@",
						friendingUser,
						  newFriend];
	NSString *result = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	else {
		NSLog(@"ERROR: %@", result);
		return NO;
	}
}


// takes some data and inserts it into a username for a specified user
// specified fields we must pass into the JSON:
//					-name
//					-type ("ppr" or "sensor")
//                  -data (in the form of NSArray of floats)
// return YES on success
+(BOOL)addBPMData:(NSArray *)bpmData forUser:(NSString *)name
{
	NSString *rootpath = ROOT;
	NSString *subpath = DATAPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@",
						  name];
	SBJsonWriter *writer = [[SBJsonWriter alloc] init];
	
	// we place the data in proper dictionary json format
	// so that it can be more easily dissected by the backend.
	// this does take up more space if there are lots of data points.
	NSMutableDictionary *dictRepresentation = [[NSMutableDictionary alloc] init];
	for(int j = 0; j < [bpmData count]; j++) {
		[dictRepresentation setObject:[bpmData objectAtIndex:j] forKey:[NSString stringWithFormat:@"%d", 1 + j]];
	}
	NSString *body = [writer stringWithObject:dictRepresentation]; 
	[writer release];
	NSString *result = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:body];
	if([result isEqualToString:@"0"]) return YES;
	else {
		NSLog(@"ERROR: %@", result);
		return NO;
	}
}

// indicates whether there is an error with the return vaue
// of a certain string;
// 'YES' => there is an error
// 'NO' => no error
+(BOOL)checkReturnStrForError:(NSString *)returnStr {
	if(!returnStr) return YES;
	// case insensitive check for error
	NSRange textRange;
	textRange = [[returnStr lowercaseString] rangeOfString:@"error"];
	if(textRange.location == NSNotFound) return NO;
	return YES;
}

+(NSArray *)getBPMDataForUser:(NSString *)name
{
	NSString *rootpath = ROOT;
	NSString *subpath = BPMINFOPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@", name];
	NSString *returnStr = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([self checkReturnStrForError:returnStr]) {
		return NO;
	}
	// parse the formatted data returned into bpm data, which should
	// be properly formatted already
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *result = [parser objectWithString:returnStr];
	[parser release];
	return [result autorelease];	
}

// converts a php date in NSString form and 
// returns the date representation.
// Date is of the specific form 2011-08-11 17:12, denoting 08/11/2011 at 5:12PM.
+(NSDate *)phpDateToNSDate:(NSString *)toConvert {
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehaviorDefault];
	NSDateFormatter *dF = [[NSDateFormatter alloc] init];
    [dF setDateFormat:@"yyyy-MM-dd HH:mm"];
	
    NSDate *convertedDate = [[NSDate alloc] init];
    convertedDate = [dF dateFromString:toConvert];
	
	return convertedDate;
}

+(ppUser *)dictionarytoUser:(NSDictionary *)dict {
    ppUser *newUser = [[ppUser alloc] init];
	[newUser setBpm:[[dict objectForKey:@"bpm"] floatValue]];
	[newUser setRestingRate:[[dict objectForKey:@"restingrate"] floatValue]];
    
	[newUser setName:[dict objectForKey:@"name"]];
	[newUser setImageURL:[dict objectForKey:@"url"]];
	[newUser setPoints:[[dict objectForKey:@"points"] integerValue]];
	NSString *dateStr = [dict objectForKey:@"lastUpdated"];
	[newUser setLastUpdated:[self phpDateToNSDate:dateStr]];
	
	return [newUser autorelease];
}

// converts specifically formatted json with appropriate user information into 
// a ppUser, allocates space for that user, and returns a pointer to the new user
+(ppUser *)jsonToUser:(NSString *)info
{
	// search the info string for certain field, then, allocate a new user for the field.
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSDictionary *userInfo = [parser objectWithString:info error:nil];
	if(!userInfo) {
		NSLog(@"Error; cannot parse user data in jsontoUser:(NSString *)info");
		return NULL;
	}
    return [self dictionarytoUser:userInfo];
	
}

// gets the user info stored remotely; response comes in the form of
// JSON string to be parsed into a dictionary. JSON formatted according
// to PHP standards.
+(ppUser *)getUserInfo:(NSString *)name
{
	NSString *rootpath = ROOT;
	NSString *subpath = USERINFOPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@", name];
	NSString *returnStr = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([self checkReturnStrForError:returnStr]) {
		return NO;
	}
	return [[self jsonToUser:returnStr] autorelease];
}

// returns autoreleased array of friends with target user
// nsarray entries are ppUser entries
// the format of the response is, in JSON form, a dictionary 
// with usernames 
+(NSArray *)getBuddyList:(NSString *)name {
	NSString *rootpath = ROOT;
	NSString *subpath = FRIENDINFOPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@", name];
	
	NSString *returnStr = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([self checkReturnStrForError:returnStr]) {
		return NO;
	}
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *friendArray = [parser objectWithString:returnStr];
	[parser release];
	
	// for each friend, we request the user's info from the user database
	NSMutableArray *result = [[NSMutableArray alloc] init];
	for(int i = 0; i < [friendArray count]; i++) {
		[result addObject:[self getUserInfo:[friendArray objectAtIndex:i]]];
	}
	
	return [result autorelease];
	
}

// gets info for all users. 
+(NSArray *)getAllUsers {
	NSString *rootpath = ROOT;
	NSString *subpath = USERINFOPATH;
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@", @"_ALL"];
	NSString *destination = [rootpath stringByAppendingString:subpath];
	
	NSString *returnStr = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([self checkReturnStrForError:returnStr]) {
		NSLog(@"ERROR");
		return NO;
	}
	
	// return should contain all info associated with users.
	SBJsonParser *parser = [[SBJsonParser alloc] init];
    
	NSArray *result = [parser objectWithString:returnStr];
    NSMutableArray *allUsers = [[NSMutableArray alloc] init];
    for (int i = 0; i < [result count]; i++) {
        [allUsers addObject:[self dictionarytoUser:[result objectAtIndex:i]]];
    }
	[parser release];
	
	return [allUsers autorelease];
}

// returns an autoreleased NSDate
+(NSDate *)getLastUpdate:(NSString*)name {
	NSString *rootpath = ROOT;
	NSString *subpath = LASTPATH;
	
	// must specify opt in the backend; 'one' signifies a single user
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@&opt=%@", name, @"one"];
	NSString *destination = [rootpath stringByAppendingString:subpath];
	
	// get the json server response, parse, and return converted nsdate object
	NSString *returnStr = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *result = [parser objectWithString:returnStr];
	if(!result) return NO;
	NSString *toParse = [[result objectAtIndex:0] objectForKey:@"lastUpdated"];
	if(!toParse) return NO;
	
	NSDate *resultDate = [self phpDateToNSDate:toParse];
	[parser release];
	return resultDate;
}

// similar to bpm, except the 'opt' parameter is changed
+(NSArray *)getBPMLastDay:(NSString *)name {
	NSString *rootpath = ROOT;
	NSString *subpath = LASTPATH;
	
	// must specify opt in the backend; 'day' signifies getting a day's most recent data;
	NSString *paramStr = [NSString stringWithFormat:@"&name=%@&opt=%@", name, @"day"];
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *returnData = [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	
	// expect an nsarray of purely bpm data
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *jsonData = [parser objectWithString:returnData];
	[parser release];
	return [jsonData autorelease];
}

+(BOOL)updatePointsForUser:(NSString*)name to:(NSInteger)newPoints {
	NSString *paramStr = [NSString stringWithFormat:@"&field=%@&name=%@&points=%d",
						  @"points",
						  name,
						  newPoints];
	NSString *rootpath = ROOT;
	NSString *subpath = UPDATEPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *result= [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	return NO;
}

/*Inserts a new message for the user.*/
+(BOOL)addMessagesForUser:(NSString*)name messages:(NSString *)newMsg {
	NSString *paramStr = [NSString stringWithFormat:@"name=%@&message=%@",
						  name,
						  newMsg];
	NSString *rootpath = ROOT;
	NSString *subpath = MESSAGEPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *result= [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	if([result isEqualToString:@"0"]) return YES;
	return NO;	
}

/*
 * transforms an NSArray of NSDictionaries of [date => message]
 */
+(NSDictionary *)getMessagesForUser:(NSString*)name {
	NSString *paramStr = [NSString stringWithFormat:@"name=%@",
						  name];
	NSString *rootpath = ROOT;
	NSString *subpath = MESSAGEINFOPATH;
	NSString *destination = [rootpath stringByAppendingString:subpath];
	NSString *returnStr= [self sendHTTPRequest:@"POST" toDestination:destination withParamString:paramStr withBody:NO];
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	
	NSDictionary *rawInfo = [parser objectWithString:returnStr];
	
	NSMutableDictionary *dictToReturn = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [rawInfo keyEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		NSDate *convertedDate = [self phpDateToNSDate:key];
		[dictToReturn setObject:[rawInfo objectForKey:key] forKey:convertedDate];
	}
	[parser release];
	return [dictToReturn autorelease];
}

@end

