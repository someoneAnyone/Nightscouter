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
        
        
        
        let rootDictionary: NSMutableDictionary = NSMutableDictionary()
        
        for (key, obj) in watchEntryDictionary {
            if let array = obj as? [AnyObject] {
                if let objDict: NSDictionary = array.first as? NSDictionary {
                    rootDictionary["\(key)"] = objDict
                }
            }
        }
        
        
        var nowDouble: Double = 0
        if let statusDictionary = rootDictionary[EntryPropertyKey.statusKey] as? NSDictionary, now = statusDictionary[EntryPropertyKey.nowKey] as? Double {
            nowDouble = now
        }
        
        // Blood glucose object
        
        var direction = Direction.None
        var sgv: Double = 0
        
        var filtered = 0
        var unfiltlered = 0
        var noise: Noise = .None
        
        var bgdelta: Double = 0
        var batteryInt: Int = 0
        var datetime: Double = 0
        
        if let bgsDictionary = rootDictionary[EntryPropertyKey.bgsKey] as? NSDictionary {
            if let directionString = bgsDictionary[EntryPropertyKey.directionKey] as? String,
                directionType = Direction(rawValue: directionString),
                sgvString = bgsDictionary[EntryPropertyKey.sgvKey] as? String {
                    
                    direction = directionType
                    
                    if let sgvDouble = sgvString.toDouble {
                        sgv = sgvDouble
                    }
                    
            }
            
            if let opFiltered = bgsDictionary[EntryPropertyKey.filteredKey] as? Int,
                opUnfiltlered = bgsDictionary[EntryPropertyKey.unfilteredKey] as? Int,
                opNoiseInt = bgsDictionary[EntryPropertyKey.noiseKey] as? Int,
                opNoise = Noise(rawValue: opNoiseInt) {
                    
                    filtered = opFiltered
                    unfiltlered = opUnfiltlered
                    noise = opNoise
                    
            }
            
            
            
            
            if let bgdeltaString = bgsDictionary[EntryPropertyKey.bgdeltaKey] as? String {
                bgdelta = bgdeltaString.toDouble!
            }
            if let bgdeltaNumber = bgsDictionary[EntryPropertyKey.bgdeltaKey] as? Double {
                bgdelta = bgdeltaNumber
            }
            
            
            
            if let batteryString = bgsDictionary[EntryPropertyKey.batteryKey] as? String {
                
                if let batInt = Int(batteryString) {
                    batteryInt = batInt
                }
                
            }
            
            if let datetimeDouble = bgsDictionary[EntryPropertyKey.datetimeKey] as? Double  {
                datetime = datetimeDouble
            }
        }
        
        
        
        
        // cals object
        var cals: NSDictionary = NSDictionary()
        
        if let opCals: NSDictionary = rootDictionary[EntryPropertyKey.calsKey] as? NSDictionary {
            cals = opCals
        }
        
        
        
        guard let slope = cals[EntryPropertyKey.slopeKey] as? Double,
            intercept = cals[EntryPropertyKey.interceptKey] as? Double,
            scale = cals[EntryPropertyKey.scaleKey] as? Double else {
                self.init(identifier: NSUUID().UUIDString, date: datetime.toDateUsingSeconds(), device: WatchFaceDeviceValue, now: nowDouble.toDateUsingSeconds(), bgdelta: bgdelta, battery: batteryInt)
                self.sgv =  SensorGlucoseValue(sgv: sgv, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: 0, noise: noise)
                
                
                return
        }
        
        
        
        self.init(identifier: NSUUID().UUIDString, date: datetime.toDateUsingSeconds(), device: WatchFaceDeviceValue, now: nowDouble.toDateUsingSeconds(), bgdelta: bgdelta, battery: batteryInt)
        self.sgv =  SensorGlucoseValue(sgv: sgv, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: 0, noise: noise)
        self.cal = Calibration(slope: slope, scale: scale, intercept: intercept)
        
        
    }
}