//
//  Chartable.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public protocol Chartable {
    var chartDictionary: [String: AnyObject] { get }
    var chartColor: String { get }
    var chartDateFormatter: DateFormatter { get }
    var jsonForChart: String { get }
}

extension Chartable {
    public var chartColor: String {
        return "white"
    }
    public var chartDateFormatter: DateFormatter {
        let nsDateFormatter = DateFormatter()
        nsDateFormatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyy"
        nsDateFormatter.timeZone = TimeZone.autoupdatingCurrent

        return nsDateFormatter
    }
    
    public var jsonForChart: String {
        let jsObj =  try? JSONSerialization.data(withJSONObject: chartDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
        
//        let str = String(data: jsObj!, encoding: .utf8)
        let str = String(bytes: jsObj!, encoding: String.Encoding.utf8)
        
        return str!
    }
}

extension SensorGlucoseValue: Chartable {
    public var chartDictionary: [String: AnyObject] {
        get{
            let entry: SensorGlucoseValue = self
            let dateForJson = chartDateFormatter.string(from: entry.date)
            let dict: [String: AnyObject] = ["color" : chartColor as AnyObject, "date" : dateForJson as AnyObject, "filtered" : entry.filtered as AnyObject, "noise": entry.noise.rawValue as AnyObject, "sgv" : entry.mgdl as AnyObject, "type" : "sgv" as AnyObject, "unfiltered" : entry.unfiltered as AnyObject, "y" : entry.mgdl as AnyObject, "direction" : entry.direction.rawValue as AnyObject]
            
            return dict
        }
    }
}
/*
extension Calibration: Chartable {
    public var chartDictionary: [String: Any] {
        get{
            let entry: Calibration = self
            let dateForJson = chartDateFormatter.string(from: entry.date)
            let dict: [String: Any] = ["color" : chartColor, "date" : dateForJson, "slope" : entry.slope, "intercept": entry.intercept, "scale" : entry.scale]
            
            return dict
        }
    }
}

extension MeteredGlucoseValue: Chartable {
    public var chartDictionary: [String: Any] {
        get{
            let entry: MeteredGlucoseValue = self
            let dateForJson = chartDateFormatter.string(from: entry.date as Date)
            let dict: [String: Any] = ["color" : chartColor, "date" : dateForJson, "device" : entry.device.rawValue, "mgdl" : entry.mgdl]
            
            return dict
        }
    }
    
}
*/
