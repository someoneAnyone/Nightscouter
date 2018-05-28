//
//  Chartable.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public protocol Chartable {
    var chartDictionary: String { get }
    var chartColor: String { get }
    var chartDateFormatter: DateFormatter { get }
    var jsonForChart: String { get }
}

struct ChartPoint: Codable {
    let color: String
    let date: Date
    let filtered: Double
    let noise: Noise
    let sgv: MgdlValue
    let type: String
    let unfiltered: Double
    let y: Double
    let direction: Direction
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
//        do {
//        let jsObj =  try JSONSerialization.data(withJSONObject: chartDictionary, options:[])
//            guard let str = String(bytes: jsObj, encoding: .utf8) else {
//                return ""
//            }
//
//            return str
//        } catch {
//            print(error)
//            return ""
//        }
        return chartDictionary
    }
}

extension SensorGlucoseValue: Chartable {
    public var chartDictionary: String {
        get{
            let entry: SensorGlucoseValue = self
            // let dateForJson = chartDateFormatter.string(from: entry.date)
            
            let chartObject = ChartPoint(color: chartColor, date: entry.date, filtered: entry.filtered ?? 0, noise: entry.noise ?? .none, sgv: entry.mgdl, type: "sgv", unfiltered: entry.unfiltered ?? 0, y: entry.mgdl, direction: entry.direction ?? .none)
            let jsonEncorder = JSONEncoder()
            jsonEncorder.dateEncodingStrategy = .formatted(chartDateFormatter)
            let item = try! jsonEncorder.encode(chartObject.self)
            
            return String(data: item, encoding: .utf8) ?? "{}"
        }
    }
}
