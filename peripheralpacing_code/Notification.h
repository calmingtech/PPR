//
//  Notification.h
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 9/12/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Notification : NSObject {
	NSString *message;
	NSSound *sound;
}
@property (copy) NSString *message;
@property (assign) NSSound *sound;
@end
