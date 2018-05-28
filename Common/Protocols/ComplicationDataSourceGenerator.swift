//
//  ComplicationDataSourceGenerator.swift
//  Nightscouter
//
//  Created by Peter Ina on 3/10/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public protocol ComplicationDataSourceGenerator {
    var oldestComplicationData: ComplicationTimelineEntry? { get }
    var latestComplicationData: ComplicationTimelineEntry? { get }
    var complicationUpdateInterval: TimeInterval { get }
    func nearest(calibration cals: [Calibration], forDate date: Date) -> Calibration?
    
    func generateComplicationData(with serverConfiguration: ServerConfiguration, sensorGlucoseValues: [SensorGlucoseValue], calibrations: [Calibration]) -> [ComplicationTimelineEntry]
}

// MARK: Complication Data Source


public extension ComplicationDataSourceGenerator {
    var complicationUpdateInterval: TimeInterval { return 60.0 * 30.0 }
    
    var nextRequestedComplicationUpdateDate: Date {
        guard let latestComplicationData = latestComplicationData else {
            return Date(timeIntervalSinceNow: complicationUpdateInterval)
        }
        
        return latestComplicationData.date.addingTimeInterval(complicationUpdateInterval)
    }
    
    func nearest(calibration cals: [Calibration], forDate date: Date) -> Calibration? {
        if cals.isEmpty {
            return nil
        }
        
        var desiredIndex: Int?
        var minDate: TimeInterval = fabs(Date().timeIntervalSinceNow)
        for (index, cal) in cals.enumerated() {
            let dateInterval = fabs(cal.date.timeIntervalSince(date))
            let compared = minDate < dateInterval
            if compared {
                minDate = dateInterval
                desiredIndex = index
            }
        }
        guard let index = desiredIndex else {
            print("NON-FATAL ERROR: No valid index was found... return first calibration if its there.")
            return cals.first
        }
        return cals[safe: index]
    }
    
    public func generateComplicationData(with serverConfiguration: ServerConfiguration, sensorGlucoseValues: [SensorGlucoseValue], calibrations: [Calibration]) -> [ComplicationTimelineEntry] {
        
        let configuration = serverConfiguration
        let sgvs = sensorGlucoseValues
        
        // Init Complication Model Array for return as Timeline.
        var compModels: [ComplicationTimelineEntry] = []
        
        // Get prfered Units for site.
        let units = configuration.displayUnits
        
        // Setup thresholds for proper color coding.
        let thresholds: Thresholds = configuration.settings?.thresholds ?? Thresholds(bgHigh: 300, bgLow: 70, bgTargetBottom: 60, bgTargetTop: 250)
        
        // Iterate through provided Sensor Glucose Values to create a timeline.
        for (index, sgv) in sgvs.enumerated() where index < 2 {
            
            // Create a color for a given SGV value.
            let sgvColor = thresholds.desiredColorState(forValue: sgv.mgdl)
            
            // Set the date required by the Complication Data Source (for Timeline)
            let date = sgv.date
            
            // Convet Sensor Glucose Value to a proper string. Always start with a mgd/L number then convert to a mmol/L
            var sgvString = sgv.mgdl.formattedForMgdl
            if units == .mmol {
                sgvString = sgv.mgdl.formattedForMmol
            }
            
            //
            // END of Delta Calculation
            //
            // Init Delta var.
            var delta: MgdlValue = 0
            
            // Get the next index position which would be a previous or older reading.
            let previousIndex: Int = index + 1
            // If the next index is a valid object and the number is safe.
            if let previousSgv = sgvs[safe: previousIndex] , sgv.isGlucoseValueOk {
                delta = sgv.mgdl - previousSgv.mgdl
            }
            // Convert to proper units
            if units == .mmol {
                delta = delta.toMmol
            }
            
            // Create strings if the sgv is ok. Otherwise clear it out.
            let deltaString = sgv.isGlucoseValueOk ? "(" + delta.formattedBGDelta(forUnits: units) + ")" : ""
            
            // END of Delta Calculation
            //
            
            //
            // Start of Raw Calculation
            //
            // Init Raw String var
            var rawString: String = ""
            
            // Get nearest calibration for a given sensor glucouse value's date.
            if let calibration = nearest(calibration: calibrations, forDate: sgv.date as Date) {
                
                // Calculate Raw BG for a given calibration.
                let raw = sgv.calculateRaw(withCalibration: calibration) //calculateRawBG(fromSensorGlucoseValue: sgv, calibration: calibration)
                var rawFormattedString = raw.formattedForMgdl
                // Convert to correct units.
                if units == .mmol {
                    rawFormattedString = raw.formattedForMmol
                }
                // Create string representation of raw data.
                rawString = rawFormattedString
            }
            
            let compModel = ComplicationTimelineEntry(date: date, rawLabel: rawString, nameLabel: configuration.displayName, sgvLabel: sgvString, deltaLabel: deltaString, tintColor: sgvColor.colorValue, units: units, direction: sgv.direction ?? .none, noise: sgv.noise ?? Noise.unknown)
            
            compModels.append(compModel)
        }
        
        /*
         let settings = configuration.settings ?? ServerConfiguration().settings!
         
         // Get the latest model and use to create stale complication timeline entries.
         let model = compModels.max{ (lModel, rModel) -> Bool in
         return rModel.date.compare(lModel.date as Date) == .orderedDescending
         }
         
         
         if let model = model {
         // take last date and extend out 15 minutes.
         if settings.timeAgo.warn {
         let warnTime = settings.timeAgo.warnMins
         let warningStaleDate = model.date.addingTimeInterval(warnTime)
         let warnItem = ComplicationTimelineEntry(date: warningStaleDate, rawLabel: "Please update.", nameLabel: "Data missing.", sgvLabel: "Warning", deltaLabel: "", tintColor: DesiredColorState.warning.colorValue, units: .mgdl, direction: .none, noise: .none)
         compModels.append(warnItem)
         }
         
         if settings.timeAgo.urgent {
         // take last date and extend out 30 minutes.
         let urgentTime = settings.timeAgo.urgentMins
         let urgentStaleDate = model.date.addingTimeInterval(urgentTime)
         let urgentItem = ComplicationTimelineEntry(date: urgentStaleDate, rawLabel: "Please update.", nameLabel: "Data missing.", sgvLabel: "Urgent", deltaLabel: "", tintColor: DesiredColorState.alert.colorValue, units: .mgdl, direction: .none, noise: .none)
         compModels.append(urgentItem)
         }
         }*/
        
        // compModels.sorted()
        
        return compModels
    }
    
}


extension Site: ComplicationDataSourceGenerator {
    @discardableResult
     public mutating func generateComplicationData() -> [ComplicationTimelineEntry] {
        
        //if !self.updateNow { return self.complicationTimeline }
        
        guard let configuration = self.configuration else {
            return []
        }
        self.complicationTimeline = generateComplicationData(with: configuration, sensorGlucoseValues: sgvs, calibrations: cals)
        
        return self.complicationTimeline
    }
    
    public var latestComplicationData: ComplicationTimelineEntry? {
        let complicationModels: [ComplicationTimelineEntry] = self.complicationTimeline // ?? []
        
        return sortByDate(complicationModels).first
    }
    
    public var oldestComplicationData: ComplicationTimelineEntry? {
        let complicationModels: [ComplicationTimelineEntry] = self.complicationTimeline // ?? []
        
        return sortByDate(complicationModels).last
    }
    
}
