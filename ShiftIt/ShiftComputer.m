#import "ShiftComputer.h"
#import "NSScreen+Coordinates.h"
#import "ShiftIt.h"
#import "ShiftableWindow.h"

CGRect lastWindowRect = {{0,0},{0,0}};

@interface ShiftComputer ()

@property (nonatomic, retain) ShiftableWindow *window;
@property (nonatomic, assign) BOOL isWide;

- (CGRect)screenFrame;
- (float)snapToThirdsForValue:(float)value 
               containerValue:(float)containerValue 
                     ifOrigin:(Origin)Origin 
                  isNearPoint:(CGPoint)point 
        cycleThroughFullValue:(BOOL)cycleThroughFullValue;

@end

@implementation ShiftComputer

@synthesize window, isWide;

+ (ShiftComputer *)shiftComputer {
    return [[[ShiftComputer alloc] init] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        self.window = [ShiftableWindow focusedWindow];
        if (!self.window) return nil;
        self.isWide = self.window.screen.visibleFrame.size.width > self.window.screen.visibleFrame.size.height;
    }
    
    return self;
}

- (void)dealloc {
    self.window = nil;
    [super dealloc];
}

- (CGRect)screenFrame {
    NSScreen *screen = self.window.screen;
    return [screen windowRectFromScreenRect:screen.visibleFrame];
}

- (float)snapToThirdsForValue:(float)value containerValue:(float)containerValue ifOrigin:(Origin)Origin isNearPoint:(CGPoint)point cycleThroughFullValue:(BOOL)cycleThroughFullValue {
    float resultingValue = ceilf(containerValue / 2.0);
    if ([self.window origin:Origin isNearPoint:point]) {
        if (AreClose(value, ceilf(containerValue / 2.0))) {
            resultingValue = ceilf(containerValue / 3.0);
        }
        if (cycleThroughFullValue) {
            if (AreClose(value, ceilf(containerValue / 3.0))) {
                resultingValue = ceilf(containerValue);
            }            
            if (AreClose(value, ceilf(containerValue))) {
                resultingValue = ceilf(2 * containerValue / 3.0);
            }            
        } else {
            if (AreClose(value, ceilf(containerValue / 3.0))) {
                resultingValue = ceilf(2 * containerValue / 3.0);
            }            
        }
    }
    
    return resultingValue;
}

- (void)left {
    CGRect frame = self.screenFrame;
    CGPoint originPoint = CGPointMake(frame.origin.x, self.isWide ? frame.origin.y : self.window.frame.origin.y);
    float targetHeight = self.isWide ? frame.size.height : self.window.frame.size.height;
    float targetWidth = [self snapToThirdsForValue:self.window.frame.size.width containerValue:frame.size.width 
                                          ifOrigin:topLeft isNearPoint:originPoint cycleThroughFullValue:!self.isWide];
    
    [self.window setWindowSize:CGSizeMake(targetWidth, targetHeight) 
                 andSnapOrigin:topLeft 
                            to:originPoint];
}

- (void)right {
    CGRect frame = self.screenFrame;
    CGPoint originPoint = CGPointMake(frame.origin.x + frame.size.width, self.isWide ? frame.origin.y : self.window.frame.origin.y);
    float targetHeight = self.isWide ? frame.size.height : self.window.frame.size.height;
    float targetWidth = [self snapToThirdsForValue:self.window.frame.size.width containerValue:frame.size.width 
                                          ifOrigin:topRight isNearPoint:originPoint cycleThroughFullValue:!self.isWide];
    
    [self.window setWindowSize:CGSizeMake(targetWidth, targetHeight) 
                 andSnapOrigin:topRight 
                            to:originPoint];
}

- (void)top {
    CGRect frame = self.screenFrame;
    CGPoint originPoint = CGPointMake(self.isWide ? self.window.frame.origin.x : frame.origin.x, frame.origin.y);
    float targetHeight = [self snapToThirdsForValue:self.window.frame.size.height containerValue:frame.size.height 
                                           ifOrigin:topLeft isNearPoint:originPoint cycleThroughFullValue:self.isWide];
    float targetWidth = self.isWide ? self.window.frame.size.width : frame.size.width;
    
    [self.window setWindowSize:CGSizeMake(targetWidth, targetHeight) 
                 andSnapOrigin:topLeft 
                            to:originPoint];
}

- (void)bottom {
    CGRect frame = self.screenFrame;
    CGPoint originPoint = CGPointMake(self.isWide ? self.window.frame.origin.x : frame.origin.x, frame.origin.y + frame.size.height);
    float targetHeight = [self snapToThirdsForValue:self.window.frame.size.height containerValue:frame.size.height 
                                           ifOrigin:bottomLeft isNearPoint:originPoint cycleThroughFullValue:self.isWide];
    float targetWidth = self.isWide ? self.window.frame.size.width : frame.size.width;
    
    [self.window setWindowSize:CGSizeMake(targetWidth, targetHeight) 
                 andSnapOrigin:bottomLeft 
                            to:originPoint];
}

- (void)fullscreen {
    CGRect frame = self.screenFrame;
    if (RectsAreClose(self.window.frame, frame) && !CGRectIsEmpty(lastWindowRect)) {
        [self.window setWindowSize:lastWindowRect.size 
                     andSnapOrigin:topLeft 
                                to:lastWindowRect.origin];            
    } else {
        lastWindowRect = self.window.frame;
        [self.window setWindowSize:frame.size 
                     andSnapOrigin:topLeft 
                                to:frame.origin];    
    }
}

- (void)center {
    CGRect frame = self.screenFrame;
    float targetFactor = 0.85;
    
    float currentWidthFactor = self.window.frame.size.width / frame.size.width;
    float currentHeightFactor = self.window.frame.size.height / frame.size.height;
    
    if ([self.window origin:center isNearPoint:CGPointCenterOfCGRect(frame)] && AreClose(currentWidthFactor, currentHeightFactor)) {
        if (AreClose(currentWidthFactor * 1000, 850)) {
            targetFactor = 0.6;
        } else if (AreClose(currentWidthFactor * 1000, 600)) {
            targetFactor = 0.33333;
        }
    }
    
    [self.window setWindowSize:CGSizeMake(frame.size.width * targetFactor, frame.size.height * targetFactor)
                 andSnapOrigin:center
                            to:CGPointCenterOfCGRect(frame)];
}

- (void)swapscreen {
    if ([[NSScreen screens] count] > 1) {
        NSScreen *currentScreen = self.window.screen;
        NSUInteger index = [[NSScreen screens] indexOfObject:currentScreen] + 1;
        NSScreen *nextScreen = [[NSScreen screens] objectAtIndex:index % [[NSScreen screens] count]];
        
        CGRect frame = [nextScreen windowRectFromScreenRect:nextScreen.visibleFrame];
        [self.window setWindowSize:CGSizeMake(frame.size.width * 0.85, frame.size.height * 0.85)
                     andSnapOrigin:center
                                to:CGPointCenterOfCGRect(frame)
                          onScreen:nextScreen];
    }
}

@end