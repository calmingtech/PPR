//
//  BreathRate.h
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BreathRate : Object
{
@private 
	//a circular buffer for storing the last ~33 seconds of breath data (at a sampling rate of 18samples/sec)
	int samples[600];
	int sample_index;
	float sample_rate;
	//last calculated breath rate
	float breath_rate;
}

- (float) getBreathRate;
- (id) add_sample: (int) value :(float) time;
   
   
@end