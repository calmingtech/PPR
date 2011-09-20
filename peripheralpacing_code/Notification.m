//
//  Notification.m
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 9/12/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import "Notification.h"


@implementation Notification
@synthesize message;
@synthesize sound;
-(id) init 
{
	message = nil;
	sound = nil;
	return self;
}
@end
