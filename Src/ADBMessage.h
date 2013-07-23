//
//  ADBMessage.h
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import <Foundation/Foundation.h>

@interface ADBMessage : NSObject <NSCopying>

@property (nonatomic, readonly) SEL selector;

- (id)initWithSelector:(SEL)aSelector;

@end
