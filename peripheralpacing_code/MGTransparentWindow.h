#import <Cocoa/Cocoa.h>

@interface MGTransparentWindow : NSWindow
{
   
}

+ (MGTransparentWindow *)windowWithFrame:(NSRect)frame;
- (void)drawRect:(NSRect)rect;
@end
