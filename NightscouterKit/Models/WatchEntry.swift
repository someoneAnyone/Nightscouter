//
//  WatchFace.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

extension EntryPropertyKey {
    static let statusKey = "status"
    static let nowKey = "now"
    static let bgsKey = "bgs"
    static let bgdeltaKey = "bgdelta"
    static let trendKey = "trend"
    static let datetimeKey = "datetime"
    static let batteryKey = "battery"
    static let iob = "iob" // Not implmented yet.
}

let WatchFaceDeviceValue = "watchFace"

public class WatchEntry: Entry {
    public var now: NSDate
    public var bgdelta: Double
    public let battery: Int
    public var batteryString: String {
        get{
            // Convert int from JSON into a proper precentge.
            let percentage = Float(battery)/100
            
            let numberFormatter: NSNumberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = .PercentStyle
            numberFormatter.zeroSymbol = "---%"
            
            return numberFormatter.stringFromNumber(percentage)!
            //            return "\(NSNumberFormatter.localizedStringFromNumber(percentage, numberStyle: NSNumberFormatterStyle.PercentStyle))"
        }
    }
    public var batteryColorState: DesiredColorState {
        if battery < 50 && battery > 20 {
            return DesiredColorState.Warning
        } else if battery <= 20 {
            return DesiredColorState.Alert
        }
        return DesiredColorState.Neutral
    }
    
    public init(identifier: String, date: NSDate, device: String, now: NSDate, bgdelta: Double, battery: Int) {
        self.now = now
        self.bgdelta = bgdelta
        self.battery = battery
        
        super.init(identifier: identifier, date: date, device: device)
    }
}

public extension WatchEntry {
    public convenience init(watchEntryDictionary: [String : AnyObject]) {
        
        
        
        let newDict: NSMutableDictionary = NSMutableDictionary()
        
        for (key, obj) in watchEntryDictionary {
            if let array = obj as? [AnyObject] {
                if let objDict: NSDictionary = array.first as? NSDictionary {
                    newDict["\(key)"] = objDict
                }
            }
        }
        
        guard let status: NSDictionary = newDict[EntryPropertyKey.statusKey] as? NSDictionary,
            nowDouble = status[EntryPropertyKey.nowKey] as? Double  else {
                self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)


                return
        }
        
        
        // Blood glucose object
        guard let bgs: NSDictionary = newDict[EntryPropertyKey.bgsKey] as? NSDictionary else {
            self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)

            return
        }
        
        guard let directionString = bgs[EntryPropertyKey.directionKey] as? String,
            direction = Direction(rawValue: directionString),
            sgv = bgs[EntryPropertyKey.sgvKey] as? String,
            filtered = bgs[EntryPropertyKey.filteredKey] as? Int,
            unfiltlered = bgs[EntryPropertyKey.unfilteredKey] as? Int,
            noiseInt = bgs[EntryPropertyKey.noiseKey] as? Int,
            noise = Noise(rawValue: noiseInt) else {
                self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)

                return
        }
        
        
        var bgdelta: Double = 0
        
        if let bgdeltaString = bgs[EntryPropertyKey.bgdeltaKey] as? String {
            bgdelta = bgdeltaString.toDouble!
        }
        if let bgdeltaNumber = bgs[EntryPropertyKey.bgdeltaKey] as? Double {
            bgdelta = bgdeltaNumber
        }
        
        guard let batteryString = bgs[EntryPropertyKey.batteryKey] as? String else {
            self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)

         return
        }
        
        let batteryInt = Int(batteryString)
        
        guard let datetime = bgs[EntryPropertyKey.datetimeKey] as? Double else {
            self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)

            return
        }
        
        // cals object
        guard let cals: NSDictionary = newDict[EntryPropertyKey.calsKey] as? NSDictionary else {
            self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)

            return
        }
        
        guard let slope = cals[EntryPropertyKey.slopeKey] as? Double,
            intercept = cals[EntryPropertyKey.interceptKey] as? Double,
            scale = cals[EntryPropertyKey.scaleKey] as? Double else {
                self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: "", now: NSDate(), bgdelta: 0, battery: 0)

                return
        }


        
        self.init(identifier: NSUUID().UUIDString, date: datetime.toDateUsingSeconds(), device: WatchFaceDeviceValue, now: nowDouble.toDateUsingSeconds(), bgdelta: bgdelta, battery: batteryInt!)
        self.sgv =  SensorGlucoseValue(sgv: sgv.toDouble!, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: 0, noise: noise)
        self.cal = Calibration(slope: slope, scale: scale, intercept: intercept)
     

    }
}
