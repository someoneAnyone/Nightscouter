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

open class WatchEntry: Entry, CustomStringConvertible {
    open var now: Date
    open var bgdelta: Double
    open let battery: Int
    open var batteryString: String {
        get{
            // Convert int from JSON into a proper precentge.
            let percentage = Float(battery)/100
            
            let numberFormatter: NumberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .percent
            numberFormatter.zeroSymbol = "---%"
            
            return numberFormatter.string(from: NSNumber(value: percentage))!
        }
    }
    open var batteryColorState: DesiredColorState {
        if battery < 50 && battery > 20 {
            return DesiredColorState.Warning
        } else if battery <= 20 && battery > 1 {
            return DesiredColorState.Alert
        }
        return DesiredColorState.Neutral
    }
    
    open var raw: Double? {
        if let sgValue:SensorGlucoseValue = self.sgv, let calValue = self.cal {
            let raw: Double = sgValue.rawIsigToRawBg(calValue)
            return sgValue.sgv.isInteger ? round(raw) : raw
            
        }
        return nil
    }
    
    open var description: String {
        return "WatchEntry: { \(dictionary.description) }"
    }
    
    public init(identifier: String, date: Date, device: Device, now: Date, bgdelta: Double, battery: Int) {
        self.now = now
        self.bgdelta = bgdelta
        self.battery = battery
        
        super.init(identifier: identifier, date: date, device: device)
    }
}

public extension WatchEntry {
    public convenience init(watchEntryDictionary: [String: Any]) {
        
        let rootDictionary: NSMutableDictionary = NSMutableDictionary()
        
        let device = Device.WatchFace
        
        for (key, obj) in watchEntryDictionary {
            if let array = obj as? [AnyObject] {
                if let objDict: NSDictionary = array.first as? NSDictionary {
                    rootDictionary["\(key)"] = objDict
                }
            }
        }
        
        
        var nowDouble: Double = 0
        if let statusDictionary = rootDictionary[EntryPropertyKey.statusKey] as? NSDictionary, let now = statusDictionary[EntryPropertyKey.nowKey] as? Double {
            nowDouble = now
        }
        
        // Blood glucose object
        
        var direction = Direction.None
        var sgv: Double = 0
        
        var filtered = 0
        var unfiltlered = 0
        var noise: Noise = .none
        
        var bgdelta: Double = 0
        var batteryInt: Int = 0
        var datetime: Double = 0
        
        if let bgsDictionary = rootDictionary[EntryPropertyKey.bgsKey] as? NSDictionary {
            if let directionString = bgsDictionary[EntryPropertyKey.directionKey] as? String,
                let directionType = Direction(rawValue: directionString),
                let sgvString = bgsDictionary[EntryPropertyKey.sgvKey] as? String {
                    
                    direction = directionType
                    
                    if let sgvDouble = sgvString.toDouble {
                        sgv = sgvDouble
                    }
                    
            }
            
            if let opFiltered = bgsDictionary[EntryPropertyKey.filteredKey] as? Int,
                let opUnfiltlered = bgsDictionary[EntryPropertyKey.unfilteredKey] as? Int
            {
                filtered = opFiltered
                unfiltlered = opUnfiltlered
                
            }
            if let opNoiseInt = bgsDictionary[EntryPropertyKey.noiseKey] as? Int,
                let opNoise = Noise(rawValue: opNoiseInt) {
                    
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
            let intercept = cals[EntryPropertyKey.interceptKey] as? Double,
            let scale = cals[EntryPropertyKey.scaleKey] as? Double else {
                self.init(identifier: UUID().uuidString, date: datetime.toDateUsingSeconds() as Date, device: device, now: nowDouble.toDateUsingSeconds() as Date, bgdelta: bgdelta, battery: batteryInt)
                self.sgv =  SensorGlucoseValue(sgv: sgv, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: 0, noise: noise)
                
                
                return
        }
        
        
        
        self.init(identifier: UUID().uuidString, date: datetime.toDateUsingSeconds() as Date, device: device, now: nowDouble.toDateUsingSeconds() as Date, bgdelta: bgdelta, battery: batteryInt)
        self.sgv =  SensorGlucoseValue(sgv: sgv, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: 0, noise: noise)
        self.cal = Calibration(slope: slope, scale: scale, intercept: intercept, date: date)
        
        
    }
}
