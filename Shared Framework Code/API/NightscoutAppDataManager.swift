//
//  NightscoutAppDataManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 12/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

let updateInterval: NSTimeInterval = Constants.NotableTime.StandardRefreshTime
public let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


public func quickFetch(site: Site, handler: (returnedSite: Site, error: NightscoutAPIError) -> Void) {
    dispatch_async(queue) {
        print(">>> Entering \(__FUNCTION__) <<<")
        print("Loading all site data for site: \(site.url)")
        let group: dispatch_group_t = dispatch_group_create()
        
        let nsAPI = NightscoutAPIClient(url: site.url)
        
        var errorToReturn: NightscoutAPIError = .NoError
        
        dispatch_group_enter(group)
        print("GET Sever Status/Configuration")
        nsAPI.fetchServerConfiguration { (result) -> Void in
            switch result {
            case .Error:
                site.disabled = true
                errorToReturn = NightscoutAPIError.DownloadErorr("No configuration was found")
                handler(returnedSite: site, error: errorToReturn)
            case let .Value(boxedConfiguration):
                let configuration = boxedConfiguration.value
                site.configuration = configuration
            }
            
            dispatch_group_leave(group)
        }
        
        if site.disabled == false {
            
            dispatch_group_enter(group)
            print("GET Sever Pebble/Watch")
            nsAPI.fetchDataForWatchEntry({ (watchEntry, errorCode) -> Void in
                site.watchEntry = watchEntry
                
                errorToReturn = errorCode
                dispatch_group_leave(group)
            })
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            print("All network operations are complete.")
            handler(returnedSite: site, error: errorToReturn)
        }
    }
}


public func fetchSiteData(site: Site, handler: (returnedSite: Site, error: NightscoutAPIError) -> Void) {
    dispatch_async(queue) {
        print(">>> Entering \(__FUNCTION__) <<<")
        print("Loading all site data for site: \(site.url)")
        let group: dispatch_group_t = dispatch_group_create()
        
        let nsAPI = NightscoutAPIClient(url: site.url)
        
        var errorToReturn: NightscoutAPIError = .NoError
        
        dispatch_group_enter(group)
        print("GET Sever Status/Configuration")
        nsAPI.fetchServerConfiguration { (result) -> Void in
            switch result {
            case .Error:
                site.disabled = true
                errorToReturn = NightscoutAPIError.DownloadErorr("No configuration was found")
                handler(returnedSite: site, error: errorToReturn)
            case let .Value(boxedConfiguration):
                let configuration = boxedConfiguration.value
                site.configuration = configuration
            }
            
            dispatch_group_leave(group)
        }
        
        if site.disabled == false {
            
            dispatch_group_enter(group)
            print("GET Sever Pebble/Watch")
            nsAPI.fetchDataForWatchEntry({ (watchEntry, errorCode) -> Void in
                site.watchEntry = watchEntry
                
                errorToReturn = errorCode
                dispatch_group_leave(group)
            })
            
            dispatch_group_enter(group)
            print("GET Sever Entries/SGVs")
            nsAPI.fetchDataForEntries(Constants.EntryCount.NumberForComplication, completetion: { (entries, errorCode) -> Void in
                site.entries = entries
                errorToReturn = errorCode
                dispatch_group_leave(group)
            })
            
            dispatch_group_enter(group)
            print("GET Sever CALs/Calibrations")
            let numberOfCalsNeeded = ((Constants.EntryCount.NumberForComplication * 5) / 60) / 12 + 1
            nsAPI.fetchCalibrations(numberOfCalsNeeded, completetion: { (calibrations, errorCode) -> Void in
                errorToReturn = errorCode
                if let calibrations = calibrations {
                    let cals = calibrations.sort{(item1:Entry, item2:Entry) -> Bool in
                        item1.date.compare(item2.date) == .OrderedDescending
                        }.flatMap { $0.cal }
                    
                    site.calibrations = cals
                }
                dispatch_group_leave(group)
            })
            
        }
        
        let group2: dispatch_group_t = dispatch_group_create()
        dispatch_group_enter(group2)
        dispatch_group_notify(group, queue) {
            print("Generate Timeline data for Complication")
            let complicationModels = generateComplicationModels(forSite: site, calibrations: site.calibrations)
            site.complicationModels = complicationModels
            dispatch_group_leave(group2)

        }
        
        dispatch_group_notify(group2, dispatch_get_main_queue()) {
            print("All network operations are complete.")
            handler(returnedSite: site, error: errorToReturn)
        }
    }
}

private func generateComplicationModels(forSite site: Site, calibrations: [Calibration]) -> [ComplicationModel] {
    
    let cals = calibrations.sort{(item1: Calibration, item2: Calibration) -> Bool in
        item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
    }
    
    guard let configuration = site.configuration, displayName = site.configuration?.displayName, entries = site.entries else {
        return []
    }
    
    var cmodels: [ComplicationModel] = []
    
    // Get prefered Units. mmol/L or mg/dL
    let units: Units = configuration.displayUnits
    
    for (index, entry) in entries.enumerate() {
        
        if let sgvValue = entry.sgv {
            
            // Convert units.
            var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
            if units == .Mmol {
                boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
            }
            
            
            var sgvString = "\(sgvValue.sgv.formattedForMgdl)"
            if configuration.displayUnits == .Mmol {
                sgvString = sgvValue.sgv.formattedForMmol
            }
            
            sgvString =  "\(sgvValue.sgvString(forUnits: units))"
            let sgvEmoji = "\(sgvValue.direction.emojiForDirection)"
            let sgvStringWithEmoji = "\(sgvString) \(sgvValue.direction.emojiForDirection)"
            
            var delta: Double = 0
            
            let nextIndex: Int = index + 1
            
            if nextIndex < entries.count {
                if let previousSgv = entries[nextIndex].sgv {
                    if sgvValue.isSGVOk && previousSgv.isSGVOk {
                        delta = sgvValue.sgv - previousSgv.sgv
                    }
                }
            }
            
            if configuration.displayUnits == .Mmol {
                delta = delta.toMmol
            }
            
            let deltaString = delta.formattedBGDelta(forUnits: units)
            let deltaStringShort = delta.formattedBGDelta(forUnits: units, appendString: "∆")
            let sgvColor = colorForDesiredColorState(boundedColor)
            
            var raw = ""
            var rawShort = ""
            
            if let cal = nearestCalibration(calibrations: cals, calibrationsforDate: entry.date) {
                
                var convertedRawValue: String = sgvValue.rawIsigToRawBg(cal).formattedForMgdl
                if configuration.displayUnits == .Mmol {
                    convertedRawValue = sgvValue.rawIsigToRawBg(cal).formattedForMmol
                }
                
                raw = "\(convertedRawValue) : \(sgvValue.noise.description)"
                rawShort = "\(convertedRawValue) : \(sgvValue.noise.description[sgvValue.noise.description.startIndex])"
            }
            
            let model = ComplicationModel(displayName: displayName, date: entry.date, sgv: sgvStringWithEmoji, sgvEmoji: sgvEmoji, tintString: sgvColor.toHexString(), delta: deltaString, deltaShort: deltaStringShort, raw: raw, rawShort: rawShort)
            
            cmodels.append( model)
            
        }
        
    }
    return cmodels
}


private func nearestCalibration(calibrations cals:[Calibration], calibrationsforDate date: NSDate) -> Calibration? {
    var desiredIndex: Int?
    var minDate: NSTimeInterval = fabs(NSDate().timeIntervalSinceNow)
    
    for (index, entry) in cals.enumerate() {
        let dateInterval = fabs(entry.date.timeIntervalSinceDate(date))
        let compared = minDate < dateInterval
        // print("Testing: \(minDate) < \(dateInterval) = \(compared)")
        if compared {
            minDate = dateInterval
            desiredIndex = index
        }
    }
    
    guard let index = desiredIndex else {
        print("no valid index was found... return last calibration")
        return cals.first
    }
    
    // print("incoming date: \(closestDate.timeIntervalSinceNow) returning date: \(calibrations[index].date.timeIntervalSinceNow)")
    return cals[index]
}

