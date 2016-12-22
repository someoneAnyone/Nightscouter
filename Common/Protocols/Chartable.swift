//
//  Chartable.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public protocol Chartable {
    var chartDictionary: NSDictionary { get }
    var chartColor: String { get }
    var chartDateFormatter: DateFormatter { get }
    var jsonForChart: String { get }
}

extension Chartable {
    public var chartColor: String {
        return "grey"
    }
    public var chartDateFormatter: DateFormatter {
        let nsDateFormatter = DateFormatter()
        nsDateFormatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyy"
        nsDateFormatter.timeZone = TimeZone.autoupdatingCurrent
        nsDateFormatter.locale = Locale(identifier: "en_US")
        return nsDateFormatter
    }
    
    public var jsonForChart: String {
        let jsObj =  try? JSONSerialization.data(withJSONObject: chartDictionary, options:[])
        
        guard let jsObjSafe = jsObj, let str = String(bytes: jsObjSafe, encoding: .utf8) else {
            return ""
        }
        
        return str
    }
}

extension SensorGlucoseValue: Chartable {
    public var chartDictionary: NSDictionary {
        get{
            let entry: SensorGlucoseValue = self
            let dateForJson = chartDateFormatter.string(from: entry.date)
            let dict: NSDictionary = ["color" : chartColor, "date" : dateForJson, "filtered" : entry.filtered, "noise": entry.noise.rawValue, "sgv" : entry.mgdl, "type" : "sgv", "unfiltered" : entry.unfiltered, "y" : entry.mgdl, "direction" : entry.direction.rawValue]
            
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
