//
//  Entry.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

//let NightscoutModelErrorDomain: String = "com.nightscout.nightscouter.models.entry"

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

public enum Type: String, CustomStringConvertible {
    case Sgv = "sgv", Cal = "cal", Mbg = "mbg", ServerForecast = "server-forecast", None = "None"
    
    public var description: String {
        return self.rawValue
    }
    
    public init() {
        self = .None
    }
}

public class Entry: DictionaryConvertible {
    public var identifier: String
    public var device: Device
    
    public var date: NSDate
    
    public var dateTimeAgoString: String {
        get{
            return NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(date)
        }
    }
    public var dateTimeAgoStringShort: String {
        get{
            
            let shorterTimeAgo = dateTimeAgoString.componentsSeparatedByString(" ").dropLast()
            var finalString: String = ""
            
            for stringPart in shorterTimeAgo {
                finalString += " " + stringPart
            }
            return "\(finalString)"
        }
    }
    public var dateString: String?
    
    public var sgv: SensorGlucoseValue?
    public var cal: Calibration?
    public var mbg: MeterBloodGlucose?
    
    public var type: Type
    
    public init(identifier: String, date: NSDate, device: Device) {
        self.identifier = identifier
        self.date = date
        self.device = device
        self.type = Type()
    }
    
    public init(identifier: String, date: NSDate, device: Device, dateString: String, sgv: SensorGlucoseValue?, cal: Calibration?, mbg: MeterBloodGlucose?, type: Type) {
        self.identifier = identifier
        self.date = date
        self.device = device
        self.dateString = dateString
        self.sgv = sgv
        self.cal = cal
        self.mbg = mbg
        self.type = type
    }
}

public extension Entry {
    
    public var chartDictionary: NSDictionary {
        get{
            let entry: Entry = self
            
            var color: String = "white"
            let typeString: Type = entry.type
            
            switch(typeString) {
            case .Sgv:
                color = "grey"
            case .Mbg:
                color = "red"
            case .Cal:
                color = "yellow"
            case .ServerForecast:
                color = "blue"
            default:
                color = "grey"
            }
            
            let nsDateFormatter = NSDateFormatter()
            // nsDateFormatter.dateFormat = "EEE MMM d yyy HH:mm:ss OOOO (zzz)"
            nsDateFormatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyy"
            
            nsDateFormatter.timeZone = NSTimeZone.localTimeZone()
            let dateForJson = nsDateFormatter.stringFromDate(entry.date)
            
            let dict: NSDictionary = ["color" : color, "date" : dateForJson, "filtered" : entry.sgv!.filtered, "noise": entry.sgv!.noise.rawValue, "sgv" : entry.sgv!.sgv, "type" : entry.type.rawValue, "unfiltered" : entry.sgv!.unfiltered, "y" : entry.sgv!.sgv, "direction" : entry.sgv!.direction.rawValue]
            
            return dict
        }
    }
    
    public var jsonForChart: String {
        let jsObj =  try? NSJSONSerialization.dataWithJSONObject(self.chartDictionary, options:[])
        let str = NSString(data: jsObj!, encoding: NSUTF8StringEncoding)
        return String(str!)
    }
}


public extension Entry {
    
    public convenience init(jsonDictionary: [String: AnyObject]) {
        
        let dict = jsonDictionary
        
        guard let identifier = dict[EntryPropertyKey.identKey] as? String,
            deviceString = dict[EntryPropertyKey.deviceKey] as? String,
            rawEpoch = dict[EntryPropertyKey.dateKey] as? Double else {

                self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: Device())
                return
        }

        let device: Device = Device(rawValue: deviceString) ?? .Unknown
        let date = rawEpoch.toDateUsingSeconds()
        
        let dateString = dict[EntryPropertyKey.dateStringKey] as? String
        
        guard let stringForType = dict[EntryPropertyKey.typeKey] as? String,
            type: Type = Type(rawValue: stringForType) else {
                
                self.init(identifier: NSUUID().UUIDString, date: NSDate(), device: Device())
                
                return
        }
        
        var sgValue: SensorGlucoseValue! = nil
        var calValue: Calibration! = nil
        var mbgValue: MeterBloodGlucose! = nil
        
        switch type {
        case .Sgv:
            
            var sgvDouble: Double = 0
            if let sgv = dict[EntryPropertyKey.sgvKey] as? Double {
                sgvDouble = sgv
            } else if let sgv = dict[EntryPropertyKey.sgvKey] as? String {
                sgvDouble = sgv.toDouble!
            }

            guard let directionString = dict[EntryPropertyKey.directionKey] as? String,
                direction = Direction(rawValue: directionString) else {
            
                    break
            }
        
            var filtered: Int = 0
            var unfiltlered: Int = 0
            var rssi: Int = 0
        if let  filt = dict[EntryPropertyKey.filteredKey] as? Int,
            unfilt = dict[EntryPropertyKey.unfilteredKey] as? Int,
            rss = dict[EntryPropertyKey.rssiKey] as? Int {

                filtered = filt
                unfiltlered = unfilt
                rssi = rss
        }
        
        
            var noise = Noise.None
            if let noiseInt = dict[EntryPropertyKey.noiseKey] as? Int,
                noiseType = Noise(rawValue: noiseInt) {
                    
                    noise = noiseType
            }
            
            sgValue = SensorGlucoseValue(sgv: sgvDouble, direction: direction, filtered: filtered, unfiltered: unfiltlered, rssi: rssi, noise: noise)
            
        case .Mbg:
            guard let mbg = dict[EntryPropertyKey.mgbKey] as? Int else {
                break
            }
            mbgValue = MeterBloodGlucose(mbg: mbg)
            
        case .Cal:
            guard let slope = dict[EntryPropertyKey.slopeKey] as? Double,
                intercept = dict[EntryPropertyKey.interceptKey] as? Double,
                let scale = dict[EntryPropertyKey.scaleKey] as? Double else {
                    break
            }
            
            calValue = Calibration(slope: slope, scale: scale, intercept: intercept, date:  date)

        default:
            let errorString: String = "JSON: \(stringForType) has unknown type:\(type)"
            #if DEBUG
                print(errorString)
            #endif
            break
        }
        self.init(identifier: identifier, date: date, device:device, dateString: dateString!, sgv: sgValue, cal: calValue, mbg: mbgValue, type: type)
    }
}