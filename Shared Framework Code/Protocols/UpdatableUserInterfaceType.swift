//
//  UpdatableUserInterfaceType.swift
//  Nightscouter
//
//  Created by Peter Ina on 3/10/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation


#if os(iOS)
    import UIKit
    public typealias ViewController = UIViewController
#elseif  os(watchOS)
    import WatchKit
    public typealias ViewController = WKInterfaceController
#elseif os(OSX)
    import Cocoa
    public typealias ViewController = NSViewController
#endif

public protocol UpdatableUserInterfaceType {
    func startUpdateUITimer()
    var updateInterval: NSTimeInterval { get }
    func updateUI(notif: NSTimer)
}

public extension UpdatableUserInterfaceType where Self: ViewController {
    
    var updateUITimer: NSTimer {
        return NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: Selector("updateUI:"), userInfo: nil, repeats: true)
    }
    
    func startUpdateUITimer() {
        print(updateUITimer)
    }
    
    var updateInterval: NSTimeInterval {
        return 60.0
    }
}


