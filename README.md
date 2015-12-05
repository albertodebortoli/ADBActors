ADBActors
===========================

Post: http://albertodebortoli.github.io/blog/2014/05/20/asynchronous-message-passing-with-actors-in-objective-c/

Simple concept of Actor Model in Objective-C based on the idea of Valletta Ventures [Actors library](http://vallettaventures.com/2012/03/04/asynchronous-message-passing-in-Objective-C/).

Usage:

* subclass `ADBActor`
* see main.m for example 

## Actors, these strangers

Although we are all in love with Objective-C, the power of a language itself is given by its inner features. Languages like [Ada](https://www.adacore.com/adaanswers/about/ada) have a built-in concurrency model, while Objective-C needs external libraries (let's say `libdispatch`) to try to achieve the same power of expression found in richer languages.

The same happened for the implementation of the Actor Model. The standout language for the feature of asynchronous message passing using the actor model is Erlang. From [Wikipedia](http://en.wikipedia.org/wiki/Actor_model):

{% blockquote %}
The actor model in computer science is a mathematical model of concurrent computation that treats "actors" as the universal primitives of concurrent digital computation: in response to a message that it receives, an actor can make local decisions, create more actors, send more messages, and determine how to respond to the next message received.
{% endblockquote %}

That said, languages like Ada and Erlang are semantically more powerful than Objective-C, as some features are expressed at the language level rather than through libraries provided in the user space.

Adopting the Actor Model means avoiding the Object Orientation orthodoxy and forcing the developer to write software as a collection of smaller communicating programs that do not share state. Software written using the Actor Model approach is inevitably more "pure" than its traditional counterpart as the paradigm expresses a better level of abstraction, no matter which language is used. 

<!-- more -->

In the Actor Model concurrency paradigm, each Actor waits to receive a message. When it gets one it processes the message, and notifies – via another message – one or more other actors. Actors communicate asynchronously by message passing, rather than sharing resources or using primitive mechanisms (locks, semaphores, etc...) to guarantee mutual access to them. As is well known, the standard approach carries a high risk of race conditions, deadlocks and similar pesky problems.
In their pure form, Actors can scale to thousands of threads spread out over hundreds of cores.

## Thread safety, the standard path

Returning to the world of Objective-C from this little digression, a widely accepted way to deal with a locking mechanism is to use queues that provide an intrinsic way to stem the danger of thread safety. Grand Central Dispatch (GCD) should be the first choice that comes to mind, but it does not solve the thread safety issues – and the programmer still has to design carefully to guarantee the thread safety.

The following code provides an intrinsic lock mechanism for a mutable data structure using a serial queue.

```objective-c
@interface ThreadSafeStorage : NSObject

- (id)objectForKey:(NSString *)key;
- (void)addObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

@end
```

```objective-c
@interface ThreadSafeStorage ()

@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, strong) dispatch_queue_t lockQueue;

@end

@implementation ThreadSafeStorage

- (instancetype)init
{
    if (self = [super init]) {
        _lockQueue = dispatch_queue_create("com.albertodebortoli.threadsafestorage", DISPATCH_QUEUE_SERIAL);
        _data = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)objectForKey:(NSString *)key
{
    __block id retVal = nil;
    dispatch_sync(self.lockQueue, ^{
        retVal = [self.data objectForKey:key];
    });
    return retVal;
}

- (void)addObject:(id)object forKey:(NSString *)key
{
    dispatch_async(self.lockQueue, ^{
        [self.data setObject:object forKey:key];
    });
}

- (void)removeObjectForKey:(NSString *)key
{
    dispatch_async(self.lockQueue, ^{
        [self.data removeObjectForKey:key];
    });
}

@end
```

In the given class there are no explicit locks or similar primitives to guarantee mutual access, but still, any method will need to ensure that the data is accessed under mutual exclusion. This becomes particularly problematic when the class is modified at a later date and the real thread safety of the class is hard to prove.

Consider a class whose responsibility is to persist data on a SQLite database, which is an example of shared data. Let's consider the threading issues dealing with different Managed Object Contexts in Core Data: one could try to solve the problem with an Actor (a thread) that intrinsically applies a lock mechanism to the shared data and thread safety.

The actor semantics are learnable by most developers and 'safer' than their locked counterparts. They raise the abstraction level and allow developers to focus on coordinating access to the data rather than protecting all accesses to it with locks. 

## Actors, talking business

We are about to propose an Actor Model implementation inspired on the original implementation of [Valletta Ventures](https://github.com/vallettaventures/VVActors) library.

The main classes are Messages and Actors. Let's start with the Message: it is simply a wrapper for a selector.

Interface file:

```objective-c
@interface ADBMessage : NSObject <NSCopying>

@property (nonatomic, readonly) SEL selector;

- (id)initWithSelector:(SEL)aSelector;

@end
```

Implementation file:

```objective-c
@interface ADBMessage ()

@property (nonatomic, assign) SEL selector;

@end

@implementation ADBMessage

- (id)initWithSelector:(SEL)selector
{
    self = [super init];
    if (self) {
        _selector = selector;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
```

The intention is to subclass `Message` to add custom fields appropriate to the message. It is important to note that in order to avoid sharing state, `Message` and any of its subclasses must be copied.

The `Actor` class looks as follows:

```objective-c
@interface ADBActor : NSThread

@property (nonatomic, copy, readonly) NSString *uuid;

- (void)executeMessage:(ADBMessage *)message;

@end
```

with the following implementation:

```objective-c

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
            shouldKeepRunning = [runLoop runMode:NSDefaultRunLoopMode
                                      beforeDate:[NSDate distantFuture]];
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
```

The important parts here are:

* Each Actor is a `NSThread` subclass
* Actors are meant to be subclassed to perform ad-hoc tasks
* `executeMessage:` can be called from any thread, and this guarantees the thread safety

An Actor, when booted, will start an NSRunLoop which will be used to dispatch any queued messages to the correct method. Using the NSRunLoop we will idle for free when no messages are queued.

`executeMessage:` is used to pass a message to an Actor, which copies the message to avoid shared state and places the call in the run loop. When called by the run loop the `_processMessage:` selector calls the selector specified in the message with the message as an argument. The message is automatically released after the method has returned.

## Let me play, please

The easiest way to see this in action is with a super simple example (taken from the original implementation of [Valletta Ventures](http://vallettaventures.com/2012/03/04/asynchronous-message-passing-in-Objective-C/) library. First, subclass Actor:

```objective-c
@interface TestActor : ADBActor

@property (nonatomic, assign) ADBActor *nextInChain;

- (void)passItOn:(ADBMessage *)message;

@end
```

```objective-c
@implementation TestActor

- (void)passItOn:(ADBMessage *)message
{
    NSLog(@"<%@> passes to <%@>", self, self.nextInChain);
    [self.nextInChain executeMessage:message];
}

@end
```

then create some actors, put them in a chain and fire the message passing:

```objective-c
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
```

These actor will keep passing the message between them for 10 seconds, after which the actors will be cancelled.

The full code can be found on GitHub in my [ADBActors repository](https://github.com/albertodebortoli/ADBActors)


## Uh, cool stuff, so...

You could consider to use the actor paradigm when:

* you can decompose your problem into a set of independent tasks linked by a clear workflow
* you want to be able to cancel jobs
* you want to scale across threads and cores
* you have a complex system that involves dependencies and shared state
* you want to avoid the usage of explicit locks to protect shared state and actually make copies of that state (messages) and reacting to them locally
* you want to code components that are intrinsically thread safe

# License

Licensed under the New BSD License.

Copyright (c) 2013, Alberto De Bortoli
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Alberto De Bortoli nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Alberto De Bortoli BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Resources

Info can be found on [my website](http://albertodebortoli.com), [and on Twitter](http://twitter.com/albertodebo).
