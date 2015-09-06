//
//  ScrollUtils.m
//  asdfghjkl
//
//  Created by Matt Condon on 9/6/15.
//  Copyright © 2015 mattc. All rights reserved.
//

#import "ScrollUtils.h"

@implementation ScrollUtils

+ (CGEventRef) createScrollEventWithScrollAmount:(int32_t)amt
{
  return CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, amt, 0);
}

@end
