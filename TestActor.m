//
//  TestActor.m
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import "TestActor.h"

@implementation TestActor

- (void)passItOn:(ADBMessage *)message
{
    NSLog(@"<%@> passes to <%@>", self, self.nextInChain);
    [self.nextInChain executeMessage:message];
}

@end
