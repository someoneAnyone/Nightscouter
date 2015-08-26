//
//  Entry.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

let NightscoutModelErrorDomain: String = "com.nightscout.nightscouter.models.entry"

// TODO: Clean these up.
public enum Direction : String, Printable {
    case None = "None", DoubleUp = "DoubleUp", SingleUp = "SingleUp", FortyFiveUp = "FortyFiveUp", Flat = "Flat", FortyFiveDown = "FortyFiveDown", SingleDown = "SingleDown", DoubleDown = "DoubleDown", NotComputable = "NOT COMPUTABLE", RateOutOfRange = "RateOutOfRange"
    
    public static let allValues = [None, DoubleUp, SingleUp, FortyFiveUp, Flat, FortyFiveDown, SingleDown, DoubleDown, NotComputable, RateOutOfRange]
    
    public var description : String {
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
    
    public var emojiForDirection : String {
        get {
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
    }
    
    public func directionForString(directionString: String) -> Direction {
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

public enum Noise : Int, Printable {
    case None = 0, Clean = 1, Light = 2, Medium = 3, Heavy = 4
    public var description: String {
        switch (self) {
        case .None: return "---"
        case .Clean: return "Clean"
        case .Light: return "Light"
        case .Medium: return "Medium"
        case .Heavy: return "Heavy"
        }
    }
}

public enum Type: String {
    case sgv = "sgv"
    case cal = "cal"
    case mbg = "mbg"
    case serverforecast = "server-forecast"
    case none = "None"
    
    public init(){
        self = .none
    }
}

// TODO: Add known devices and convert over to enum for future feature checking.
public enum Device: String {
    case Unknown = "unknown"
    case Dexcom = "dexcom"
    case xDripDexcomShare = "xDrip-DexcomShare"
    case WatchFace = "watchFace"
    case Share2 = "share2"
}

// type = cal
public struct Calibration {
    public let slope: Double
    public let scale: Double
    public let intercept: Double
}

// type = sgv
public struct SensorGlucoseValue {
    public let sgv: Double
    public let direction: Direction
    public let filtered: Int
    public let unfiltered: Int
    public let rssi: Int
    public let noise: Noise
    
    enum ReservedValues: Double {
        case NoGlucose=0, SensoreNotActive=1, MinimalDeviation=2, NoAntenna=3, SensorNotCalibrated=5, CountsDeviation=6, AbsoluteDeviation=9, PowerDeviation=10, BadRF=12, HupHolland=17
    }
    
    public var sgvString: String { // Consider moving this to a Printable or similar protocal?
        get {

            let mgdlSgvValue: Double = sgv.isInteger ? sgv : sgv.toMgdl

            if let special:ReservedValues = ReservedValues(rawValue: mgdlSgvValue) {
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
                case .BadRF:
                    return "?RF✖"
                case .HupHolland:
                    return "MH"
                default:
                    return "✖"
                }
            }
            if sgv >= 30 && sgv < 40 {
                return NSLocalizedString("sgvLowString", tableName: nil, bundle:  NSBundle.mainBundle(), value: "", comment: "Label used to indicate a very low blood sugar.")
            }
            return NSNumberFormatter.localizedStringFromNumber(self.sgv, numberStyle: NSNumberFormatterStyle.DecimalStyle)
        }
    }
}

// type = mgb
public struct MeterBloodGlucose {
    public let mbg: Int
}

public class Entry: NSObject {
    public var idString: String
    public var device: String
    public var date: NSDate
    public var dateTimeAgoString: String {
        get{
            return NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(date)
        }
    }
    public var dateString: String?
    public var sgv: SensorGlucoseValue?
    public var cal: Calibration?
    public var mbg: MeterBloodGlucose?
    public var raw: Double?
    public var type: Type?
    
    public var dictionaryRep: NSDictionary {
        get{
            let entry: Entry = self
            
            var color: String = "white"
            let typeString: Type = entry.type!
            
            switch(typeString) {
            case .sgv:
                color = "grey"
            case .mbg:
                color = "red"
            case .cal:
                color = "yellow"
            case .serverforecast:
                color = "blue"
            default:
                color = "grey"
            }
            
            let nsDateFormatter = NSDateFormatter()
            // nsDateFormatter.dateFormat = "EEE MMM d yyy HH:mm:ss OOOO (zzz)"
            nsDateFormatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyy"
            
            nsDateFormatter.timeZone = NSTimeZone.localTimeZone()
            let dateForJson = nsDateFormatter.stringFromDate(entry.date)
            
            let dict: NSDictionary = ["color" : color, "date" : dateForJson, "filtered" : entry.sgv!.filtered, "noise": entry.sgv!.noise.rawValue, "sgv" : entry.sgv!.sgv, "type" : entry.type!.rawValue, "unfiltered" : entry.sgv!.unfiltered, "y" : entry.sgv!.sgv, "direction" : entry.sgv!.direction.rawValue]
            
            return dict
        }
    }
    
    public var jsonForChart: String {
        let jsonError: NSError?
        let jsObj =  NSJSONSerialization.dataWithJSONObject(self.dictionaryRep, options:nil, error:nil)
        let str = NSString(data: jsObj!, encoding: NSUTF8StringEncoding)
        return String(str!)
    }
    
    public init(identifier: String, date: NSDate, device: String) {
        self.idString = identifier
        self.date = date
        self.device = device
    }
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
    static let identKey = "_id"
    static let deviceKey = "device"
    static let dateStringKey = "dateString"
}

public extension Entry {
    
    public convenience init(jsonDictionary: [String: AnyObject]) {
        
        let dict = jsonDictionary
        
        var idString: String = ""
        var date: NSDate = NSDate()
        var device: String = ""
        
        var sgvItem: SensorGlucoseValue?
        var calItem: Calibration?
        var meterItem: MeterBloodGlucose?
        
        var type: Type = Type()
        
        if let identifier = dict[EntryPropertyKey.identKey] as? String {
            idString = identifier
        }
        
        if let deviceString = dict[EntryPropertyKey.deviceKey] as? String {
            device = deviceString
        }
        
        var dateString: String = ""
        if let dateStringOptional = dict[EntryPropertyKey.dateStringKey] as? String {
            dateString = dateStringOptional
        }
        
        if let rawEpoch = dict[EntryPropertyKey.dateKey] as? Double {
            date = rawEpoch.toDateUsingSeconds()
        }
        if let stringForType = dict[EntryPropertyKey.typeKey] as? String {
            if let typedString: Type = Type(rawValue: stringForType) {
                type = typedString
                switch type {
                case .sgv:
                    
                    sgvItem = SensorGlucoseValue(sgv: 0, direction: .None, filtered: 0, unfiltered: 0, rssi: 0, noise: .None)
                    
                    if let directionString = dict[EntryPropertyKey.directionKey] as? String {
                        if let direction = Direction(rawValue: directionString) {
                            sgvItem?.direction = direction
                        }
                    }
                    
                    if let sgv = dict[EntryPropertyKey.sgvKey] as? Double {
                        sgvItem?.sgv = sgv
                    }
                    
                    if let filtered = dict[EntryPropertyKey.filteredKey] as? Int {
                        sgvItem?.filtered = filtered
                    }
                    
                    if let unfiltlered = dict[EntryPropertyKey.unfilteredKey] as? Int {
                        sgvItem?.unfiltered = unfiltlered
                    }
                    
                    if let rssi = dict[EntryPropertyKey.rssiKey] as? Int {
                        sgvItem?.rssi = rssi
                    }
                    
                    if let noiseInt = dict[EntryPropertyKey.noiseKey] as? Int {
                        if let noise = Noise(rawValue: noiseInt) {
                            sgvItem?.noise = noise
                        }
                    }
                    
                case .mbg:
                    if let mbg = dict[EntryPropertyKey.mgbKey] as? Int {
                        let meter = MeterBloodGlucose(mbg: mbg)
                        meterItem = meter
                    }
                    
                case .cal:
                    if let slope = dict[EntryPropertyKey.slopeKey] as? Double {
                        if let intercept = dict[EntryPropertyKey.interceptKey] as? Double {
                            if let scale = dict[EntryPropertyKey.scaleKey] as? Double {
                                let calValue = Calibration(slope: slope, scale: scale, intercept: intercept)
                                calItem = calValue
                            }
                        }
                    }
                    
                default:
                    let errorString: String = "I have encountered a nightscout recorded type I don't know\ntype:\(typedString)"
                    #if DEBUG
                        println(errorString)
                    #endif
                    NSError(domain: NightscoutModelErrorDomain, code: -10, userInfo: ["description": errorString])
                }
            }
        } else {
            let errorString: String = "Type feild is missing for \(dict)"
            #if DEBUG
                println(errorString)
            #endif
            NSError(domain: NightscoutModelErrorDomain, code: -11, userInfo: ["description": errorString])
            sgvItem = SensorGlucoseValue(sgv: 0, direction: .None, filtered: 0, unfiltered: 0, rssi: 0, noise: .None)

            if let sgv = dict[EntryPropertyKey.sgvKey] as? Double {
                sgvItem?.sgv = sgv
            }
            
            if let sgv = dict[EntryPropertyKey.sgvKey] as? String {
                sgvItem?.sgv = sgv.toDouble!
            }

            if let directionString = dict[EntryPropertyKey.directionKey] as? String {
                if let direction = Direction(rawValue: directionString) {
                    sgvItem?.direction = direction
                }
            }
        }
        
        self.init(identifier: idString, date: date, device:device)//, type: type)
        
        self.dateString = dateString
        self.sgv = sgvItem
        self.mbg = meterItem
        self.cal = calItem
        
        self.type = type
        
        if (sgvItem != nil) && (calItem != nil){
            self.raw = rawIsigToRawBg(sgvItem!, calValue: calItem!)
        }
    }
}

// TODO: fix this!
// TODO: Is tihs the best it can be? Should it be a cumputed property?
public extension Entry {
    public func rawIsigToRawBg(sgValue: SensorGlucoseValue, calValue: Calibration) -> Double {
        
        var raw: Double = 0
        
        let unfiltered = Double(sgValue.unfiltered)
        let filtered = Double(sgValue.filtered)
        let sgv: Double = sgValue.sgv.isInteger ? sgValue.sgv : sgValue.sgv.toMgdl
        let slope = calValue.slope
        let scale = calValue.scale
        let intercept = calValue.intercept
        
        if (slope == 0 || unfiltered == 0 || scale == 0) {
            raw = 0;
        } else if (filtered == 0 || sgv < 40) {
            raw = scale * (unfiltered - intercept) / slope
        } else {
            let ratioCalc = scale * (filtered - intercept) / slope
            let ratio = ratioCalc / sgv
            
            //FIXME: there is divid by zero happining here... need to recheck the math.
            // Fixed but could it be cleaner?
            let rawCalc = scale * (unfiltered - intercept) / slope
            raw = rawCalc / ratio
        }
        
        return sgValue.sgv.isInteger ? round(raw) : raw
    }
}