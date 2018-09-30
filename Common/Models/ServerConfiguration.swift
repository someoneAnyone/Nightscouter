//
//  ServerConfiguration.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/11/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public struct ServerConfiguration: Codable, CustomStringConvertible {
    public let status: String
    public let version: String
    public let name: String
    public let serverTime: String
    public let apiEnabled: Bool
    public let careportalEnabled: Bool
    public let boluscalcEnabled: Bool
    public let settings: Settings?
    
    public var description: String {
        var dict = [String: Any]()
        
        dict["status"] = status
        dict["apiEnabled"] = apiEnabled
        dict["serverTime"] = serverTime
        dict["careportalEnabled"] = careportalEnabled
        dict["boluscalcEnabled"] = boluscalcEnabled
        dict["settings"] = settings
        dict["version"] = version
        dict["name"] = name
        
        return dict.description
    }
    
    public init() {
        self.status = "okToTest"
        self.version = "0.0.0test"
        self.name = "NightscoutTest"
        self.serverTime = "2016-01-13T15:04:59.059Z"
        self.apiEnabled = true
        self.careportalEnabled = false
        self.boluscalcEnabled = false
        
        let placeholderAlarm1: [Double] = [15, 30, 45, 60]
        let placeholderAlarm2: [Double] = [30, 60, 90, 120]
        
        let alrm = Alarm(urgentHigh: true, urgentHighMins: placeholderAlarm2, high: true, highMins: placeholderAlarm2, low: true, lowMins: placeholderAlarm1, urgentLow: true, urgentLowMins: placeholderAlarm1, warnMins: placeholderAlarm2)
        let timeAgo = TimeAgoAlert(warn: true, warnMins: 60.0 * 10, urgent: true, urgentMins: 60.0 * 15)
        let plugins: [Plugin] = [Plugin.delta, Plugin.rawbg]

        let thre = Thresholds(bgHigh: 300, bgLow: 70, bgTargetBottom: 60, bgTargetTop: 250)
        
        let s = Settings(units: .mgdl, showRawbg: .never, customTitle: "NightscoutDefault", alarmUrgentHigh: true, alarmUrgentHighMins: alrm.urgentLowMins, alarmHigh: alrm.urgentHigh, alarmHighMins: alrm.warnMins, alarmLow: alrm.low, alarmLowMins: alrm.lowMins, alarmUrgentLow: alrm.urgentLow, alarmUrgentLowMins: alrm.urgentLowMins, alarmWarnMins: alrm.warnMins, alarmTimeagoWarn: timeAgo.warn, alarmTimeagoWarnMins: timeAgo.urgentMins, alarmTimeagoUrgent: timeAgo.urgent, alarmTimeagoUrgentMins: timeAgo.urgentMins, thresholds: thre, enable: plugins)
        self.settings = s

    }
    
    public init(status: String, version: String, name: String, serverTime: String, api: Bool, carePortal: Bool, boluscalc: Bool, settings: Settings?, head: String) {
        self.status = status
        self.version = version
        self.name = name
        self.serverTime = serverTime
        self.apiEnabled = api
        self.careportalEnabled = carePortal
        self.boluscalcEnabled = boluscalc
        self.settings = settings
    }
}

extension ServerConfiguration: Equatable { }
public func ==(lhs: ServerConfiguration, rhs: ServerConfiguration) -> Bool {
    return lhs.status == rhs.status &&
        lhs.version == rhs.version &&
        lhs.name == rhs.name &&
        lhs.serverTime == rhs.serverTime &&
        lhs.apiEnabled == rhs.apiEnabled &&
        lhs.careportalEnabled == rhs.careportalEnabled &&
        lhs.boluscalcEnabled == rhs.boluscalcEnabled &&
        lhs.settings == rhs.settings
}

extension ServerConfiguration {
    public var displayName: String {
        if let settings = settings {
            return settings.customTitle
        } else {
            return name
        }
    }
    
    public var displayRawData: Bool {
        if let settings = settings {
            let rawEnabled = settings.enable.contains(Plugin.rawbg)
            if rawEnabled {
                switch settings.showRawbg {
                case .noise:
                    return true
                case .always:
                    return true
                case .never:
                    return false
                }
                
            }
        }
        return false
        
    }
    
    public var displayUnits: GlucoseUnit {
        if let settings = settings {
            return settings.units
        }
        return .mgdl
    }
}

public struct Settings: Codable {
    public let units: GlucoseUnit

    public let showRawbg: RawBGMode
    public let customTitle: String

    public var alarms: Alarm {
        return Alarm(urgentHigh: alarmUrgentHigh, urgentHighMins: alarmUrgentHighMins, high: alarmHigh, highMins: alarmHighMins, low: alarmLow, lowMins: alarmLowMins, urgentLow: alarmUrgentLow, urgentLowMins: alarmUrgentLowMins, warnMins: alarmWarnMins)
    }
    
    public let alarmUrgentHigh: Bool
    public let alarmUrgentHighMins: [Double]
    public let alarmHigh: Bool
    public let alarmHighMins: [Double]
    public let alarmLow: Bool
    public let alarmLowMins: [Double]
    public let alarmUrgentLow: Bool
    public let alarmUrgentLowMins: [Double]
    public let alarmWarnMins: [Double]
    public let alarmTimeagoWarn: Bool
    public var alarmTimeagoWarnMins: Double = 15
    public let alarmTimeagoUrgent: Bool
    public var alarmTimeagoUrgentMins: Double = 30
    
    public var timeAgo: TimeAgoAlert {
        return TimeAgoAlert(warn: alarmTimeagoWarn, warnMins: TimeInterval(alarmTimeagoWarnMins * 10), urgent: alarmTimeagoUrgent, urgentMins: TimeInterval(alarmTimeagoUrgentMins * 10))
    }

    public let thresholds: Thresholds
    public let enable: [Plugin]
    
}

extension Settings {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
       
        units = try values.decode(GlucoseUnit.self, forKey: .units)
        showRawbg = try values.decode(RawBGMode.self, forKey: .showRawbg)
        customTitle = try values.decode(String.self, forKey: .customTitle)
        
        alarmUrgentHigh = try values.decode(Bool.self, forKey: .alarmUrgentHigh)
        alarmUrgentHighMins = try values.decode([Double].self, forKey: .alarmUrgentHighMins)
        alarmHigh = try values.decode(Bool.self, forKey: .alarmHigh)
        alarmHighMins = try values.decode([Double].self, forKey: .alarmHighMins)
        alarmLow = try values.decode(Bool.self, forKey: .alarmLow)
        alarmLowMins = try values.decode([Double].self, forKey: .alarmLowMins)
        alarmUrgentLow = try values.decode(Bool.self, forKey: .alarmUrgentLow)
        alarmUrgentLowMins  = try values.decode([Double].self, forKey: .alarmUrgentLowMins)
        alarmWarnMins = try values.decode([Double].self, forKey: .alarmWarnMins)
        alarmTimeagoWarn = try values.decode(Bool.self, forKey: .alarmTimeagoWarn)
        alarmTimeagoUrgent = try values.decode(Bool.self, forKey: .alarmTimeagoUrgent)
        
        do {
            alarmTimeagoWarnMins = try values.decode(Double.self, forKey: .alarmTimeagoWarnMins) * 10
        } catch {
            alarmTimeagoWarnMins = 15
        }
        
        do {
            alarmTimeagoUrgentMins = try values.decode(Double.self, forKey: .alarmTimeagoUrgentMins) * 10
        } catch {
            alarmTimeagoUrgentMins = 30
        }
        
        thresholds = try values.decode(Thresholds.self, forKey: .thresholds)
        enable = try values.decode([Plugin].self, forKey: .enable)
    }
}

extension Settings: Equatable {}
public func ==(lhs: Settings, rhs: Settings) -> Bool {
    return lhs.units == rhs.units &&
        lhs.customTitle == rhs.customTitle &&
        lhs.alarms == rhs.alarms &&
        lhs.timeAgo == rhs.timeAgo &&
        lhs.enable == rhs.enable &&
        lhs.thresholds == rhs.thresholds
}

public enum Plugin: String, Codable, CustomStringConvertible, RawRepresentable {
    case careportal
    case rawbg
    case iob
    case ar2
    case treatmentnotify
    case delta
    case direction
    case upbat
    case errorcodes
    case simplealarms
    case pushover
    case maker
    case cob
    case bwp
    case cage
    case basal
    case profile
    case timeago
    case alexa
    case bridge, bgnow, devicestatus, boluscalc, food, sage, iage, mmconnect, pump, openaps, loop, cors
    
    public var description: String {
        return self.rawValue
    }
}

public enum GlucoseUnit: String, Codable, RawRepresentable, CustomStringConvertible {
    case mgdl = "mg/dL"
    case mmol = "mmol"
    
    public init() {
        self = .mgdl
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case GlucoseUnit.mmol.rawValue, "mmol/L":
            self = .mmol
        default:
            self = .mgdl
        }
    }
    
    public var description: String {
        switch self {
        case .mgdl:
            return "mg/dL"
        case .mmol:
            return "mmol/L"
        }
    }
    
    public var descriptionShort: String {
        switch self {
        case .mgdl:
            return "mg"
        case .mmol:
            return "mmol"
        }
    }
}
// Need to re-evaluate how we treat Glucose units and conversion within the app.

@available(iOS 10.0, *)
extension GlucoseUnit {
    @available(watchOSApplicationExtension 3.0, *)
    public var unit: UnitConcentrationMass {
        switch self {
        case .mgdl:
            return .milligramsPerDeciliter
        case .mmol:
            return .millimolesPerLiter(withGramsPerMole: 0.01)
        }
    }
    
}

public enum RawBGMode: String, Codable, RawRepresentable, CustomStringConvertible {
    case never = "never"
    case always = "always"
    case noise = "noise"
    
    public init() {
        self = .never
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case RawBGMode.always.rawValue:
            self = .always
        case RawBGMode.noise.rawValue:
            self = .noise
        default:
            self = .never
        }
    }
    
    public var description: String {
        return self.rawValue
    }
}

public struct Thresholds: Codable, CustomStringConvertible {
    public let bgHigh: Double
    public let bgLow: Double
    public let bgTargetBottom :Double
    public let bgTargetTop :Double
    
    public var description: String {
        let dict = ["bgHigh": bgHigh, "bgLow": bgLow, "bgTargetBottom": bgTargetBottom, "bgTargetTop": bgTargetTop]
        return dict.description
    }
    
    public init() {
        self.bgHigh = 300
        self.bgLow = 60
        self.bgTargetBottom = 70
        self.bgTargetTop = 250
    }
    
    public init(bgHigh: Double? = 300, bgLow: Double? = 60, bgTargetBottom: Double? = 70, bgTargetTop: Double? = 250) {
        guard let bgHigh = bgHigh, let bgLow = bgLow, let bgTargetTop = bgTargetTop, let bgTargetBottom = bgTargetBottom else {
            self = Thresholds()
            return
        }
        
        self.bgHigh = bgHigh
        self.bgLow = bgLow
        self.bgTargetBottom = bgTargetBottom
        self.bgTargetTop = bgTargetTop
    }
}

extension Thresholds: ColorBoundable {
    public var bottom: Double { return self.bgLow }
    public var targetBottom: Double { return self.bgTargetBottom }
    public var targetTop: Double { return self.bgTargetTop }
    public var top: Double { return self.bgHigh }
}

extension Thresholds: Equatable {}
public func ==(lhs: Thresholds, rhs: Thresholds) -> Bool {
    return lhs.bottom == rhs.bottom &&
        lhs.targetBottom == rhs.targetBottom &&
        lhs.targetTop == rhs.targetTop &&
        lhs.top == rhs.top
}

public struct Alarm: Codable, CustomStringConvertible {
    public let urgentHigh: Bool
    public let urgentHighMins: [Double]
    public let high: Bool
    public let highMins: [Double]
    public let low: Bool
    public let lowMins: [Double]
    public let urgentLow: Bool
    public let urgentLowMins: [Double]
    public let warnMins: [Double]
    
    public var description: String {
        let dict = ["urgentHigh": urgentHigh, "urgentHighMins": urgentHighMins, "high": high, "highMins": highMins, "low": low, "lowMins": lowMins, "urgentLow": urgentLow, "urgentLowMins": urgentLowMins, "warnMins": warnMins] as [String : Any]
        return dict.description
    }
}

extension Alarm : Equatable {}
public func ==(lhs: Alarm, rhs: Alarm) -> Bool {
    return lhs.urgentHigh == rhs.urgentHigh &&
        lhs.urgentHighMins == rhs.urgentHighMins &&
        lhs.high == rhs.high &&
        lhs.highMins == rhs.highMins &&
        lhs.low == rhs.low &&
        lhs.lowMins == rhs.lowMins &&
        lhs.urgentLow == rhs.urgentLow &&
        lhs.urgentLowMins == rhs.urgentLowMins &&
        lhs.warnMins == rhs.warnMins
}



public enum AlarmType: String, Codable, CustomStringConvertible {
    case predict
    case simple
    
    init() {
        self = .predict
    }
    
    public var description: String {
        return self.rawValue
    }
}

public struct TimeAgoAlert: Codable, CustomStringConvertible {
    public let warn: Bool
    public let warnMins: TimeInterval
    public let urgent: Bool
    public let urgentMins: TimeInterval
    
    public var description: String {
        let dict = ["warn": warn, "warnMins": warnMins, "urgent": urgent, "urgentMins": urgentMins] as [String : Any]
        return dict.description
    }
}

public extension TimeAgoAlert {
    public func isDataStaleWith(interval sinceNow: TimeInterval) -> (warn: Bool, urgent: Bool) {
        return isDataStaleWith(interval: sinceNow, warn: self.warnMins, urgent: self.urgentMins)
    }
    
    private func isDataStaleWith(interval sinceNow: TimeInterval, warn: TimeInterval, urgent: TimeInterval, fallback: TimeInterval = TimeInterval(600)) -> (warn: Bool, urgent: Bool) {
        
        let warnValue: TimeInterval = -max(fallback, warn)
        let urgentValue: TimeInterval = -max(fallback, urgent)
        let returnValue = (sinceNow < warnValue, sinceNow < urgentValue)
        
        #if DEBUG
            // print("\(__FUNCTION__): {sinceNow: \(sinceNow), warneValue: \(warnValue), urgentValue: \(urgentValue), fallback:\(-fallback), returning: \(returnValue)}")
        #endif
        
        return returnValue
    }
    
}

extension TimeAgoAlert: Equatable {}
public func ==(lhs: TimeAgoAlert, rhs: TimeAgoAlert) -> Bool {
    return lhs.warn == rhs.warn &&
        lhs.warnMins == rhs.warnMins &&
        lhs.urgent == rhs.urgent &&
        lhs.urgentMins == rhs.urgentMins
}
