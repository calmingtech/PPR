/*
 *  wirelessHdr.h
 *  peripheralpacing
 *
 *  Created by Poorna Krishnamoorthy on 9/11/11.
 *  Copyright 2011 stanford university. All rights reserved.
 *
 */

/*
 * Arduino-serial
 * --------------
 * 
 * A simple command-line example program showing how a computer can
 * communicate with an Arduino board. Works on any POSIX system (Mac/Unix/PC) 
 *
 *
 * Compile with something like:
 * gcc -o arduino-serial arduino-serial.c
 *
 * Created 5 December 2006
 * Copyleft (c) 2006, Tod E. Kurt, tod@todbot.com
 * http://todbot.com/blog/
 *
 * 
 * Updated 8 December 2006: 
 *  Justin McBride discoevered B14400 & B28800 aren't in Linux's termios.h.
 *  I've included his patch, but commented out for now.  One really needs a
 *  real make system when doing cross-platform C and I wanted to avoid that
 *  for this little program. Those baudrates aren't used much anyway. :)
 *
 * Updated 26 December 2007:
 *  Added ability to specify a delay (so you can wait for Arduino Diecimila)
 *  Added ability to send a binary byte number
 *
 * Update 31 August 2008:
 *  Added patch to clean up odd baudrates from Andy at hexapodia.org
 *
 */

#include <stdio.h>    /* Standard input/output definitions */
#include <stdlib.h> 
#include <stdint.h>   /* Standard types */
#include <string.h>   /* String function definitions */
#include <unistd.h>   /* UNIX standard function definitions */
#include <fcntl.h>    /* File control definitions */
#include <errno.h>    /* Error number definitions */
#include <termios.h>  /* POSIX terminal control definitions */
#include <sys/ioctl.h>
#include <getopt.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#define NUM_VALUES 600
#define SENSOR_MAX 1023
void usage(void);
int wireless_port_init(const char* serialport, int baud);
int wireless_port_read_until(int fd, char* buf, char until, int *numRead);
int autoDetect_wireless_port();
int getNextWVal(int fd,int *val,char *header);


int wvalues[NUM_VALUES] = {0};
int indx;
BOOL warm_up_w = YES;

int autoDetect_wireless_port(int baud) { 
	io_object_t serialPort;
	io_iterator_t serialPortIterator;
	int fd;
	//ask for all the serial ports
	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue),&serialPortIterator);
	//Loop through all the serial ports
	while (serialPort = IOIteratorNext(serialPortIterator)) { 
		NSString *portName = IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),kCFAllocatorDefault,0);
		IOObjectRelease(serialPort);
		//A rough hack that should detect Arduino on Mac
		if ([portName hasPrefix :@"/dev/tty.usbserial"] || [portName hasPrefix :@"/dev/tty.usbmodem"] ||
			[portName hasPrefix :@"/dev/cu.usbserial"] || [portName hasPrefix :@"/dev/cu.usbmodem"])
		{	NSLog(@"Detected wireless port=%@",portName);
			fd = wireless_port_init([portName UTF8String],baud);
			int val;
			char header[9600];
			if (fd != -1){
				int rc = getNextWVal(fd, &val,header);
				if ((rc == 0) && (header[0] == '~')) {
					NSLog(@"found the correct port with val=%d",val);
					return fd;
				}
				close(fd);
			}
		}
	}
	return -1;
}

int getNextWVal(int fd,int *val,char *buf) 
{ 
	//char buf[12];
	int numRead, rc;
	do {
		rc = wireless_port_read_until(fd, buf,'\n',&numRead); 
		*val = buf[8] * 256 + buf[9];
		if ((*val == 0) || (*val == 256) || (*val == 512))
			continue;
	//	printf("rc = %d\n",rc);
	} while ((buf[0] != '~') && (numRead < 11) && (rc == 0)) ;
	if ((rc == -1) || (rc == -3)) 
		return rc;
//	printf("buf[8]=%d buf[9]=%d\n",buf[8],buf[9]);
	//int second = (buf[9] == -1) ? 255 : buf[9];
	//int first = 256 * (int) buf[8];
	//printf("val=%d\n",*val);
	//sscanf(buf,"%s %d\n",header,val);
	wvalues[indx] = *val;
	indx = ++indx % NUM_VALUES;
	
	int min = SENSOR_MAX;
	int max = 0;
	if (warm_up_w && (indx == 0))
		warm_up_w = NO;
	//detect if user left computer by checking range of values returned by the sensor
	// over a span of 30 secs.
	if (!warm_up_w) { 
		for (int i = 0; i < NUM_VALUES; i++)
		{
			min = (wvalues[i] < min) ? wvalues[i] : min;
			max = (wvalues[i] > max) ? wvalues[i] : max;
		}
		//NSLog(@"min=%d max = %d ",min,max);
		if (abs(min - max) < 6) 
			return -2;
	}
	return rc;
}
int wireless_port_read_until(int fd, char* buf, char until, int *numRead)
{
    char b[1];
    int i=0,numSleep = 0;
    do { 
        int n = read(fd, b, 1);  // read a char at a time
	//	printf("n=%d\n",n);
        if( n==-1) return -1;    // couldn't read
        if( n==0 ) {
            usleep( 10 * 1000 ); // wait 10 msec try again
            numSleep++;
			if (numSleep == 3000) // Detect if wireless switched off in past 30secs
				return -3;
			continue;
        }
		numSleep = 0;
		if ((i == 0 ) && (b[0] != '~'))
			continue;
        buf[i] = b[0]; 
	//	printf("buf[%d] so far %x\n",i,buf[i]);
		i++;
    } while( i != 11);//b[0] != until );
	*numRead = i;
    buf[i] = 0;  // null terminate the string
	//printf("numread=%d buf=%s",*numRead,buf);
    return 0;
}

// takes the string name of the serial port (e.g. "/dev/tty.usbserial","COM1")
// and a baud rate (bps) and connects to that port at that speed and 8N1.
// opens the port in fully raw mode so you can send binary data.
// returns valid fd, or -1 on error
int wireless_port_init(const char* serialport, int baud)
{
    struct termios toptions;
    int fd;
    
    //fprintf(stderr,"init_serialport: opening port %s @ %d bps\n",
    //        serialport,baud);
	//	char *port = [autoDetect_Arduino_port() UTF8String];
	//  if (port != NULL) 
	//	fd = open(port,O_RDWR | O_NOCTTY | O_NDELAY);
	//else
	fd = open(serialport, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1)  {
        perror("init_serialport: Unable to open port ");
        return -1;
    }
    
    if (tcgetattr(fd, &toptions) < 0) {
        perror("init_serialport: Couldn't get term attributes");
        return -1;
    }
    speed_t brate = baud; // let you override switch below if needed
    switch(baud) {
		case 4800:   brate=B4800;   break;
		case 9600:   brate=B9600;   break;
#ifdef B14400
		case 14400:  brate=B14400;  break;
#endif
		case 19200:  brate=B19200;  break;
#ifdef B28800
		case 28800:  brate=B28800;  break;
#endif
		case 38400:  brate=B38400;  break;
		case 57600:  brate=B57600;  break;
		case 115200: brate=B115200; break;
    }
    cfsetispeed(&toptions, brate);
    cfsetospeed(&toptions, brate);
	
    // 8N1
    toptions.c_cflag &= ~PARENB;
    toptions.c_cflag &= ~CSTOPB;
    toptions.c_cflag &= ~CSIZE;
    toptions.c_cflag |= CS8;
    // no flow control
    toptions.c_cflag &= ~CRTSCTS;
	
    toptions.c_cflag |= CREAD | CLOCAL;  // turn on READ & ignore ctrl lines
    toptions.c_iflag &= ~(IXON | IXOFF | IXANY); // turn off s/w flow ctrl
	
    toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // make raw
    toptions.c_oflag &= ~OPOST; // make raw
	
    // see: http://unixwiz.net/techtips/termios-vmin-vtime.html
    toptions.c_cc[VMIN]  = 0;
    toptions.c_cc[VTIME] = 20;
    
    if( tcsetattr(fd, TCSANOW, &toptions) < 0) {
        perror("init_serialport: Couldn't set term attributes");
        return -1;
    }
	
    return fd;
}
