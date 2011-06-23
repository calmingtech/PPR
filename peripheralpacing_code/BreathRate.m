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
	last_sample_time = 0;
	breath_rate = 0;
	smoothing_index = 0;
	warm_up = true;
	return self;
}

- (float) hann: (int)idx
{
	
	float hann_data[WINDOW_SIZE] = { 0.0, 0.000895,0.0035, 0.0078, 0.0134, 0.0202,0.0278,0.0357,0.0437,\
		0.0512, 0.0580, 0.0636, 0.0679, 0.0705, 0.0714, 0.0705, 0.0679, 0.0636, 0.0580, 0.0512, 0.0437,\
		0.0357,0.0278,0.0202,0.0134,0.0078,0.0035,0.000895,0};  //Normalized hann values
		
	return hann_data[idx];
}

- (float) getBreathRate
{
	return breath_rate;

}


- (id) add_sample: (int) value :(float) time
{
	
	smoothing_buffer[smoothing_index]=value;
	float smooth_val = 0.0;
	for (int i=0; i<WINDOW_SIZE; i++)
		smooth_val += smoothing_buffer[(smoothing_index+1+i)%WINDOW_SIZE] * [self hann:i];
	samples[sample_index] = smooth_val;
    sampleTime[sample_index]  = time;
	//printf("%d\n",samples[sample_index]);
	
	
	
	//calculate breath rate
	if (warm_up)
	{
		breath_rate = 0;
	}
	else {
		int npeaks = 0;
		for (int i = 1; i < NUM_SAMPLES - 1; i++) { 
			if ((samples[i] > samples[i - 1]) && (samples[i] > samples[i + 1]))
			npeaks++;
	}
	int last_index = (sample_index + 1) % NUM_SAMPLES;
	float dt  = sampleTime[sample_index] - sampleTime[last_index];
	//Final breath rate calculation = number of peaks /duration * (60 Sec/1 Min)
	breath_rate = (npeaks) * 60/dt;
		
	//printf("npeaks: %d, myrate: %f dt=%f \n",npeaks,breath_rate,dt);
		
	}
	
	
	
	
	//update sample_index
	sample_index = (sample_index+1)%NUM_SAMPLES;
	smoothing_index = (smoothing_index+1)%WINDOW_SIZE;
	if (sample_index==0)  
		warm_up = false;
	return self;
}

@end
