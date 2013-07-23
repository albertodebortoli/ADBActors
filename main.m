//
//  main.m
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import <Foundation/Foundation.h>
#import "TestActor.h"

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        TestActor *actor1 = [[TestActor alloc] init];
        TestActor *actor2 = [[TestActor alloc] init];
        TestActor *actor3 = [[TestActor alloc] init];

        actor1.nextInChain = actor2;
        actor2.nextInChain = actor3;
        actor3.nextInChain = actor1;
        
        [actor1 start];
        [actor2 start];
        [actor3 start];

        ADBMessage *message = [[ADBMessage alloc] initWithSelector:@selector(passItOn:)];
        [actor1 executeMessage:message];

        sleep(10);

        [actor1 cancel];
        [actor2 cancel];
        [actor3 cancel];
    }
    
    return 0;
}
