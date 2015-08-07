//
//  Settings.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

public enum EnabledOptions: String, Printable {
    case careportal = "careportal"
    case rawbg = "rawbg"
    case iob = "iob"
    case ar2 = "ar2"
    case treatmentnotify = "treatmentnotify"
    case delta = "delta"
    case direction = "direction"
    case upbat = "upbat"
    case errorcodes = "errorcodes"
    case simplealarms = "simplealarms"
    case pushover = "pushover"
    
    public var description: String {
        return self.rawValue
    }
}

public enum Units: String, Printable {
    case Mgdl = "mg/dl"
    case Mmoll = "mmol/L"
    
    public var description: String {
        return self.rawValue
    }
}

public enum RawBGMode: String, Printable {
    case Never = "never"
    case Always = "always"
    case Noise = "noise"
    
    public var description: String {
        return self.rawValue
    }
}

public struct Threshold: Printable {
    public let bg_high: Int
    public let bg_low: Int
    public let bg_target_bottom :Int
    public let bg_target_top :Int
    
    public var description: String {
        let dict = ["bg_high": bg_high, "bg_low": bg_low, "bg_target_bottom": bg_target_bottom, "bg_target_top": bg_target_top]
        return dict.description
    }
}

public struct Alarm: Printable {
    public let alarmHigh: Bool
    public let alarmLow: Bool
    public let alarmTimeAgoUrgent: Bool
    public let alarmTimeAgoUrgentMins: NSTimeInterval
    public let alarmTimeAgoWarn: Bool
    public let alarmTimeAgoWarnMins: NSTimeInterval
    public let alarmUrgentHigh: Bool
    public let alarmUrgentLow: Bool
    
    public var description: String {
        let dict = ["alarmHigh": alarmHigh, "alarmLow:": alarmLow, "alarmTimeAgoUrgent": alarmTimeAgoUrgentMins, "alarmTimeAgoWarn": alarmTimeAgoWarn, "alarmTimeAgoWarnMins": alarmTimeAgoWarnMins, "alarmUrgentHigh": alarmUrgentHigh, "alarmUrgentLow": alarmUrgentLow]
        return dict.description
    }
}

public enum AlarmTypes: String, Printable {
    case predict = "predict"
    case simple = "simple"
    
    public var description: String {
        return self.rawValue
    }
}

public struct Defaults: Printable {
    // Start of "defaults" dictionary
    public let units: Units
    public let timeFormat: Int
    public let nightMode: Bool
    public let showRawbg: RawBGMode
    public let customTitle: String
    public let theme: String
    public let alarms: Alarm
    public let language: String
    public let showPlugins: String? = nil
    // End of "defaults" dictionary
    
    public var description: String {
        let dict = ["units": units.description, "timeFormat": timeFormat, "nightMode": nightMode.description, "showRawbg": showRawbg.rawValue, "customTitle": customTitle, "theme": theme, "alarms": alarms.description, "language": language]
        return dict.description
    }
}

struct ConfigurationPropertyKey {
    static let alarm_typesKey = "alarm_types"
    static let apiEnabledKey = "apiEnabled"
    static let careportalEnabledKey = "careportalEnabled"
    static let defaultsKey = "defaults"
    static let alarmHighKey = "alarmHigh"
    static let alarmLowKey = "alarmLow"
    static let alarmTimeAgoUrgentKey = "alarmTimeAgoUrgent"
    static let alarmTimeAgoUrgentMinsKey = "alarmTimeAgoUrgentMins"
    static let alarmTimeAgoWarnKey = "alarmTimeAgoWarn"
    static let alarmTimeAgoWarnMinsKey = "alarmTimeAgoWarnMins"
    static let alarmUrgentHighKey = "alarmUrgentHigh"
    static let alarmUrgentLowKey = "alarmUrgentLow"
    static let customTitleKey = "customTitle"
    static let languageKey = "language"
    static let nightModeKey = "nightMode"
    static let showRawbgKey = "showRawbg"
    static let themeKey = "theme"
    static let timeFormatKey = "timeFormat"
    static let unitsKey = "units"
    static let enabledOptionsKey = "enabledOptions"
    static let headKey = "head"
    static let nameKey = "name"
    static let statusKey = "status"
    static let thresholdsKey = "thresholds"
    static let bg_highKey = "bg_high"
    static let bg_lowKey = "bg_low"
    static let bg_target_bottomKey = "bg_target_bottom"
    static let bg_target_topKey = "bg_target_top"
    static let versionKey = "version"
    static let extendedSettingsKey = "extendedSettings"
}

public struct ServerConfiguration: Printable {
    public let status: String?
    public let apiEnabled: Bool?
    public let careportalEnabled: Bool?
    public let enabledOptions: [EnabledOptions]?
    public let defaults: Defaults?
    public let unitsRoot: Units?
    public let head:String?
    public let version: String?
    public let thresholds: Threshold?
    public let alarm_types: String?
    public let name: String?
    
    public var description: String {
        
        var dict = Dictionary<String, AnyObject>()  //= NSMutableDictionary ()
        if let status = status {
            dict["status"] = status
        }
        if let apiEnabled = apiEnabled{
            dict["apiEnabled"] = apiEnabled
        }
        if let capreporatlEnabled = careportalEnabled {
            dict["capreporatlEnabled"] = capreporatlEnabled
        }
        if let enabledOptions = enabledOptions {
            dict["enabledOptions"] = enabledOptions.description
        }
        if let defaults = defaults {
            dict["defaults"] = defaults.description
        }
        if let unitsRoot = unitsRoot {
            dict["unitsRoot"] = unitsRoot.description
        }
        if let head = head {
            dict["head"] = head
        }
        if let version = version {
            dict["version"] = version
        }
        if let thresholds = thresholds {
            dict["thresholds"] = thresholds.description
        }
        if let alarm_types = alarm_types {
            dict["alram_types"] = alarm_types
        }
        if let name = name {
            dict["name"] = name
        }

        // let dict = ["status" : status, "apiEnabled" : apiEnabled?.description, "carePortal": careportalEnabled?.description, "enabledOptions": enabledOptions?.description, "defaults": defaults?.description, "units": unitsRoot?.rawValue, "head": head, "version": version, "thresholds": thresholds?.description, "alarm_types": alarm_types, "name": name]
        return dict.description
    }
}

public extension ServerConfiguration {
    
    init(jsonDictionary: [String:AnyObject]) {
        
        var serverConfig: ServerConfiguration = ServerConfiguration(status: nil, apiEnabled: nil, careportalEnabled: nil, enabledOptions: nil, defaults: nil, unitsRoot: nil, head: nil, version: nil, thresholds: nil, alarm_types: nil, name: nil)
        
        var root = jsonDictionary
        if let statusString = root[ConfigurationPropertyKey.statusKey] as? String {
            if let apiEnabledBool = root[ConfigurationPropertyKey.apiEnabledKey] as? Bool {
                if let careportalEnabledBool = root[ConfigurationPropertyKey.careportalEnabledKey] as? Bool {
                    if let unitsRootString = root[ConfigurationPropertyKey.unitsKey] as? String {
                        let unitsRootUnit = Units(rawValue: unitsRootString)!
                        if let headString = root[ConfigurationPropertyKey.headKey] as? String {
                            if let versionString = root[ConfigurationPropertyKey.versionKey] as? String {
                                if let alarmTypesString = root[ConfigurationPropertyKey.alarm_typesKey] as? String {
                                    
                                    var options = [EnabledOptions]()
                                    if let enabledOptionsString = root[ConfigurationPropertyKey.enabledOptionsKey] as? String {
                                        for stringItem in enabledOptionsString.componentsSeparatedByString(" "){
                                            if let item = EnabledOptions(rawValue: stringItem){
                                                options.append(item)
                                            }
                                        }
                                    }
                                    
                                    let nameString = root[ConfigurationPropertyKey.nameKey] as? String
                                    
                                    var defaultsDefaults: Defaults?
                                    if let defaultsDictionary = root[ConfigurationPropertyKey.defaultsKey] as? [String: AnyObject] {
                                        let units = Units(rawValue: defaultsDictionary[ConfigurationPropertyKey.unitsKey] as! String)!
                                        let timeFormat = (defaultsDictionary[ConfigurationPropertyKey.timeFormatKey] as! String).toInt()!
                                        let nightMode = defaultsDictionary[ConfigurationPropertyKey.nightModeKey] as! Bool
                                        let showRawbg = RawBGMode(rawValue: defaultsDictionary[ConfigurationPropertyKey.showRawbgKey] as! String)!
                                        let customTitle = defaultsDictionary[ConfigurationPropertyKey.customTitleKey] as! String
                                        
                                        let theme = defaultsDictionary[ConfigurationPropertyKey.themeKey] as! String
                                        
                                        let aHigh = defaultsDictionary[ConfigurationPropertyKey.alarmHighKey] as! Bool
                                        let aLow = defaultsDictionary[ConfigurationPropertyKey.alarmLowKey] as! Bool
                                        let aTAU = defaultsDictionary[ConfigurationPropertyKey.alarmTimeAgoUrgentKey] as! Bool
                                        let aTAUMDouble = defaultsDictionary[ConfigurationPropertyKey.alarmTimeAgoUrgentMinsKey] as! Double
                                        let aTAUMin: NSTimeInterval = aTAUMDouble * 60 // Convert minutes to seconds.
                                        
                                        let aTAW = defaultsDictionary[ConfigurationPropertyKey.alarmTimeAgoWarnKey] as! Bool
                                        let aTAWMDouble = defaultsDictionary[ConfigurationPropertyKey.alarmTimeAgoWarnMinsKey] as! Double
                                        let aTAWMin: NSTimeInterval = aTAWMDouble * 60 // Convert minutes to seconds.
                                        let aTUH = defaultsDictionary[ConfigurationPropertyKey.alarmUrgentHighKey] as! Bool
                                        let aTUL = defaultsDictionary[ConfigurationPropertyKey.alarmUrgentLowKey] as! Bool
                                        
                                        let alarms = Alarm(alarmHigh: aHigh, alarmLow: aLow, alarmTimeAgoUrgent: aTAU, alarmTimeAgoUrgentMins: aTAUMin, alarmTimeAgoWarn: aTAW, alarmTimeAgoWarnMins: aTAWMin, alarmUrgentHigh: aTUH, alarmUrgentLow: aTUL)
                                        
                                        let language = defaultsDictionary[ConfigurationPropertyKey.languageKey] as! String
                                        
                                        defaultsDefaults = Defaults(units: units, timeFormat: timeFormat, nightMode: nightMode, showRawbg: showRawbg, customTitle: customTitle, theme: theme, alarms: alarms, language: language)
                                    }
                                    
                                    var threasholdsThreshold: Threshold?
                                    if let thresholdsDict = jsonDictionary[ConfigurationPropertyKey.thresholdsKey] as? [String : AnyObject] {
                                        let bg_high = thresholdsDict[ConfigurationPropertyKey.bg_highKey] as! Int
                                        let bg_low = thresholdsDict[ConfigurationPropertyKey.bg_lowKey] as! Int
                                        let bg_target_bottom = thresholdsDict[ConfigurationPropertyKey.bg_target_bottomKey] as! Int
                                        let bg_target_top = thresholdsDict[ConfigurationPropertyKey.bg_target_topKey] as! Int
                                        threasholdsThreshold = Threshold(bg_high: bg_high, bg_low: bg_low, bg_target_bottom: bg_target_bottom, bg_target_top: bg_target_top)
                                    }
                                    
                                    serverConfig = ServerConfiguration(status: statusString, apiEnabled: apiEnabledBool, careportalEnabled: careportalEnabledBool, enabledOptions: options, defaults: defaultsDefaults, unitsRoot: unitsRootUnit, head: headString, version: versionString, thresholds: threasholdsThreshold, alarm_types: alarmTypesString, name: nameString)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        status = serverConfig.status
        apiEnabled = serverConfig.apiEnabled
        careportalEnabled = serverConfig.careportalEnabled
        enabledOptions = serverConfig.enabledOptions
        
        defaults = serverConfig.defaults
        
        unitsRoot = serverConfig.unitsRoot
        head = serverConfig.head
        version = serverConfig.version
        thresholds = serverConfig.thresholds
        alarm_types = serverConfig.alarm_types
        name = serverConfig.name
    }
}

// TODO: Should this be here?
public enum DesiredColorState {
    case Alert, Warning, Positive, Neutral
}

// TODO: Should this be here? Maybe it shuld be a threshold extension.
public extension ServerConfiguration {
    
    public func boundedColorForGlucoseValue(value: Int) -> DesiredColorState {
        var color = DesiredColorState.Neutral
        if let thresholds = self.thresholds {
            if (value >= thresholds.bg_high) {
                color = .Alert
            } else if (value > thresholds.bg_target_top && value < thresholds.bg_high) {
                color =  .Warning
            } else if (value >= thresholds.bg_target_bottom && value <= thresholds.bg_target_top) {
                color = .Positive
            } else if (value < thresholds.bg_target_bottom && value > thresholds.bg_low) {
                color = .Warning
            } else if (value <= thresholds.bg_low && value != 0) {
                color = .Alert
            }
        }
        return color
    }
    
    public func isDataStaleWith(interval sinceNow: NSTimeInterval) -> (warn: Bool, urgent: Bool) {
        if let alarms = self.defaults?.alarms {
            return isDataStaleWith(interval: sinceNow, warn: alarms.alarmTimeAgoWarnMins, urgent: alarms.alarmTimeAgoUrgentMins)
        } else {
            return isDataStaleWith(interval: sinceNow, warn: 900, urgent: 1800)
        }
    }
    
    public func isDataStaleWith(interval sinceNow: NSTimeInterval, warn: NSTimeInterval, urgent: NSTimeInterval, fallback: NSTimeInterval = NSTimeInterval(600)) -> (warn: Bool, urgent: Bool) {
        
        let warnValue: NSTimeInterval = -max(fallback, warn)
        let urgentValue: NSTimeInterval = -max(fallback, urgent)
        var returnValue = (sinceNow < warnValue, sinceNow < urgentValue)

        #if DEBUG
            println("\(__FUNCTION__): {sinceNow: \(sinceNow), warneValue: \(warnValue), urgentValue: \(urgentValue), fallback:\(-fallback), returning: \(returnValue)}")
        #endif
        
        return returnValue
    }

}
