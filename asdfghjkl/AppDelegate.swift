//
//  AppDelegate.swift
//  asdfghjkl
//
//  Created by Matt Condon on 9/5/15.
//  Copyright (c) 2015 mattc. All rights reserved.
//

import Cocoa
import CoreGraphics

let POSITIONS : [Int64: [Int]] = [
  50: [223, 173],
  18: [267, 173],
  19: [309, 173],
  20: [351, 173],
  21: [393, 173],
  23: [435, 173],
  22: [477, 173],
  26: [519, 173],
  28: [561, 173],
  25: [603, 173],
  29: [645, 173],
  27: [687, 173],
  24: [730, 173],
  51: [786, 173],

  48: [233, 214],
  12: [285, 214],
  13: [330, 214],
  14: [372, 214],
  15: [414, 214],
  17: [456, 214],
  16: [498, 214],
  32: [540, 214],
  34: [582, 214],
  31: [624, 214],
  35: [666, 214],
  33: [708, 214],
  30: [750, 214],
  42: [792, 214],

  0: [298, 255],
  1: [340, 255],
  2: [382, 255],
  3: [424, 255],
  5: [466, 255],
  4: [508, 255],
  38: [550, 255],
  40: [592, 255],
  37: [634, 255],
  41: [676, 255],
  39: [718, 255],
  36: [779, 255],

  6: [319, 296],
  7: [361, 296],
  8: [403, 296],
  9: [445, 296],
  11: [487, 296],
  45: [529, 296],
  46: [571, 296],
  43: [613, 296],
  47: [655, 296],
  44: [697, 296],

  49: [489, 340],
  123: [712, 350],
  126: [754, 330],
  125: [754, 350],
  124: [796, 350],
]

let LEFT_KEYS : [Int64] = [50, 18, 19, 20, 21, 23, 48, 12, 13, 14, 15, 17, 0, 1, 2, 3, 5, 6, 7, 8, 9, 11]
let RIGHT_KEYS : [Int64] = [22, 26, 28, 25, 29, 27, 24, 51, 16, 32, 34, 31, 35, 33, 30, 42, 4, 38, 40, 37, 41, 39, 36, 11, 45, 46, 43, 47, 44, 49, 123, 125, 126, 124]

var lastLocation : [Int] = []
var lastKeyCode : Int64?
var isTouchingTimer : NSTimer?
var keyUpTimer : NSTimer?
var timeOfLastKeypress : NSDate?

var wasDragging : Bool = false

var setOfHeldButtons = NSMutableSet()
var setOfPreviouslyHeldButtons = NSSet()
var hasPotentialScroll = false
var isScrolling = false
var scrollTimer : NSTimer?
var scrollUp = false

var interpTimer : NSTimer?
let steps : Double = 15.0

var isScrollingTimer : NSTimer?

var delayedMoveTimer : NSTimer?

let scrollDelay = 0.1

var scrollEventStarted = false
var scrollEventContinued = false
var isMoving = false

class Whatever : NSObject {
  func touchingFinished() {
    isTouchingTimer?.invalidate()
    isTouchingTimer = nil

    lastKeyCode = nil
    timeOfLastKeypress = nil

    delayedMoveTimer?.invalidate()
    delayedMoveTimer = nil

    scrollEventStarted = false
    scrollEventContinued = false
    isMoving = false
  }

  func scrollingFinished() {
    isScrollingTimer = nil
  }

  func lClick() {
    leftClick()
  }

  func rClick() {
    rightClick()
  }

  func interpTimerCallback(timer : NSTimer) {
    let userInfo = timer.userInfo as! [String: Double]
    let iter = userInfo["iteration"]!

    if (iter > steps) {
      // stop iteration
      return
    }

    let interval = userInfo["interval"]!
    let dx = userInfo["dx"]!
    let dy = userInfo["dy"]!
    let fromX = userInfo["fromX"]!
    let fromY = userInfo["fromY"]!
    let dt = interval * iter
    let totalTime = interval * steps

    let t = dt / totalTime

    let newX = lerp(fromX, d: dx, t: t)
    let newY = lerp(fromY, d: dy, t: t)

    moveMouse(to: CGPoint(x: newX, y: newY))

    interpTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: whatever, selector: "interpTimerCallback:", userInfo: [
      "iteration": iter + 1,
      "interval": interval,
      "dx": dx,
      "dy": dy,
      "fromX": fromX,
      "fromY": fromY
      ], repeats: false)
  }

  func interpolateScroll(timer : NSTimer) {
    let userInfo = timer.userInfo as! [String: Double]
    let iter = userInfo["iteration"]!

    if (iter > steps) {
      // stop iteration
      return
    }

    let interval = userInfo["interval"]!
    let dy = userInfo["dy"]!
    let dt = interval * iter
    let totalTime = interval * steps

    let direction = userInfo["direction"]! > 0

    let t = dt / totalTime

    let newY = lerp(0, d: dy, t: t)

    scroll(newY, direction: direction)

    interpTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: whatever, selector: "interpolateScroll:", userInfo: [
      "iteration": iter + 1,
      "interval": interval,
      "dy": dy,
      "direction": direction
      ], repeats: false)
  }

  func delayedMoveTimerCallback(timer : NSTimer) {
    isMoving = true
//    let p = timer.userInfo as! [Int]
//    smoothMoveMouse(by: p)
  }
}

let whatever = Whatever()

func lerp(a : Double, d: Double, t : Double) -> Double {
   return a + d * t
}

func interpolateBetweenPoints(from from: CGPoint, to: CGPoint) {
  let deltaX = to.x - from.x
  let deltaY = to.y - from.y

  let totalTime = 0.08

  interpTimer?.invalidate()
  interpTimer = NSTimer.scheduledTimerWithTimeInterval(totalTime / steps, target: whatever, selector: "interpTimerCallback:", userInfo: [
    "iteration": 0,
    "interval": totalTime / steps,
    "dx": deltaX,
    "dy": deltaY,
    "fromX": from.x,
    "fromY": from.y
  ], repeats: false)
}

func interpolateScroll(amt : Double, direction : Double) {

  let totalTime = 0.4

  interpTimer?.invalidate()
  interpTimer = NSTimer.scheduledTimerWithTimeInterval(totalTime / steps, target: whatever, selector: "interpolateScroll:", userInfo: [
    "iteration": 0,
    "interval": totalTime / steps,
    "dy": amt,
    "direction": direction
    ], repeats: false)
}

func distanceFromLast(keyCode : Int64) -> [Int] {
  // computes the distance with (0,0) at top left
  guard let lastKey = lastKeyCode else {
    return [0, 0]
  }

  let location = POSITIONS[keyCode]!
  let lastLocation = POSITIONS[lastKey]!
  let r = [location[0] - lastLocation[0], location[1] - lastLocation[1]]
  return r
}

func modifyValue(v : Double, forTime time : Double) -> Double {
  let s = -12.5 * time + 4
  return v * s
}

func onShiftKeyDown(keyCode : Int64) {
  
  if let _ = isScrollingTimer {
    // only trigger this block if it's the nth key we've touched in a row

    // deltaT for keyDown events calculations
    var dt = 0.0
    if let tl = timeOfLastKeypress {
      dt = NSDate().timeIntervalSinceDate(tl)
    }

    let d = distanceFromLast(keyCode)
    let direction = d[1] < 0
    let scrollAmt = modifyValue(abs(Double(d[1])/2.0), forTime: dt)
    smoothScroll(scrollAmt, direction: direction ? 1.0 : -1.0)
  }

  lastKeyCode = keyCode
  timeOfLastKeypress = NSDate()

  isScrollingTimer?.invalidate()
  isScrollingTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: whatever, selector: "scrollingFinished", userInfo: nil, repeats: false)

}

func onShiftKeyUp(keyCode : Int64) {

}

func onKeyDown(keyCode : Int64) {
  setOfHeldButtons.addObject(NSNumber(longLong: keyCode))

  if let _ = isTouchingTimer {
    // only trigger this block if it's the nth key we've touched in a row

    // deltaT for keyDown events calculations
    var dt = 0.0
    if let tl = timeOfLastKeypress {
      dt = NSDate().timeIntervalSinceDate(tl)
    }

//    print(keyCode, dt, setOfHeldButtons.count)
    let d = distanceFromLast(keyCode)
    let nd = [
      Int(modifyValue(Double(d[0]), forTime: dt)),
      Int(modifyValue(Double(d[1]), forTime: dt))
    ]

    isMoving = true
    smoothMoveMouse(by: nd)
  } else {
    isTouchingTimer?.invalidate()
    isTouchingTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: whatever, selector: "touchingFinished", userInfo: nil, repeats: false)
  }

  lastKeyCode = keyCode
  timeOfLastKeypress = NSDate()
  // reset the isTouching and keyUp timers every time we get a keyDown
  keyUpTimer?.invalidate()
  keyUpTimer = nil

}

func onKeyUp(keyCode : Int64) {
  setOfHeldButtons.removeObject(NSNumber(longLong: keyCode))

  if !isMoving {
    // if we're not dragging, we care about clicks
    // just in case, create a timer that's invalidated if the user clicks down before the timeout
    keyUpTimer?.invalidate()
    if LEFT_KEYS.contains(keyCode) {
      keyUpTimer = NSTimer.scheduledTimerWithTimeInterval(0.31, target: whatever, selector: "lClick", userInfo: nil, repeats: false)
    } else {
      keyUpTimer = NSTimer.scheduledTimerWithTimeInterval(0.31, target: whatever, selector: "rClick", userInfo: nil, repeats: false)
    }
  } else {
    isTouchingTimer?.invalidate()
    isTouchingTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: whatever, selector: "touchingFinished", userInfo: nil, repeats: false)
  }

}





/****

EVENT FUNCTIONS

****/

func smoothMoveMouse(by by : [Int]) {
  let currentLocation = NSEvent.mouseLocation()
  let newX = currentLocation.x + CGFloat(by[0])
  let newY = currentLocation.y - CGFloat(by[1])

  interpolateBetweenPoints(from: currentLocation, to: CGPoint(x: newX, y: newY))
}

func smoothScroll(amt : Double, direction : Double) {
  interpolateScroll(amt, direction: direction)
}

func moveMouse(by by: [Int]) {

  let currentLocation = NSEvent.mouseLocation()
  let newX = currentLocation.x + CGFloat(by[0])
  // invert to use origin at bottom left
  let newY = (NSScreen.mainScreen()?.frame.size.height)! - (currentLocation.y - CGFloat(by[1]))
  let move = CGEventCreateMouseEvent(
    nil,
    CGEventType.MouseMoved,
    CGPoint(x: newX, y: newY),
    CGMouseButton.Left
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, move)
}

func moveMouse(to to: CGPoint) {
  // lol global coordinates
  let newTo = CGPoint(x: to.x, y: (NSScreen.mainScreen()?.frame.size.height)! - to.y)
  let move = CGEventCreateMouseEvent(
    nil,
    CGEventType.MouseMoved,
    newTo,
    CGMouseButton.Left
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, move)
}

func scroll(amt: Double, direction : Bool) {
  let scrollAmt = amt * (direction ? 1 : -1)
  let move = ScrollUtils.createScrollEventWithScrollAmount(Int32(scrollAmt)).takeRetainedValue() as CGEvent
  CGEventPost(CGEventTapLocation.CGHIDEventTap, move)
}

func leftDown() {
  let down = CGEventCreateMouseEvent(
    nil,
    CGEventType.LeftMouseDown,
    CGPoint(x: NSEvent.mouseLocation().x, y: (NSScreen.mainScreen()?.frame.size.height)! - NSEvent.mouseLocation().y),
    CGMouseButton.Left
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, down)
}

func leftUp() {
  let up = CGEventCreateMouseEvent(
    nil,
    CGEventType.LeftMouseUp,
    CGPoint(x: NSEvent.mouseLocation().x, y: (NSScreen.mainScreen()?.frame.size.height)! - NSEvent.mouseLocation().y),
    CGMouseButton.Left
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, up)
}

func leftClick() {
  leftDown()
  leftUp()
}

func leftDrag(to to : CGPoint) {
  let drag = CGEventCreateMouseEvent(
    nil,
    CGEventType.LeftMouseDragged,
    to,
    CGMouseButton.Left
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, drag)
}

func rightDown() {
  let down = CGEventCreateMouseEvent(
    nil,
    CGEventType.RightMouseDown,
    CGPoint(x: NSEvent.mouseLocation().x, y: (NSScreen.mainScreen()?.frame.size.height)! - NSEvent.mouseLocation().y),
    CGMouseButton.Right
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, down)
}

func rightUp() {
  let up = CGEventCreateMouseEvent(
    nil,
    CGEventType.RightMouseUp,
    CGPoint(x: NSEvent.mouseLocation().x, y: (NSScreen.mainScreen()?.frame.size.height)! - NSEvent.mouseLocation().y),
    CGMouseButton.Right
  )
  CGEventPost(CGEventTapLocation.CGHIDEventTap, up)
}

func rightClick() {
  print("rightClick")
  rightDown()
  rightUp()
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  var eventTap : CFMachPort?
  let w = whatever

  func applicationDidFinishLaunching(aNotification: NSNotification) {

    let eventMask = (1 << CGEventType.KeyDown.rawValue) |
                    (1 << CGEventType.KeyUp.rawValue) |
                    (1 << CGEventType.LeftMouseDown.rawValue) |
                    (1 << CGEventType.LeftMouseUp.rawValue) |
                    (1 << CGEventType.MouseMoved.rawValue) |
                    (1 << CGEventType.RightMouseDown.rawValue) |
                    (1 << CGEventType.RightMouseUp.rawValue) |
                    (1 << CGEventType.LeftMouseDragged.rawValue) |
                    (1 << CGEventType.ScrollWheel.rawValue)

    guard let eventTap = CGEventTapCreate(
      .CGHIDEventTap,
      .HeadInsertEventTap,
      .Default,
      CGEventMask(eventMask),
      { (proxy : CGEventTapProxy, type : CGEventType, event : CGEvent, userInfo : UnsafeMutablePointer<Void>) -> Unmanaged<CGEvent>? in

        let ctrlKeyHeld = (CGEventGetFlags(event).rawValue & CGEventFlags.MaskControl.rawValue) > 0;
        let shiftKeyHeld = (CGEventGetFlags(event).rawValue & CGEventFlags.MaskAlternate.rawValue) > 0;

        if ((ctrlKeyHeld || shiftKeyHeld) && CGEventGetIntegerValueField(event, .KeyboardEventAutorepeat) == 0) {
          // ctrl key and not an autorepeat
          let keyCode = CGEventGetIntegerValueField(event, .KeyboardEventKeycode)

          if (ctrlKeyHeld) {
            if type == .KeyDown {
              onKeyDown(keyCode)
            }

            if type == .KeyUp {
              onKeyUp(keyCode)
            }
          }

          if (shiftKeyHeld) {
            if type == .KeyDown {
              onShiftKeyDown(keyCode)
            }

            if type == .KeyUp {
              onShiftKeyUp(keyCode)
            }
          }

          if [.LeftMouseDown, .LeftMouseUp, .RightMouseDown, .RightMouseUp, .MouseMoved, .LeftMouseDragged, .ScrollWheel].contains(type) {
            CGEventSetFlags(event, CGEventFlags(rawValue: 0)!)
            return Unmanaged.passRetained(event)
          }

          return nil
        }
        return Unmanaged.passRetained(event)
      },
      nil) else {
        print("FAILED");
        exit(1)
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes)
    CGEventTapEnable(eventTap, true)
    CFRunLoopRun()

  }

  

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }


}









