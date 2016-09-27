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
#elseif os(watchOS)
    import WatchKit
    public typealias ViewController = WKInterfaceController
#elseif os(OSX)
    import Cocoa
    public typealias ViewController = NSViewController
#endif


@objc
public protocol UpdatableUserInterfaceType {
    func startUpdateUITimer()
    var updateInterval: TimeInterval { get }
    func updateUI(notif: Timer?)
}

public extension UpdatableUserInterfaceType where Self: ViewController {
    
    var updateUITimer: Timer {
        return Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(Self.updateUI(notif:)), userInfo: nil, repeats: true)
    }
    
    func startUpdateUITimer() {
        print(updateUITimer)
    }
    
    var updateInterval: TimeInterval {
        return 60.0
    }
}


