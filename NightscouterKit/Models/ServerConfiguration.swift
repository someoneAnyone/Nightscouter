//
//  Settings.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

public enum EnabledOptions: String, CustomStringConvertible {
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
    case maker = "maker"
    case cob = "cob"
    case bwp = "bwp"
    case cage = "cage"
    case basal = "basal"
    
    public var description: String {
        return self.rawValue
    }
}

public enum Units: String, CustomStringConvertible {
    case Mgdl = "mg/dl"
    case Mmol = "mmol"
    
    public var description: String {
        switch self {
        case .Mgdl:
            return "mg/dL"
        case .Mmol:
            return "mmol/L"
        }
    }
}

public enum RawBGMode: String, CustomStringConvertible {
    case Never = "never"
    case Always = "always"
    case Noise = "noise"
    
    public var description: String {
        return self.rawValue
    }
}

public struct Threshold: CustomStringConvertible {
    public let bg_high: Double
    public let bg_low: Double
    public let bg_target_bottom :Double
    public let bg_target_top :Double
    
    public var description: String {
        let dict = ["bg_high": bg_high, "bg_low": bg_low, "bg_target_bottom": bg_target_bottom, "bg_target_top": bg_target_top]
        return dict.description
    }
}

public struct Alarm: CustomStringConvertible {
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

public enum AlarmTypes: String, CustomStringConvertible {
    case predict = "predict"
    case simple = "simple"
    
    public var description: String {
        return self.rawValue
    }
}

public struct Defaults: CustomStringConvertible {
    // Start of "defaults" dictionary // In future nightscout this becomes settings... not sure how we want to manage the transition.
    public let units: Units
    public let timeFormat: Int
    public let nightMode: Bool
    public let showRawbg: RawBGMode
    public let customTitle: String
    public let theme: String
    public let alarms: Alarm
    public let language: String
    public let showPlugins: String?
    public let enable: [EnabledOptions]?
    public let thresholds: Threshold?
    public let defaultFeatures: [String]?
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
    static let alarmTimeAgoUrgentKey = "alarmTimeAgoUrgent" // for ns version 7.0.
    static let alarmTimeagoUrgentKey = "alarmTimeagoUrgent" // for ns version 8.0.
    static let alarmTimeAgoUrgentMinsKey = "alarmTimeAgoUrgentMins"  // for ns version 7.0.
    static let alarmTimeagoUrgentMinsKey = "alarmTimeagoUrgentMins"  // for ns version 8.0.
    static let alarmTimeAgoWarnKey = "alarmTimeAgoWarn" // for ns version 7.0.
    static let alarmTimeagoWarnKey = "alarmTimeagoWarn"
    static let alarmTimeAgoWarnMinsKey = "alarmTimeAgoWarnMins" // for ns version 7.0.
    static let alarmTimeagoWarnMinsKey = "alarmTimeagoWarnMins"
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

    // ver 7.0
    static let bg_highKey = "bg_high"
    static let bg_lowKey = "bg_low"
    static let bg_target_bottomKey = "bg_target_bottom"
    static let bg_target_topKey = "bg_target_top"
    
    // ver 8.0
    static let bgHighKey = "bgHigh"
    static let bgLowKey = "bgLow"
    static let bgTargetBottomKey = "bgTargetBottom"
    static let bgTargetTopKey = "bgTargetTop"
    
    static let versionKey = "version"
    
    // Not implmented yet
     static let extendedSettingsKey = "extendedSettings"
     static let settingsKey = "settings"
     static let enableKey = "enable"
     static let showPluginsKey = "showPlugins"
}

public struct ServerConfiguration: CustomStringConvertible {
    public var status: String?
    public var apiEnabled: Bool?
    public var careportalEnabled: Bool?
    public var enabledOptions: [EnabledOptions]?
    public var defaults: Defaults?
//    public let settings: Defaults?
    public var unitsRoot: Units?
    public var head:String?
    public var version: String?
    public var thresholds: Threshold?
    public var alarm_types: String?
    public var name: String?
    
    public var description: String {
        
        var dict = Dictionary<String, AnyObject>()
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
        
        return dict.description
    }
}

public extension ServerConfiguration {
    
    init(jsonDictionary: [String:AnyObject]) {
        
        var serverConfig: ServerConfiguration = ServerConfiguration(status: nil, apiEnabled: nil, careportalEnabled: nil, enabledOptions: nil, defaults: nil, unitsRoot: nil, head: nil, version: nil, thresholds: nil, alarm_types: nil, name: nil)
        
        var root = jsonDictionary
        
        if let statusString = root[ConfigurationPropertyKey.statusKey] as? String {
            serverConfig.status = statusString
        }
        
        if let apiEnabledBool = root[ConfigurationPropertyKey.apiEnabledKey] as? Bool {
            serverConfig.apiEnabled = apiEnabledBool
        }
        
        if let careportalEnabledBool = root[ConfigurationPropertyKey.careportalEnabledKey] as? Bool {
            serverConfig.careportalEnabled = careportalEnabledBool
        }
        
        if let unitsRootString = root[ConfigurationPropertyKey.unitsKey] as? String {
            let unitsRootUnit = Units(rawValue: unitsRootString)!
            serverConfig.unitsRoot = unitsRootUnit
        }
        
        if let headString = root[ConfigurationPropertyKey.headKey] as? String {
            serverConfig.head = headString
        }
        
        if let versionString = root[ConfigurationPropertyKey.versionKey] as? String {
            serverConfig.version = versionString
        }
        
        if let alarmTypesString = root[ConfigurationPropertyKey.alarm_typesKey] as? String {
            serverConfig.alarm_types = alarmTypesString
        }
        
        var options = [EnabledOptions]()
        if let enabledOptionsString = root[ConfigurationPropertyKey.enabledOptionsKey] as? String {
            for stringItem in enabledOptionsString.componentsSeparatedByString(" "){
                if let item = EnabledOptions(rawValue: stringItem){
                    options.append(item)
                }
            }
        }
        
        if let nameString = root[ConfigurationPropertyKey.nameKey] as? String {
            serverConfig.name = nameString
        }
        
        var threshold: Threshold?
        if let thresholdsDict = jsonDictionary[ConfigurationPropertyKey.thresholdsKey] as? [String : AnyObject] {
            let bg_high = thresholdsDict[ConfigurationPropertyKey.bg_highKey] as! Double
            let bg_low = thresholdsDict[ConfigurationPropertyKey.bg_lowKey] as! Double
            let bg_target_bottom = thresholdsDict[ConfigurationPropertyKey.bg_target_bottomKey] as! Double
            let bg_target_top = thresholdsDict[ConfigurationPropertyKey.bg_target_topKey] as! Double
            threshold = Threshold(bg_high: bg_high, bg_low: bg_low, bg_target_bottom: bg_target_bottom, bg_target_top: bg_target_top)
        }

        
        var defaultsDefaults: Defaults?
        if let defaultsDictionary = root[ConfigurationPropertyKey.defaultsKey] as? [String: AnyObject] {
            let units = Units(rawValue: defaultsDictionary[ConfigurationPropertyKey.unitsKey] as! String)!
            let timeFormat = Int((defaultsDictionary[ConfigurationPropertyKey.timeFormatKey] as! String))!
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
        
            defaultsDefaults = Defaults(units: units, timeFormat: timeFormat, nightMode: nightMode, showRawbg: showRawbg, customTitle: customTitle, theme: theme, alarms: alarms, language: language, showPlugins: nil, enable: nil, thresholds: nil, defaultFeatures: nil)
        }
        
        if let settingsDictionary = root[ConfigurationPropertyKey.settingsKey] as? [String: AnyObject] {
            let units = Units(rawValue: (settingsDictionary[ConfigurationPropertyKey.unitsKey] as! String).lowercaseString)!
            let timeFormat = Int((settingsDictionary[ConfigurationPropertyKey.timeFormatKey] as! String))!
            let nightMode = settingsDictionary[ConfigurationPropertyKey.nightModeKey] as! Bool
            let showRawbg = RawBGMode(rawValue: settingsDictionary[ConfigurationPropertyKey.showRawbgKey] as! String)!
            let customTitle = settingsDictionary[ConfigurationPropertyKey.customTitleKey] as! String
            
            let theme = settingsDictionary[ConfigurationPropertyKey.themeKey] as! String
            
            let aHigh = settingsDictionary[ConfigurationPropertyKey.alarmHighKey] as! Bool
            let aLow = settingsDictionary[ConfigurationPropertyKey.alarmLowKey] as! Bool
            let aTAU = settingsDictionary[ConfigurationPropertyKey.alarmTimeagoUrgentKey] as! Bool
            let aTAUMDouble = settingsDictionary[ConfigurationPropertyKey.alarmTimeagoUrgentMinsKey] as! Double
            let aTAUMin: NSTimeInterval = aTAUMDouble * 60 // Convert minutes to seconds.
            
            let aTAW = settingsDictionary[ConfigurationPropertyKey.alarmTimeagoWarnKey] as! Bool
            let aTAWMDouble = settingsDictionary[ConfigurationPropertyKey.alarmTimeagoWarnMinsKey] as! Double
            let aTAWMin: NSTimeInterval = aTAWMDouble * 60 // Convert minutes to seconds.
            let aTUH = settingsDictionary[ConfigurationPropertyKey.alarmUrgentHighKey] as! Bool
            let aTUL = settingsDictionary[ConfigurationPropertyKey.alarmUrgentLowKey] as! Bool
            
            let alarms = Alarm(alarmHigh: aHigh, alarmLow: aLow, alarmTimeAgoUrgent: aTAU, alarmTimeAgoUrgentMins: aTAUMin, alarmTimeAgoWarn: aTAW, alarmTimeAgoWarnMins: aTAWMin, alarmUrgentHigh: aTUH, alarmUrgentLow: aTUL)
            
            let language = settingsDictionary[ConfigurationPropertyKey.languageKey] as! String
            
            
            if let enableArray = settingsDictionary[ConfigurationPropertyKey.enableKey] as? [String] {
                for stringItem in enableArray{
                    if let item = EnabledOptions(rawValue: stringItem){
                        options.append(item)
                    }
                }
            }
            
            if let thresholdsDict = settingsDictionary[ConfigurationPropertyKey.thresholdsKey] as? [String : AnyObject] {
                let bg_high = thresholdsDict[ConfigurationPropertyKey.bgHighKey] as! Double
                let bg_low = thresholdsDict[ConfigurationPropertyKey.bgLowKey] as! Double
                let bg_target_bottom = thresholdsDict[ConfigurationPropertyKey.bgTargetBottomKey] as! Double
                let bg_target_top = thresholdsDict[ConfigurationPropertyKey.bgTargetTopKey] as! Double
                threshold = Threshold(bg_high: bg_high, bg_low: bg_low, bg_target_bottom: bg_target_bottom, bg_target_top: bg_target_top)
            }


            
            defaultsDefaults = Defaults(units: units, timeFormat: timeFormat, nightMode: nightMode, showRawbg: showRawbg, customTitle: customTitle, theme: theme, alarms: alarms, language: language, showPlugins: nil, enable: options, thresholds: threshold, defaultFeatures: nil)

        }

        serverConfig.defaults = defaultsDefaults
        
        serverConfig.thresholds = threshold
        serverConfig.enabledOptions = options

        self = serverConfig
    }
}

// TODO: Should this be here?
public enum DesiredColorState {
    case Alert, Warning, Positive, Neutral
}

// TODO: Should this be here? Maybe it shuld be a threshold extension.
public extension ServerConfiguration {
    
    public func boundedColorForGlucoseValue(mgdlSGV: Double) -> DesiredColorState {
        var color = DesiredColorState.Neutral
        
        let mgdlValue: Double = mgdlSGV
        
        if let thresholds = self.thresholds {
            if (mgdlValue >= thresholds.bg_high) {
                color = .Alert
            } else if (mgdlValue > thresholds.bg_target_top && mgdlValue < thresholds.bg_high) {
                color =  .Warning
            } else if (mgdlValue >= thresholds.bg_target_bottom && mgdlValue <= thresholds.bg_target_top) {
                color = .Positive
            } else if (mgdlValue < thresholds.bg_target_bottom && mgdlValue > thresholds.bg_low) {
                color = .Warning
            } else if (mgdlValue <= thresholds.bg_low && mgdlValue != 0) {
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
        let returnValue = (sinceNow < warnValue, sinceNow < urgentValue)
        
        #if DEBUG
            print("\(__FUNCTION__): {sinceNow: \(sinceNow), warneValue: \(warnValue), urgentValue: \(urgentValue), fallback:\(-fallback), returning: \(returnValue)}")
        #endif
        
        return returnValue
    }
}

public extension ServerConfiguration {
    public var displayName: String {
        if let defaults = defaults {
            return defaults.customTitle
        } else if let name = name {
            return name
        } else {
            return  NSLocalizedString("nightscoutTitleString", tableName: nil, bundle:  NSBundle.mainBundle(), value: "", comment: "Label used to when we can't find a title for the website.")
            
        }
    }
    
    public var displayUnits: Units {
        if let defaults = defaults {
            return defaults.units
        } else if let unitsRoot = unitsRoot {
            return unitsRoot
        } else {
            return .Mgdl
        }
    }
}