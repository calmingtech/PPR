//
//  BreathRate.m
//  peripheralpacing
//
//  Created by Benjamin Martin Olson on 3/30/11.
//  Copyright 2011 Omni Consumer Products. All rights reserved.
//

#import "BreathRate.h"


@implementation BreathRate

- (id) init
{
	sample_index = 0;
	average_sample_period = 0;
	last_sample_time = 0;
	breath_rate = 0;
	smoothing_index = 0;
	warm_up = true;
	return self;
}

- (float) hann: (int)idx
{
	float hann_data[WINDOW_SIZE] = { 0.0, 0.0125, 0.0495, 0.1091, 0.1883, 0.2831, 0.3887, 0.5000, 0.6113,\
		0.7169, 0.8117, 0.8909, 0.9505, 0.9875, 1.0000, 0.9875, 0.9505, 0.8909, 0.8117, 0.7169,\
		0.6113, 0.5000, 0.3887, 0.2831, 0.1883, 0.1091, 0.0495, 0.0125, 0.0 };	
	return hann_data[idx];
}

- (float) getBreathRate
{
	return breath_rate;
	//float fakebr;
	//NSString *file = [[NSString alloc] initWithContentsOfFile:[[@"~/Desktop/peripheralpacing" stringByExpandingTildeInPath]\
															   stringByAppendingString:@"/br.txt"]];
	//sscanf([file UTF8String],"%f",&fakebr);
	//return fakebr;
}


- (id) add_sample: (int) value :(float) time
{
	//samples[sample_index]=value;
	
	smoothing_buffer[smoothing_index]=value;
	float smooth_val = 0.0;
	for (int i=0; i<WINDOW_SIZE; i++)
		smooth_val += smoothing_buffer[(smoothing_index+1+i)%WINDOW_SIZE] * [self hann:i];
	samples[sample_index] = (int)(smooth_val/13.82+0.5);
	//printf("%d\n",samples[sample_index]);
	
	
	float thisperiod = time - last_sample_time;
	last_sample_time = time;
	
	//calculate sample rate
	if (!warm_up)
	{
		average_sample_period = ((NUM_SAMPLES)*average_sample_period + thisperiod)/(NUM_SAMPLES+1);
	}
	else
	{
		average_sample_period = ((sample_index)*average_sample_period + thisperiod)/(sample_index+1);
	}

	//calculate breath rate
	if (warm_up)
	{
		breath_rate = 0;
	}
	else {
		//naive method: Find breath rate every time by going through the whole array of samples. Computationally expensive, but simple
		
		//a change is a change in direction in the breath data (exhale->inhale, or v.v.). 2 changes = 1 breath cycle
		int changes = 0;
		int direction = 0;

		for (int i=0; i<NUM_SAMPLES; i++)
		{			
			int index = (sample_index+i)%NUM_SAMPLES;
			int last_index1 = (sample_index+i-1)%NUM_SAMPLES;
			int last_index2 = (sample_index+i-2)%NUM_SAMPLES;
			//int last_index3 = (sample_index+i-3)%NUM_SAMPLES;

			//keeps track of whether sample values rise or fall. 1: rise, -1: fall
			if (i>3 && i<NUM_SAMPLES)
			{
				if (samples[index] > samples[last_index1] && 
					samples[last_index1] > samples[last_index2])// &&
					//samples[last_index2] > samples[last_index3])
				{
					if (direction==-1)
						changes++;
					direction = 1;
				}
				if (samples[index] < samples[last_index1] && 
					samples[last_index1] < samples[last_index2])// &&
					//samples[last_index2] < samples[last_index3])
				{
					if (direction==1)
						changes++;
					direction = -1;
				}
			}
		}
		
		//Final calculation: Breaths/Min = Breaths/Period * (Samples/Period)^-1 * (Secs/Sample)^-1 * (60 Sec/1 Min)
		breath_rate = changes/2.0 * 1.0/NUM_SAMPLES * 1.0/average_sample_period * 60;
		//printf("changes: %d, rate: %f\n",changes,breath_rate);
	}
	
	
	
	
	//update sample_index
	sample_index = (sample_index+1)%NUM_SAMPLES;
	smoothing_index = (smoothing_index+1)%WINDOW_SIZE;
	if (sample_index==0)
		warm_up = false;
	return self;
}

@end
