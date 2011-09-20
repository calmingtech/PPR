//
//  User.h
//  peripheralpacing
//
//  Created by Poorna Krishnamoorthy on 8/26/11.
//  Copyright 2011 stanford university. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface User : NSObject {
	NSString *userName;
	NSString *image;
}
@property (assign) NSString *userName;
@property (assign) NSString *image;

@end
