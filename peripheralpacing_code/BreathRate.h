//
//  BreathRate.h
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define NUM_SAMPLES 600
#define WINDOW_SIZE 29

//A BreathRate object allows you to input samples and times and calucates a breath rate based on them.
@interface BreathRate : NSObject
{
@private 
	//a circular buffer for storing the last ~33 seconds of breath data (at a sampling rate of 18samples/sec)
	float samples[NUM_SAMPLES];
	//a circular buffer for storing time at which sample was taken
	float sampleTime[NUM_SAMPLES];

	int sample_index;
	//a circular buffer for storing the last WINDOW_SIZE samples for smoothing
	int smoothing_buffer[WINDOW_SIZE];
	int smoothing_index;
	//the last sample time, for computing a running average sample rate
	float last_sample_time;
//	float average_sample_period;
	//tells us whether or not there is enough data for the breath rate window
	bool warm_up;
	//last calculated breath rate (cycles/min)
	float breath_rate;
	float avg_rate_buffer[NUM_SAMPLES];
	float avg_total;
	int avg_index;
	float inhale_exhale_ratio;
	float inRestPerMinute;
	float outRestPerMinute;
	float init_time;
	//hann window used for smoothing
}

//constructor 
- (id) initWithTime:(double) time;
- (float) hann: (int) idx; 

- (float) getBreathRate;
- (bool)  isWarmUp;

//adds the new sample to the data and calculates new average sample rate, and breath rate based on that
- (id) add_sample: (int) value :(float) time;

@end
