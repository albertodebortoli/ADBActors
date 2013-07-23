//
//  ADBActor.h
//  ADBActors
//
//  Created by Alberto De Bortoli on 23/07/2013.
//

#import <Foundation/Foundation.h>
#import "ADBMessage.h"

@interface ADBActor : NSThread

@property (nonatomic, copy, readonly) NSString *uuid;

- (void)executeMessage:(ADBMessage *)message;

@end
