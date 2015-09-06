//
//  ScrollUtils.h
//  asdfghjkl
//
//  Created by Matt Condon on 9/6/15.
//  Copyright © 2015 mattc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScrollUtils : NSObject

+ (CGEventRef) createScrollEventWithScrollAmount:(int32_t)amt;

@end
