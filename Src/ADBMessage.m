//
//  ADBMessage.m
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import "ADBMessage.h"

@interface ADBMessage ()

@property (nonatomic, assign) SEL selector;

@end

@implementation ADBMessage

- (id)initWithSelector:(SEL)aSelector
{
    self = [super init];
    if (self) {
        _selector = aSelector;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithSelector:self.selector];
}

@end
