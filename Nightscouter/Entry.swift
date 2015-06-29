//
//  Entry.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

// TODO:// Clean these up.

public enum Direction : String {
    case None = "None", DoubleUp = "DoubleUp", SingleUp = "SingleUp", FortyFiveUp = "FortyFiveUp", Flat = "Flat", FortyFiveDown = "FortyFiveDown", SingleDown = "SingleDown", DoubleDown = "DoubleDown", NotComputable = "NOT COMPUTABLE", RateOutOfRange = "RateOutOfRange"
    
    var description : String {
        get {
            switch(self) {
                // Use Internationalization, as appropriate.
            case .None: return "None"
            case .DoubleUp: return "Double Up"
            case .SingleUp: return "Single Up"
            case .FortyFiveUp: return "Forty Five Up"
            case .Flat: return "Flat"
            case .FortyFiveDown: return "Forty Five Down"
            case .SingleDown: return "Single Down"
            case .DoubleDown: return "Double Down"
            case .NotComputable: return "N/C"
            case .RateOutOfRange: return "Rate Out Of Range"
            }
        }
    }
    
    func emojiForDirection() -> String {
        switch (self) {
        case .None: return "None"
        case .DoubleUp: return  "⇈"
        case .SingleUp: return "↑"
        case .FortyFiveUp: return  "➚"
        case .Flat: return "→"
        case .FortyFiveDown: return "➘"
        case .SingleDown: return "↓"
        case .DoubleDown: return  "⇊"
        case .NotComputable: return "-"
        case .RateOutOfRange: return "✕"
        }
    }
    
    func directionForString(directionString: String) -> Direction {
        switch directionString {
        case "None": return .None
        case "DoubleUp": return .DoubleUp
        case "SingleUp": return .SingleUp
        case "FortyFiveUp": return .FortyFiveUp
        case "Flat": return .Flat
        case "FortyFiveDown": return .FortyFiveDown
        case "SingleDown": return .SingleDown
        case "DoubleDown": return .DoubleDown
        case "NOT COMPUTABLE": return .NotComputable
        case "RateOutOfRange": return .RateOutOfRange
        default: return .None
        }
        
    }
}

enum Noise : Int, Printable {
    
    case None = 0, Clean = 1, Light = 2, Medium = 3, Heavy = 4, OtherHeavy = 5
    
    var description: String {
        switch (self) {
        case .None: return "---"
        case .Clean: return "Clean"
        case .Light: return "Light"
        case .Medium: return "Medium"
        case .Heavy: return "Heavy"
        case .OtherHeavy: return "~~~"
        }
    }
}

enum TypedString: String {
    case sgv = "sgv"
    case cal = "cal"
    case mbg = "mbg"
    case serverforecast = "server-forecast"
}

enum Type {
    case sgv(SensorGlucoseValue)
    case cal(Calibration)
    case mbg(MeterBloodGlucose)
    case unknown(String)
}



// type = cal
struct Calibration {
    let slope: Double
    let scale: Double
    let intercept: Double
}


// type = sgv
struct SensorGlucoseValue {
    let sgv: Int
    let direction: Direction
    let filtered: Int
    let unfiltered: Int
    let rssi: Int
    let noise: Noise
    
    var sgvText: String {
        get {
            if sgv < 39 {
                let special:SpecialSensorGlucoseValues = SpecialSensorGlucoseValues(rawValue: sgv)!
                switch (special) {
                case .NoGlucose:
                    return "?NG"
                case .SensoreNotActive:
                    return "?NA"
                case .MinimalDeviation:
                    return "?MD"
                case .NoAntenna:
                    return "?NA"
                case .SensorNotCalibrated:
                    return "?NC"
                case .CountsDeviation:
                    return "?CD"
                case .AbsoluteDeviation:
                    return "?AD"
                case .PowerDeviation:
                    return "?PD"
                case .HupHolland:
                    return "MH"
                default:
                    return "✖"
                }
            } else {
                return NSNumberFormatter.localizedStringFromNumber(self.sgv, numberStyle: NSNumberFormatterStyle.NoStyle)
            }
        }
    }
}

enum SpecialSensorGlucoseValues: Int {
    case NoGlucose=0, SensoreNotActive=1, MinimalDeviation=2, NoAntenna=3, SensorNotCalibrated=5, CountsDeviation=6, AbsoluteDeviation=9, PowerDeviation=10, HupHolland=17
}


// type = mgb
struct MeterBloodGlucose {
    let mbg: Int
}


struct EntryPropertyKey {
    
    static let typeKey = "type"
    static let sgvKey = "sgv"
    static let calKey = "cal"
    static let mgbKey = "mbg"
    static let serverforecastKey = "serverForcastKey"
    static let directionKey = "direction"
    static let dateKey = "date"
    static let filteredKey = "filtered"
    static let unfilteredKey = "unfiltered"
    static let noiseKey = "noise"
    static let calsKey = "cals"
    static let slopeKey = "slope"
    static let interceptKey = "intercept"
    static let scaleKey = "scale"
    static let rssiKey = "rssi"
}


class Entry: NSObject {
    var idString: String
    var device: String
    var date: NSDate
    var dateString: String?
    var sgv: SensorGlucoseValue?
    var cal: Calibration?
    var mbg: MeterBloodGlucose?
    //    var type: Type
    
    var raw: Double?
    var type: TypedString?
    
    var dictionaryRep: NSDictionary {
        get{
            let entry: Entry = self
            
            var color: String = "white"
            let type: TypedString = entry.type!
            switch(type)
            {
            case .sgv:
                color = "grey"
            case .mbg:
                color = "red"
            case .cal:
                color = "yellow"
            case .serverforecast:
                color = "blue"
            }
            //Mon Jun 15 2015 21:17:35 GMT-0400 (EDT)
            let nsDateFormatter = NSDateFormatter()
            //            nsDateFormatter.dateFormat = "EEE MMM d yyy HH:mm:ss OOOO (zzz)"
            nsDateFormatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyy"
            
            nsDateFormatter.timeZone = NSTimeZone.localTimeZone()
            let dateForJson = nsDateFormatter.stringFromDate(entry.date)
            
            let dict: NSDictionary = ["color" : color, "date" : dateForJson, "filtered" : entry.sgv!.filtered, "noise": entry.sgv!.noise.rawValue, "sgv" : entry.sgv!.sgv, "type" : entry.type!.rawValue, "unfiltered" : entry.sgv!.unfiltered, "y" : entry.sgv!.sgv, "direction" : entry.sgv!.direction.rawValue]
            
            return dict
        }
    }
    
    init(identifier: String, date: NSDate, device: String) {//, type: Type) {
        self.idString = identifier
        self.date = date
        self.device = device
        //        self.type = type
    }
    
}

extension Entry {
    convenience init(jsonDictionary: [String:AnyObject]) {
        
        let dict = jsonDictionary
        
        var idString: String = ""
        var date: NSDate = NSDate()
        var device: String = ""
        //        var type: Type = Type.unknown("Not Set Yet")
        
        var sgvItem: SensorGlucoseValue?
        var calItem: Calibration?
        var meterItem: MeterBloodGlucose?
        
        var typed: TypedString?
        
        if let rawEpoch = dict[EntryPropertyKey.dateKey] as? Double {
            date = rawEpoch.toDateUsingSeconds() // NSDate(timeIntervalSince1970: rawEpoch/1000)// TODO://Link up with other extension.
            
            if let stringForType = dict[EntryPropertyKey.typeKey] as? String {
                if let typedString: TypedString = TypedString(rawValue: stringForType) {
                    typed = typedString
                    switch typedString {
                    case .sgv:
                        if let directionString = dict[EntryPropertyKey.directionKey] as? String {
                            if let direction = Direction(rawValue: directionString) {
                                if let sgv = dict[EntryPropertyKey.sgvKey] as? Int {
                                    if let filtered = dict[EntryPropertyKey.filteredKey] as? Int {
                                        if let unfiltlered = dict[EntryPropertyKey.unfilteredKey] as? Int {
                                            if let rssi = dict[EntryPropertyKey.rssiKey] as? Int {
                                                if let noiseInt = dict[EntryPropertyKey.noiseKey] as? Int {
                                                    if let noise = Noise(rawValue: noiseInt) {
                                                        let sgvValue = SensorGlucoseValue(sgv: sgv, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: rssi, noise: noise)
                                                        //                                                        type = Type.sgv(sgvValue)
                                                        sgvItem = sgvValue
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        
                    case .mbg:
                        if let mbg = dict[EntryPropertyKey.mgbKey] as? Int {
                            let meter = MeterBloodGlucose(mbg: mbg)
                            //                            type = Type.mbg(meter)
                            meterItem = meter
                        }
                        
                    case .cal:
                        if let slope = dict[EntryPropertyKey.slopeKey] as? Double {
                            if let intercept = dict[EntryPropertyKey.interceptKey] as? Double {
                                if let scale = dict[EntryPropertyKey.scaleKey] as? Double {
                                    let calValue = Calibration(slope: slope, scale: scale, intercept: intercept)
                                    //                                    type = Type.cal(calValue)
                                    calItem = calValue
                                }
                            }
                        }
                        
                    default:
                        println("something else")
                    }
                }
                
                
            }
            
        }
        self.init(identifier: idString, date: date, device:device)//, type: type)
        
        self.sgv = sgvItem
        self.mbg = meterItem
        self.cal = calItem
        
        self.type = typed
        
        if (sgvItem != nil) && (calItem != nil){
            self.raw = rawIsigToRawBg(sgvItem!, calValue: calItem!)
        }
        
    }
    
    
    func rawIsigToRawBg(sgValue: SensorGlucoseValue, calValue: Calibration) -> Double {
        
        var raw: Double = 0
        
        let slope = calValue.slope
        let unfiltered: Double = Double(sgValue.unfiltered)
        let filtered: Double = Double(sgValue.filtered)
        let sgv: Double = Double(sgValue.sgv)
        let scale: Double = Double(calValue.scale)
        let intercept = calValue.intercept
        
        if (slope == 0 || unfiltered == 0 || scale == 0) {
            raw = 0;
        } else if (filtered == 0 || sgv < 40) {
            raw = scale * (unfiltered - intercept) / slope
        } else {
            let ratioCalc1 = scale * (filtered - intercept) / slope
            let ratio = ratioCalc1 / sgv
            
            //FIXME:// there is divid by zero happining here... need to recheck the math.
            // Fixed but could it be cleaner?
            let rawCalc = scale * (unfiltered - intercept) / slope
            raw = rawCalc / ratio
        }
        
        return round(Double(raw))
    }
    
}

