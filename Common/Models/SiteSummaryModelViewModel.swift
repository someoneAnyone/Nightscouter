//
//  File.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/14/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//
import Foundation

public struct SiteAlarmModel {
    public var warn: Bool = false
    public var urgent: Bool = false
    public var alarmForSGV: Bool = false
    
    public var isAlarming: Bool {
        return warn || urgent || alarmForSGV
    }
}

public extension Site {
    
    public var alarmDetails: SiteAlarmModel {
        get {
            guard let configuration = configuration, let settings = configuration.settings, let latestSgv = sgvs.first else {
                return SiteAlarmModel()
            }
            
            let timeAgo = latestSgv.date.timeIntervalSinceNow
            let isStaleData = settings.timeAgo.isDataStaleWith(interval: timeAgo)
            let thresholds: Thresholds = settings.thresholds
            let sgvColorVar = thresholds.desiredColorState(forValue: latestSgv.mgdl)
            
            var alarmForSGV: Bool = false

            var urgent: Bool = isStaleData.urgent
            
            if sgvColorVar == .alert || sgvColorVar == .warning {
                alarmForSGV = true
                urgent = (sgvColorVar == .alert)
            } else if !latestSgv.isGlucoseValueOk {
                alarmForSGV = true
            }
            
            return SiteAlarmModel(warn: isStaleData.warn, urgent: urgent, alarmForSGV: alarmForSGV)
        }
    }
    
}

public struct SiteSummaryModelViewModel: SiteSummaryModelViewModelDataSource, SiteSummaryModelViewModelDelegate {
    
    public var lastReadingDate: Date
    
    public var batteryHidden: Bool
    public var batteryLabel: String
    public var nameLabel: String
    public var urlLabel: String
    public var sgvLabel: String
    public var deltaLabel: String
    
    public var rawHidden: Bool
    public var rawLabel: String
    public var rawNoise: Noise
    
    public var lastReadingColor: Color
    public var batteryColor: Color
    
    public var sgvColor: Color
    public var deltaColor: Color
    
    public var rawColor: Color
    
    public var direction: Direction
    public var text: String
    public var detailText: String
    public var lookStale: Bool
    public var desiredColor: DesiredColorState
    
    public init(withSite site: Site) {
        
        let displayUrlString = site.url.host ?? site.url.absoluteString
        
        guard let configuration = site.configuration, let settings = configuration.settings else {
            
            // Last Reading
            self.lastReadingDate = Date(timeIntervalSince1970: AppConfiguration.Constant.knownMilliseconds/1000)
            self.lastReadingColor = PlaceHolderStrings.defaultColor.colorValue
            
            // Raw
            self.rawLabel = PlaceHolderStrings.raw
            self.rawColor = PlaceHolderStrings.defaultColor.colorValue
            self.rawHidden = false
            
            // Sgv
            self.sgvLabel = PlaceHolderStrings.sgv
            self.sgvColor = PlaceHolderStrings.defaultColor.colorValue
            
            // Battery
            self.batteryHidden = false
            self.batteryLabel = PlaceHolderStrings.battery
            self.batteryColor = PlaceHolderStrings.defaultColor.colorValue
            
            // Name and URL
            self.nameLabel = PlaceHolderStrings.displayName
            self.urlLabel = displayUrlString
            
            // Delta
            self.deltaLabel = PlaceHolderStrings.delta
            self.deltaColor = PlaceHolderStrings.defaultColor.colorValue
            
            // Compass
            self.detailText = self.deltaLabel
            self.desiredColor = PlaceHolderStrings.defaultColor
            self.lookStale = false
            self.direction = .none
            self.text = self.sgvLabel
            self.rawNoise = Noise.none
            
            return
        }
        
        let units: GlucoseUnit = configuration.displayUnits
        let displayName: String = configuration.displayName
        let isRawDataAvailable = configuration.displayRawData && !site.cals.isEmpty
        
        var deltaString: String?
        var lastReadingDate: Date?
        var sgvString: String?
        var rawString: String?
        var rawNoise: Noise?
        var batteryString: String?
        var direction: Direction?
        
        var lastReadingColorVar: DesiredColorState?
        var rawColorVar: DesiredColorState?
        var sgvColorVar: DesiredColorState?
        var batteryColorVar: DesiredColorState?
        
        var isStaleData: (warn: Bool, urgent: Bool) = (false, false)
        
        if let latestSgv = site.sgvs.first {
            let thresholds: Thresholds = settings.thresholds
            sgvColorVar = thresholds.desiredColorState(forValue: latestSgv.mgdl)
            
            lastReadingDate = latestSgv.date as Date
            
            direction = latestSgv.direction
            
            var delta: MgdlValue = 0
            if let previousSgv = site.sgvs[safe:1] , latestSgv.isGlucoseValueOk {
                delta = latestSgv.mgdl - previousSgv.mgdl
            }
            
            sgvString = latestSgv.mgdl.formattedForMgdl
            
            if units == .mmol {
                sgvString = latestSgv.mgdl.formattedForMmol
                delta = delta.toMmol
            }
            
            deltaString = delta.formattedBGDelta(forUnits: units)
            
            if let latestCalibration = site.cals.first {
                let raw = calculateRawBG(fromSensorGlucoseValue: latestSgv, calibration: latestCalibration)
                rawColorVar = thresholds.desiredColorState(forValue: raw)
                
                var rawFormattedString = "\(raw.formattedForMgdl)"
                if configuration.displayUnits == .mmol {
                    rawFormattedString = raw.formattedForMmol
                }
                
                rawString = rawFormattedString
                rawNoise = latestSgv.noise
            }
            
            if let deviceStatus = site.deviceStatuses.first {
                batteryString = deviceStatus.batteryLevel
                batteryColorVar = deviceStatus.desiredColorState
            }
            
            // Calculate if the lastest watch entry we got from the server is stale.
            let timeAgo = latestSgv.date.timeIntervalSinceNow
            isStaleData = settings.timeAgo.isDataStaleWith(interval: timeAgo)
            
            if isStaleData.warn {
                batteryString = PlaceHolderStrings.battery
                batteryColorVar = .neutral
                
                rawString = PlaceHolderStrings.raw
                rawColorVar = .neutral
                rawNoise = .none
                
                deltaString = PlaceHolderStrings.delta
                
                direction = .none
                sgvString = PlaceHolderStrings.sgv
                sgvColorVar = .neutral
                lastReadingColorVar = DesiredColorState.warning
            }
            
            // Piles on to whatever warn did.
            if isStaleData.urgent{
                lastReadingColorVar = DesiredColorState.alert
            }
            
        }
        
        self.lastReadingDate = lastReadingDate ?? Date(timeIntervalSince1970: AppConfiguration.Constant.knownMilliseconds)
        self.lastReadingColor = lastReadingColorVar?.colorValue ?? PlaceHolderStrings.defaultColor.colorValue
        
        self.rawLabel = rawString ?? PlaceHolderStrings.raw
        self.rawColor = rawColorVar?.colorValue ?? PlaceHolderStrings.defaultColor.colorValue
        self.rawHidden = !isRawDataAvailable
        
        self.sgvLabel = sgvString ?? PlaceHolderStrings.sgv
        self.sgvColor = sgvColorVar?.colorValue ?? PlaceHolderStrings.defaultColor.colorValue
        
        self.batteryLabel = batteryString ?? PlaceHolderStrings.battery
        self.batteryColor = batteryColorVar?.colorValue ?? PlaceHolderStrings.defaultColor.colorValue
        
        self.nameLabel = displayName //?? PlaceHolderStrings.displayName
        self.urlLabel = displayUrlString// ?? PlaceHolderStrings.urlName
        
        self.deltaLabel = deltaString ?? PlaceHolderStrings.delta
        self.deltaColor = sgvColorVar?.colorValue ?? PlaceHolderStrings.defaultColor.colorValue
        
        self.detailText = self.deltaLabel
        self.desiredColor = sgvColorVar ?? PlaceHolderStrings.defaultColor
        self.lookStale = isStaleData.warn
        self.direction = direction ?? Direction.none
        self.text = self.sgvLabel
        
        self.rawNoise = rawNoise ?? Noise.none
        
        self.batteryHidden = site.deviceStatuses.isEmpty
    }
}
