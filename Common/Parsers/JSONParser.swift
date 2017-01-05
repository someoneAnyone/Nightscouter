//
//  JSONParser.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/20/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

// All the Additions for JSON Processing happens here.

import Foundation

// All the JSON keys I saw when parsing the socket.io output for dataUpdate
public typealias JSON = [String: Any]

struct GlobalJSONKey {
    static let sgvs = "sgvs"
    static let mbgs = "mbgs"
    static let cals = "cals"
    // static let deltaCount = "delta"
    // static let profiles = "profiles"
    // static let treatments = "treatments"
}

extension Site: Encodable, Decodable {
    struct JSONKey {
        static let lastUpdated = "lastUpdated"
        static let url = "url"
        static let updatedAt = "updatedAt"
        static let overrideScreenLock = "overrideScreenLock"
        static let disabled = "disabled"
        static let uuid = "uuid"
        static let configuration = "configuration"
        static let data = "data"
        static let sgvs = "sgvs"
        static let mbgs = "mbgs"
        static let cals = "cals"
        static let deviceStatuses = "deviceStatuses"
        static let complicationTimeline = "complicationTimeline"
    }
    
    public func encode() -> [String: Any] {
        let encodedSgvs: [[String : Any]] = sgvs.flatMap{ $0.encode() }
        let encodedCals: [[String : Any]] = cals.flatMap{ $0.encode() }
        let encodedMgbs: [[String : Any]] = mbgs.flatMap{ $0.encode() }
        let encodedDeviceStatus: [[String : Any]] = deviceStatuses.flatMap{ $0.encode() }
        let encodedComplicationTimeline: [[String : Any]] = complicationTimeline.flatMap { $0.encode() }
        
        return [JSONKey.url : url.absoluteString,
                JSONKey.updatedAt : updatedAt,
                JSONKey.overrideScreenLock : overrideScreenLock,
                JSONKey.disabled: disabled,
                JSONKey.uuid: uuid.uuidString,
                JSONKey.configuration: configuration?.encode() ?? "",
                JSONKey.sgvs: encodedSgvs,
                JSONKey.cals: encodedCals,
                JSONKey.mbgs: encodedMgbs,
                JSONKey.deviceStatuses: encodedDeviceStatus,
                JSONKey.complicationTimeline: encodedComplicationTimeline]
    }
    
    public static func decode(_ dict: [String: Any]) -> Site? {
        
        guard let urlString = dict[JSONKey.url] as? String, let url = URL(string: urlString), let uuidString = dict[JSONKey.uuid] as? String, let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        
        var site = Site(url: url, uuid: uuid)
        site.overrideScreenLock = dict[JSONKey.overrideScreenLock] as? Bool ?? false
        site.disabled = dict[JSONKey.disabled] as? Bool ?? false
        if let nextRefesh = dict[JSONKey.updatedAt] as? Date {
            site.updatedAt = nextRefesh
        } else {
            site.updatedAt = Date.distantPast
        }
        let rootDictForData = dict
        
        if let sgvs = rootDictForData[JSONKey.sgvs] as? [[String: Any]] {
            site.sgvs = sgvs.flatMap { SensorGlucoseValue.decode($0) }
        }
        
        if let mbgs = rootDictForData[JSONKey.mbgs] as? [[String: Any]] {
            site.mbgs = mbgs.flatMap { MeteredGlucoseValue.decode($0) }
        }
        
        if let cals = rootDictForData[JSONKey.cals] as? [[String: Any]] {
            site.cals = cals.flatMap { Calibration.decode($0) }
        }
        
        if let devStatus = rootDictForData[JSONKey.deviceStatuses] as? [[String: Any]] {
            site.deviceStatuses = devStatus.flatMap { DeviceStatus.decode($0) }
        }
        
        if let config = dict[JSONKey.configuration] as? [String: Any] {
            site.configuration = ServerConfiguration.decode(config)
        }
        
        if let  complicationTimeline = dict[JSONKey.complicationTimeline] as? [[String: Any]] {
            site.complicationTimeline = complicationTimeline.flatMap{ ComplicationTimelineEntry.decode($0) }
        }
        
        return site
    }
}

extension ServerConfiguration: Encodable, Decodable {
    struct JSONKey {
        static let status = "status"
        static let name = "name"
        static let version = "version"
        static let serverTime = "serverTime"
        static let apiEnabled = "apiEnabled"
        static let careportalEnabled = "careportalEnabled"
        static let boluscalcEnabled = "boluscalcEnabled"
        static let head = "head"
        static let settings = "settings"
    }
    
    public func encode() -> [String: Any] {
        var dict = [String: Any]()
        dict[JSONKey.status] = status
        dict[JSONKey.apiEnabled] = apiEnabled
        dict[JSONKey.serverTime] = serverTime
        dict[JSONKey.careportalEnabled] = careportalEnabled
        dict[JSONKey.boluscalcEnabled] = boluscalcEnabled
        dict[JSONKey.settings] = settings?.encode()
        dict[JSONKey.head] = head
        dict[JSONKey.version] = version
        dict[JSONKey.name] = name
        
        return dict
    }
    public static func decode(_ dict: [String: Any]) -> ServerConfiguration? {
        
        guard let status = dict[JSONKey.status] as? String,
            let apiEnabled = dict[JSONKey.apiEnabled] as? Bool,
            // let serverTime = dict[JSONKey.serverTime] as? String,
            let careportalEnabled = dict[JSONKey.careportalEnabled] as? Bool,
            let head = dict[JSONKey.head] as? String,
            let version = dict[JSONKey.version] as? String,
            let name = dict[JSONKey.name] as? String else {
                return nil
        }

        let serverTime = dict[JSONKey.serverTime] as? String ?? AppConfiguration.serverTimeDateFormatter.string(from: Date())

        let boluscalcEnabled = dict[JSONKey.boluscalcEnabled] as? Bool ?? false
        
        var settings: Settings?
        if let settingsDict = dict[JSONKey.settings] as? [String: Any]{
            settings = Settings.decode(settingsDict)
        }
        
        let config = ServerConfiguration(status: status, version: version, name: name, serverTime: serverTime, api: apiEnabled, carePortal: careportalEnabled, boluscalc: boluscalcEnabled, settings: settings, head: head)
        
        return config
    }
}

extension Settings: Encodable, Decodable {
    struct JSONKey {
        static let units = "units"
        static let timeFormat = "timeFormat"
        static let nightMode = "nightMode"
        static let editMode = "editMode"
        static let showRawbg = "showRawbg"
        static let customTitle = "customTitle"
        static let theme = "theme"
        static let alarmUrgentHigh = "alarmUrgentHigh"
        static let alarmHigh = "alarmHigh"
        static let alarmLow = "alarmLow"
        static let alarmUrgentLow = "alarmUrgentLow"
        static let alarmUrgentHighMins = "alarmUrgentHighMins"
        static let alarmHighMins = "alarmHighMins"
        static let alarmLowMins = "alarmLowMins"
        static let alarmUrgentLowMins = "alarmUrgentLowMins"
        static let alarmWarnMins = "alarmWarnMins"
        static let alarmTimeagoWarn = "alarmTimeagoWarn"
        static let alarmTimeagoWarnMins = "alarmTimeagoWarnMins"
        static let alarmTimeagoUrgent = "alarmTimeagoUrgent"
        static let alarmTimeagoUrgentMins = "alarmTimeagoUrgentMins"
        static let language = "language"
        static let scaleY = "scaleY"
        static let enable = "enable"
        static let alarmTypes = "alarmTypes"
        static let heartbeat = "heartbeat"
        static let baseURL = "baseURL"
        static let thresholds = "thresholds"
    }
    
    public func encode() -> [String : Any] {
        return [
            JSONKey.units: units.description,
            JSONKey.timeFormat: timeFormat,
            JSONKey.nightMode: nightMode,
            JSONKey.editMode: editMode,
            JSONKey.showRawbg: showRawbg.rawValue,
            JSONKey.customTitle: customTitle,
            JSONKey.theme: theme,
            JSONKey.alarmUrgentHigh: alarms.urgentHigh,
            JSONKey.alarmHigh: alarms.high,
            JSONKey.alarmLow: alarms.low,
            JSONKey.alarmUrgentLow: alarms.urgentLow,
            JSONKey.alarmUrgentHighMins: alarms.urgentHighMins,
            JSONKey.alarmHighMins: alarms.highMins,
            JSONKey.alarmLowMins: alarms.lowMins,
            JSONKey.alarmUrgentLowMins: alarms.urgentLowMins,
            JSONKey.language: language,
            JSONKey.scaleY: scaleY,
            JSONKey.enable : enable.flatMap { $0.rawValue },
            JSONKey.alarmTypes: alarmType.rawValue,
            JSONKey.heartbeat: heartbeat,
            JSONKey.baseURL: baseURL,
            JSONKey.thresholds: thresholds.encode()
        ]
    }
    
    public static func decode(_ dict: [String: Any]) -> Settings? {
        let json = dict
        
        var units: GlucoseUnit = .mgdl
        if let unitString = json[Settings.JSONKey.units] as? String {
            units = GlucoseUnit(rawValue: (unitString))
        }
        
        let timeFormat = json[Settings.JSONKey.timeFormat] as? Int ?? 12
        
        let nightMode = false
        let editMode = true
        let showRawbg = RawBGMode(rawValue: (json[Settings.JSONKey.showRawbg] as? String) ?? "")
        
        let customtitle = (json[Settings.JSONKey.customTitle] as? String) ?? "Unknown"
        
        let theme = "color"
        
        let alarmUrgentHigh = json[Settings.JSONKey.alarmUrgentHigh] as? Bool ?? true
        
        let alarmHigh = json[Settings.JSONKey.alarmHigh] as? Bool ?? true
        
        let alarmLow = json[Settings.JSONKey.alarmLow] as? Bool ?? true
        
        let alarmUrgentLow = json[Settings.JSONKey.alarmUrgentLow] as? Bool ?? true
        
        let placeholderAlarm1 = [15, 30, 45, 60]
        let placeholderAlarm2 = [30, 60, 90, 120]
        
        let alarmUrgentHighMins = json[Settings.JSONKey.alarmUrgentHighMins] as? [Int] ?? placeholderAlarm2
        let alarmHighMins: [Int] = json[Settings.JSONKey.alarmHighMins] as? [Int] ?? placeholderAlarm2
        
        let alarmLowMins: [Int] = json[Settings.JSONKey.alarmLowMins] as? [Int] ?? placeholderAlarm1
        let alarmUrgentLowMins: [Int] = json[Settings.JSONKey.alarmUrgentLowMins] as? [Int] ?? placeholderAlarm1
        let alarmWarnMins: [Int] = json[Settings.JSONKey.alarmWarnMins] as? [Int] ?? placeholderAlarm2
        
        let alarmTimeagoWarn = json[Settings.JSONKey.alarmTimeagoWarn] as? Bool ?? true
        let alarmTimeagoWarnMins = (json[Settings.JSONKey.alarmTimeagoWarnMins] as? Double ?? 15) * 60
        let alarmTimeagoUrgent = json[Settings.JSONKey.alarmTimeagoUrgent] as? Bool ?? true
        let alarmTimeagoUrgentMins = (json[Settings.JSONKey.alarmTimeagoUrgentMins] as? Double ?? 30) * 60
        
        let language = json[Settings.JSONKey.language] as? String ?? "en"
        let scaleY = json[Settings.JSONKey.scaleY] as? String ?? "log"
        
        let enabled: [Plugin] = (json[Settings.JSONKey.enable] as? [String] ?? [""]).flatMap { Plugin(rawValue: $0) }
        let thresholdsJSON = json[Settings.JSONKey.thresholds] as? [String: Any] ?? ["":""]
        
        let thresholds = Thresholds(bgHigh: thresholdsJSON[Thresholds.JSONKey.bgHigh] as? Double, bgLow: thresholdsJSON[Thresholds.JSONKey.bgLow] as? Double, bgTargetBottom: thresholdsJSON[Thresholds.JSONKey.bgTargetBottom] as? Double, bgTargetTop: thresholdsJSON[Thresholds.JSONKey.bgTargetTop] as? Double)
        let alarmType = AlarmType(rawValue: json[Settings.JSONKey.alarmTypes] as? String ?? "") ?? .simple
        let hreartbeat = json[Settings.JSONKey.heartbeat] as? Int ?? 60
        let baseURL = json[Settings.JSONKey.baseURL] as? String ?? ""
        let timeAgo = TimeAgoAlert(warn: alarmTimeagoWarn, warnMins: alarmTimeagoWarnMins, urgent: alarmTimeagoUrgent, urgentMins: alarmTimeagoUrgentMins)
        let alarms = Alarm(urgentHigh: alarmUrgentHigh, urgentHighMins: alarmUrgentHighMins, high: alarmHigh, highMins: alarmHighMins, low: alarmLow, lowMins: alarmLowMins, urgentLow: alarmUrgentLow, urgentLowMins: alarmUrgentLowMins, warnMins: alarmWarnMins)
        
        
        let settings = Settings(units: units, timeFormat: timeFormat, nightMode: nightMode, editMode: editMode, showRawbg: showRawbg, customTitle: customtitle, theme: theme, alarms: alarms, timeAgo: timeAgo, scaleY: scaleY, language: language, showPlugins: enabled, enable: enabled, thresholds: thresholds, baseURL: baseURL, alarmType: alarmType, heartbeat: hreartbeat)
        
        return settings
    }
}

extension Thresholds: Encodable, Decodable {
    struct JSONKey {
        static let bgHigh = "bgHigh"
        static let bgLow = "bgLow"
        static let bgTargetBottom = "bgTargetBottom"
        static let bgTargetTop = "bgTargetTop"
    }
    
    public func encode() -> [String : Any] {
        return [
            JSONKey.bgHigh: bgHigh,
            JSONKey.bgLow: bgLow,
            JSONKey.bgTargetBottom: targetBottom,
            JSONKey.bgTargetTop: targetTop
        ]
    }
    
    public static func decode(_ dict: [String: Any]) -> Thresholds? {
        guard let bgHigh = dict[JSONKey.bgHigh] as? Double, let bgLow =  dict[JSONKey.bgLow] as? Double, let bgTargetBottom =  dict[JSONKey.bgTargetBottom] as? Double, let bgTargetTop =  dict[JSONKey.bgTargetTop] as? Double else {
            return nil
        }
        
        return Thresholds(bgHigh: bgHigh, bgLow: bgLow, bgTargetBottom: bgTargetBottom, bgTargetTop: bgTargetTop)
    }
}

extension Calibration: Encodable, Decodable {
    struct JSONKey {
        static let slope = "slope"
        static let intercept = "intercept"
        static let scale = "scale"
        static let mills = "date"//"mills"
    }
    
    public func encode() -> [String : Any] {
        return [JSONKey.slope : slope, JSONKey.intercept: intercept, JSONKey.mills: milliseconds, JSONKey.scale: scale]
    }
    
    public static func decode(_ dict: [String : Any]) -> Calibration? {
        let json = dict
        
        guard let slope = json[JSONKey.slope] as? Double,
            let intercept = json[JSONKey.intercept] as? Double,
            let scale = json[JSONKey.scale] as? Double,
            let mill = json[JSONKey.mills] as? Double else {
                return nil
        }
        
        return Calibration(slope: slope, intercept: intercept, scale: scale, milliseconds: mill)
    }
}

extension MeteredGlucoseValue: Encodable {
    struct JSONKey {
        static let mills = "mills"
        static let device = "device"
        static let mgdl = "mgdl"
    }
    
    public func encode() -> [String : Any] {
        return [JSONKey.mills: milliseconds, JSONKey.mgdl: mgdl, JSONKey.device: device.description]
    }
    
    static func decode(_ dict: [String : Any]) -> MeteredGlucoseValue? {
        let json = dict
        
        guard let deviceString = json[JSONKey.device] as? String, let mgdl = json[JSONKey.mgdl] as? Double, let mill = json[JSONKey.mills] as? Double else {
            return nil
        }
        
        let device = Device(rawValue: deviceString) ?? .unknown
        
        return MeteredGlucoseValue(milliseconds: mill, device: device, mgdl: mgdl)
    }
    
}

extension SensorGlucoseValue: Encodable, Decodable {
    struct JSONKey {
        static let device = "device"
        static let rssi = "rssi"
        static let filtered = "filtered"
        static let unfiltered = "unfiltered"
        static let direction = "direction"
        static let noise = "noise"
        static let mills = "date" //"mills"
        static let mgdl = "sgv" //"mgdl"
    }
    
    public func encode() -> [String : Any] {
        return [JSONKey.device: device.description, JSONKey.direction: direction.rawValue, JSONKey.filtered: filtered, JSONKey.mills: milliseconds, JSONKey.noise: noise.rawValue, JSONKey.rssi: rssi, JSONKey.unfiltered: unfiltered, JSONKey.mgdl: mgdl]
    }
    
    public static func decode(_ dict: [String : Any]) -> SensorGlucoseValue? {
        let json = dict
        
        guard let deviceString = json[JSONKey.device] as? String, let mgdl = json[JSONKey.mgdl] as? Double, let mill = json[JSONKey.mills] as? Double, let directionString = json[JSONKey.direction] as? String else {
            return nil
        }
        
        let filtered = json[JSONKey.filtered] as? Double ?? 0
        let noiseInt = json[JSONKey.noise] as? Int ?? 0
        let rssi = json[JSONKey.rssi] as? Int ?? 0
        let unfiltered = json[JSONKey.unfiltered] as? Double ?? 0
        
        let device = Device(rawValue: deviceString) ?? .unknown
        let direction = Direction(rawValue: directionString) ?? .none
        let noise = Noise(rawValue: noiseInt) ?? .unknown

        return SensorGlucoseValue(direction: direction, device: device, rssi: rssi, unfiltered: unfiltered, filtered: filtered, mgdl: mgdl, noise: noise, milliseconds: mill)
    }
}

extension DeviceStatus: Encodable, Decodable {
    struct JSONKey {
        static let devicestatus = "devicestatus"
        static let mills = "mills"
        static let uploader = "uploader"
        static let uploaderBattery = "uploaderBattery"
        
        static let battery = "battery"
        
        static let created_at = "created_at"
        
    }
    
    public func encode() -> [String : Any] {
        return [JSONKey.mills: milliseconds, JSONKey.uploaderBattery: uploaderBattery]
    }
    
    public static func decode(_ dict: [String : Any]) -> DeviceStatus? {
        let json = dict
        
        guard let uploaderBattery = json[JSONKey.uploaderBattery] as? Int else {
            return nil
        }
        
        var mills: Mills?
        if let created = json[JSONKey.created_at] as? String {
            mills = AppConfiguration.serverTimeDateFormatter.date(from: created)?.timeIntervalSince1970.millisecond
        } else if let intMills = json["mills"] as? Int {
            mills = Mills(intMills)
        } else {
            return nil
        }
        
        /*
         guard let mills = json[JSONKey.mills].double, let uploaderBattery = json[JSONKey.uploaderBattery].int else {
         return nil
         }
         */
        /*
        guard let mills = AppConfiguration.serverTimeDateFormatter.date(from: created)?.timeIntervalSince1970.millisecond else {
            return nil
        }*/
        
        return DeviceStatus(uploaderBattery: uploaderBattery, milliseconds: mills!)
    }
}



extension ComplicationTimelineEntry: Encodable, Decodable {
    struct JSONKey {
        static let lastReadingDate = "lastReadingDate"
        static let rawHidden = "rawHidden"
        static let rawLabel = "rawLabel"
        static let nameLabel = "nameLabel"
        static let sgvLabel = "sgvLabel"
        static let deltaLabel = "deltaLabel"
        static let rawColor = "rawColor"
        static let sgvColor = "sgvColor"
        static let units = "units"
        static let noise = "noise"
        static let direction = "direction"
        
    }
    
    public func encode() -> [String : Any] {
        return [
            JSONKey.lastReadingDate: lastReadingDate,
            JSONKey.rawLabel: rawLabel,
            JSONKey.nameLabel: nameLabel,
            JSONKey.sgvLabel: sgvLabel,
            JSONKey.deltaLabel: deltaLabel,
            JSONKey.sgvColor: sgvColor.toHexString(),
            JSONKey.units: units.rawValue,
            JSONKey.direction: direction.rawValue,
            JSONKey.noise: rawNoise.rawValue
        ]
    }
    
    public static func decode(_ dict: [String : Any]) -> ComplicationTimelineEntry? {
        
        let json = dict
        
        return ComplicationTimelineEntry(
            date: dict[JSONKey.lastReadingDate] as! Date,
            rawLabel: json[JSONKey.rawLabel] as? String,
            nameLabel: json[JSONKey.nameLabel] as! String,
            sgvLabel: json[JSONKey.sgvLabel] as! String,
            deltaLabel: json[JSONKey.deltaLabel] as! String,
            tintColor: Color(hexString: json[JSONKey.sgvColor] as! String),
            units: GlucoseUnit(rawValue: json[JSONKey.units] as! String),
            direction:  Direction(rawValue: json[JSONKey.direction] as! String) ?? .none,
            noise:  Noise(rawValue: json[JSONKey.noise] as! Int) ?? .unknown
        )
    }
}





