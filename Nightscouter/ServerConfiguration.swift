//
//  Settings.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation

enum EnabledOptions: String {
    case careportal = "careportal"
    case rawbg = "rawbg"
    case iob = "iob"
}

enum Units:String {
    case Mgdl = "mg/dl"
    case Mmoll = "mmol/L"
}

enum RawBGMode: String {
    case Never = "never"
    case Always = "always"
    case Noise = "noise"
}

struct Threshold {
    let bg_high: Int
    let bg_low: Int
    let bg_target_bottom :Int
    let bg_target_top :Int
}

struct Alarm {
    let alarmHigh: Bool
    let alarmLow: Bool
    let alarmTimeAgoUrgent: Bool
    let alarmTimeAgoUrgentMins: Int
    let alarmTimeAgoWarn: Bool
    let alarmTimeAgoWarnMins: Int
    let alarmUrgentHigh: Bool
    let alarmUrgentLow: Bool
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
}

struct ServerConfiguration {
    let alarm_types: String
    let apiEnabled: Bool
    let careportalEnabled: Bool
    
    let enabledOptions: Dictionary<String, EnabledOptions>
    let head:String
    let name: String
    let status: String
    
    let units: Units
    let version: String
    let customTitle: String
    let language: String
    let nightMode: Bool
    let showRawbg: RawBGMode
    let theme: String
    let timeFormat: Int
    let unitsRoot: Units
    
    let thresholds: Threshold
    let alrams: Alarm
}

extension ServerConfiguration {
    
    init(jsonDictionary: [String:AnyObject]) {
        
        var alarm_types: String!
        var apiEnabled: Bool!
        var careportalEnabled: Bool!
        var enabledOptions: Dictionary<String, EnabledOptions>!
        var head:String!
        var name: String!
        var status: String!
        var units: Units!
        var version: String!
        var customTitle: String!
        var language: String!
        var nightMode: Bool!
        var showRawbg: RawBGMode!
        var theme: String!
        var timeFormat: Int!
        var unitsRoot: Units!
        var thresholds: Threshold!
        var alrams: Alarm!
        
        var dict = jsonDictionary
        
        if let statusVar = dict[ConfigurationPropertyKey.statusKey] as? String {
            status = statusVar
            
            if let apiEnabledVar = dict[ConfigurationPropertyKey.apiEnabledKey] as? Bool {
                apiEnabled = apiEnabledVar
                
                if let careportalEnabledVar = dict[ConfigurationPropertyKey.careportalEnabledKey] as? Bool {
                    careportalEnabled = careportalEnabledVar
                    
                    if let unitsRootString = dict[ConfigurationPropertyKey.unitsKey] as? String {
                        // Convert to a standard unit.
                        unitsRoot = Units(rawValue: unitsRootString)!
                        
                        if let headVar = dict[ConfigurationPropertyKey.headKey] as? String {
                            head = headVar
                            
                            if let versionString = dict[ConfigurationPropertyKey.versionKey] as? String {
                                version = versionString
                                
                                if let alarm_typesVar = dict[ConfigurationPropertyKey.alarm_typesKey] as? String {
                                    alarm_types = alarm_typesVar
                                    
                                    if let nameVar = dict[ConfigurationPropertyKey.nameKey] as? String {
                                        name = nameVar
                                        
                                        if let enabledOptionsVar = dict[ConfigurationPropertyKey.enabledOptionsKey] as? String {
                                            
                                            var options = [String: EnabledOptions]()
                                            for stringItem in enabledOptionsVar.componentsSeparatedByString(" "){
                                                options[stringItem] = EnabledOptions(rawValue: stringItem)
                                            }
                                            enabledOptions = options
                                            
                                            if let dd = dict[ConfigurationPropertyKey.defaultsKey] as? [String: AnyObject] {
                                                units = Units(rawValue: dict[ConfigurationPropertyKey.unitsKey] as! String)!
                                                
                                                timeFormat = (dd[ConfigurationPropertyKey.timeFormatKey] as! String).toInt()!
                                                
                                                nightMode = dd[ConfigurationPropertyKey.nightModeKey] as! Bool
                                                
                                                showRawbg = RawBGMode(rawValue: dd[ConfigurationPropertyKey.showRawbgKey] as! String)!
                                                customTitle = dd[ConfigurationPropertyKey.customTitleKey] as! String
                                                
                                                theme = dd[ConfigurationPropertyKey.themeKey] as! String
                                                
                                                let aHigh = dd[ConfigurationPropertyKey.alarmHighKey] as! Bool
                                                let aLow = dd[ConfigurationPropertyKey.alarmLowKey] as! Bool
                                                let aTAU = dd[ConfigurationPropertyKey.alarmTimeAgoUrgentKey] as! Bool
                                                let aTAUMin = dd[ConfigurationPropertyKey.alarmTimeAgoUrgentMinsKey] as! Int
                                                let aTAW = dd[ConfigurationPropertyKey.alarmTimeAgoWarnKey] as! Bool
                                                let aTAWMin = dd[ConfigurationPropertyKey.alarmTimeAgoWarnMinsKey] as! Int
                                                let aTUH = dd[ConfigurationPropertyKey.alarmUrgentHighKey] as! Bool
                                                let aTUL = dd[ConfigurationPropertyKey.alarmUrgentLowKey] as! Bool
                                                
                                                alrams = Alarm(alarmHigh: aHigh, alarmLow: aLow, alarmTimeAgoUrgent: aTAU, alarmTimeAgoUrgentMins: aTAUMin, alarmTimeAgoWarn: aTAW, alarmTimeAgoWarnMins: aTAWMin, alarmUrgentHigh: aTUH, alarmUrgentLow: aTUL)
                                                
                                                language = dd[ConfigurationPropertyKey.languageKey] as! String
                                                
                                                if let thresholdsDict = jsonDictionary[ConfigurationPropertyKey.thresholdsKey] as? [String : AnyObject] {
                                                    let bg_high = thresholdsDict[ConfigurationPropertyKey.bg_highKey] as! Int
                                                    let bg_low = thresholdsDict[ConfigurationPropertyKey.bg_lowKey] as! Int
                                                    let bg_target_bottom = thresholdsDict[ConfigurationPropertyKey.bg_target_bottomKey] as! Int
                                                    let bg_target_top = thresholdsDict[ConfigurationPropertyKey.bg_target_topKey] as! Int
                                                    thresholds = Threshold(bg_high: bg_high, bg_low: bg_low, bg_target_bottom: bg_target_bottom, bg_target_top: bg_target_top)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        self.thresholds = thresholds
        self.alrams = alrams
        self.alarm_types = alarm_types
        self.apiEnabled = apiEnabled
        self.careportalEnabled = careportalEnabled
        self.customTitle = customTitle
        self.enabledOptions = enabledOptions
        self.head = head
        self.language = language
        self.name = name
        self.nightMode = nightMode
        self.showRawbg = showRawbg
        self.status = status
        self.theme = theme
        self.timeFormat = timeFormat
        self.units = units
        self.unitsRoot = unitsRoot
        self.version = version
    }
    
}



enum DesiredColorState {
    case Alert, Warning, Positive, Neutral
}

extension ServerConfiguration {
    
    func boundedColorForGlucoseValue(value: Int) -> DesiredColorState {
        var color = DesiredColorState.Neutral
        if (value > self.thresholds.bg_high) {
            color = .Alert
        } else if (value > self.thresholds.bg_target_top) {
            color =  .Warning
        } else if (value >= self.thresholds.bg_target_bottom && value <= self.thresholds.bg_target_top) {
            color = .Positive
        } else if (value < self.thresholds.bg_low) {
            color = .Alert
        } else if (value < self.thresholds.bg_target_bottom) {
            color = .Warning
        }
        return color
    }
}
