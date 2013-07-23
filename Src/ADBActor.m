//
//  ADBActor.m
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import "ADBActor.h"
#import <objc/message.h>

@interface ADBActor ()

@property (nonatomic, copy, readwrite) NSString *uuid;

- (void)_processMessage:(ADBMessage *)message;

@end

@implementation ADBActor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _uuid = [[NSUUID UUID] UUIDString];
    }
    
    return self;
}

- (void)main
{
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        
        BOOL shouldKeepRunning = YES;
        
        while (shouldKeepRunning && !self.isCancelled) {
            shouldKeepRunning = [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

- (void)executeMessage:(ADBMessage *)message
{
    [self performSelector:@selector(_processMessage:)
                 onThread:self
               withObject:[message copy] //copy to avoid shared state
            waitUntilDone:NO];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %p %@", NSStringFromClass([self class]), self, self.uuid];
}

#pragma mark - Private Methods

- (void)_processMessage:(ADBMessage *)message
{
    if ([self respondsToSelector:message.selector]) {
        objc_msgSend(self, message.selector, message);
    }
}

@end
