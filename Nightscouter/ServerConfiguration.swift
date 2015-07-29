//
//  Settings.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

enum EnabledOptions: String, Printable {
    case careportal = "careportal"
    case rawbg = "rawbg"
    case iob = "iob"
    case ar2 = "ar2"
    case treatmentnotify = "treatmentnotify"
    case delta = "delta"
    case direction = "direction"
    case upbat = "upbat"
    case errorcodes = "errorcodes"
    
    var description: String {
        return self.rawValue
    }
}

enum Units:String, Printable {
    case Mgdl = "mg/dl"
    case Mmoll = "mmol/L"
    
    
    var description: String {
        return self.rawValue
    }
}

enum RawBGMode: String, Printable {
    case Never = "never"
    case Always = "always"
    case Noise = "noise"
    
    var description: String {
        return self.rawValue
    }
}

struct Threshold: Printable {
    let bg_high: Int
    let bg_low: Int
    let bg_target_bottom :Int
    let bg_target_top :Int
    
    var description: String {
        let dict = ["bg_high": bg_high, "bg_low:": bg_low, "bg_target_bottom": bg_target_bottom, "bg_target_top": bg_target_top]
        return dict.description
    }
}

struct Alarm {
    let alarmHigh: Bool
    let alarmLow: Bool
    let alarmTimeAgoUrgent: Bool
    let alarmTimeAgoUrgentMins: NSTimeInterval
    let alarmTimeAgoWarn: Bool
    let alarmTimeAgoWarnMins: NSTimeInterval
    let alarmUrgentHigh: Bool
    let alarmUrgentLow: Bool
}

struct Defaults: Printable {
    // Start of "defaults" dictionary
    let units: Units
    let timeFormat: Int
    let nightMode: Bool
    let showRawbg: RawBGMode
    let customTitle: String
    let theme: String
    let alarms: Alarm
    let language: String
    let showPlugins: String? = nil
    // End of "defaults" dictionary
    
    var description: String {
        let dict = ["units": units.description, "timeFormat": timeFormat, "nightMode": nightMode.description, "showRawbg": showRawbg.rawValue]
        
        return dict.description
    }
}

enum AlarmTypes: String {
    case predict = "predict"
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

struct ServerConfiguration: Printable {
    let status: String?
    let apiEnabled: Bool?
    let careportalEnabled: Bool?
    let enabledOptions: [EnabledOptions]?
    let defaults: Defaults?
    
    let unitsRoot: Units?
    let head:String?
    let version: String?
    let thresholds: Threshold?
    let alarm_types: String?
    let name: String?
    
    var description: String {
        let dict = ["status" : status, "apiEnabled" : apiEnabled?.description, "carePortal": careportalEnabled?.description, "enabledOptions": enabledOptions?.description, "defaults": defaults?.description, "units": unitsRoot?.rawValue, "head": head, "version": version, "thresholds": thresholds?.description, "alarm_types": alarm_types, "name": name]
        return dict.description
    }
}

extension ServerConfiguration {
    
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

enum DesiredColorState {
    case Alert, Warning, Positive, Neutral
}

extension ServerConfiguration {
    
    func boundedColorForGlucoseValue(value: Int) -> DesiredColorState {
        var color = DesiredColorState.Neutral
        if let thresholds = self.thresholds {
            if (value > thresholds.bg_high) {
                color = .Alert
            } else if (value > thresholds.bg_target_top) {
                color =  .Warning
            } else if (value >= thresholds.bg_target_bottom && value <= thresholds.bg_target_top) {
                color = .Positive
            } else if (value < thresholds.bg_low) {
                color = .Alert
            } else if (value < thresholds.bg_target_bottom) {
                color = .Warning
            }
        }
        return color
    }
}
