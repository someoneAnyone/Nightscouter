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

class WatchEntry: Entry {
    var now: NSDate
    var bgdelta: Int
    let battery: Int
    var batteryString: String {
        get{
            // Convert int from JSON into a proper precentge.
            var percentage = Float(battery)/100
            return "\(NSNumberFormatter.localizedStringFromNumber(percentage, numberStyle: NSNumberFormatterStyle.PercentStyle))"
        }
    }
    var batteryColorState: DesiredColorState {
        if battery < 50 && battery > 20 {
            return DesiredColorState.Warning
        } else if battery < 20 {
            return DesiredColorState.Alert
        }
        return DesiredColorState.Neutral
    }
    
    init(identifier: String, date: NSDate, device: String, now: NSDate, bgdelta: Int, battery: Int) {
        self.now = now
        self.bgdelta = bgdelta
        self.battery = battery
        
        super.init(identifier: identifier, date: date, device: device)
    }
}

extension WatchEntry {
    convenience init(watchEntryDictionary: [String : AnyObject]) {
        var now: NSDate = NSDate()
        var date: NSDate = NSDate()
        var device: String = WatchFaceDeviceValue
        var bgdelta: Int = 0
        var battery: Int = 0
        var sgvItem: SensorGlucoseValue?
        var calItem: Calibration?
        
        let newDict: NSMutableDictionary = NSMutableDictionary()
        
        for (key, obj) in watchEntryDictionary {
            if let array = obj as? [AnyObject] {
                if let objDict: NSDictionary = array.first as? NSDictionary {
                    newDict["\(key)"] = objDict
                }
            }
        }
        
        if let status: NSDictionary = newDict[EntryPropertyKey.statusKey] as? NSDictionary {
            if let nowDouble = status[EntryPropertyKey.nowKey] as? Double {
                now = nowDouble.toDateUsingSeconds()
            }
        }
        
        // Blood glucose object
        if let bgs: NSDictionary = newDict[EntryPropertyKey.bgsKey] as? NSDictionary {
            
            sgvItem = SensorGlucoseValue(sgv: 0, direction: .None, filtered: 0, unfiltered: 0, rssi: 0, noise: .None)
            if let directionString = bgs[EntryPropertyKey.directionKey] as? String {
                if let direction = Direction(rawValue: directionString) {
                    sgvItem?.direction = direction
                }
            }
            
            if let sgvString = bgs[EntryPropertyKey.sgvKey] as? String {
                sgvItem?.sgv = sgvString.toInt()!
            }
            
            if let filtered = bgs[EntryPropertyKey.filteredKey] as? Int {
                sgvItem?.filtered = filtered
            }
            
            if let unfiltlered = bgs[EntryPropertyKey.unfilteredKey] as? Int {
                sgvItem?.unfiltered = unfiltlered
            }
            
            if let noiseInt = bgs[EntryPropertyKey.noiseKey] as? Int {
                if let noise = Noise(rawValue: noiseInt) {
                    sgvItem?.noise = noise
                }
            }
            
            if let bgdeltaInt = bgs[EntryPropertyKey.bgdeltaKey] as? Int {
                bgdelta = bgdeltaInt
            }
            
            if let batteryString = bgs[EntryPropertyKey.batteryKey] as? String {
                let batteryInt = batteryString.toInt()
                battery = batteryInt!
            }
            
            if let datetime = bgs[EntryPropertyKey.datetimeKey] as? Double {
                date = datetime.toDateUsingSeconds()
            }
        }
        // cals object
        if let cals: NSDictionary = newDict[EntryPropertyKey.calsKey]as? NSDictionary {
            if let slope = cals[EntryPropertyKey.slopeKey] as? Double {
                if let intercept = cals[EntryPropertyKey.interceptKey] as? Double {
                    if let scale = cals[EntryPropertyKey.scaleKey] as? Double {
                        let calValue = Calibration(slope: slope, scale: scale, intercept: intercept)
                        calItem = calValue
                    }
                }
            }
        }
        
        self.init(identifier: NSUUID().UUIDString, date: date, device: device, now: now, bgdelta: bgdelta, battery: battery)
        self.sgv = sgvItem
        self.cal = calItem
        
        if (sgvItem != nil) && (calItem != nil){
            self.raw = rawIsigToRawBg(sgvItem!, calValue: calItem!)
        }
        
    }
}
