//
//  TestActor.h
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import "ADBActor.h"

@interface TestActor : ADBActor

@property (nonatomic, assign) ADBActor *nextInChain;

- (void)passItOn:(ADBMessage *)message;

@end
