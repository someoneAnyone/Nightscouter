//
//  NightscoutAppDataManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 12/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

let updateInterval: NSTimeInterval = Constants.NotableTime.StandardRefreshTime
public let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)


/**
 Fetch the metadata for a given site.
 The handler will always return on the main thread
 
 - parameter site: Destination site for which we are querying
 - parameter handler: closure with the resulting site or an error as parameters

 
 - returns: none
 */
public func quickFetch(site: Site, handler: (returnedSite: Site, error: NightscoutAPIError) -> Void) {
    dispatch_async(queue) {
        print(">>> Entering \(#function) <<<")
        print("STARTING quickFetch:    Load all available site data for: \(site.url)")
        
        let nsAPI = NightscoutAPIClient(url: site.url)
        var errorToReturn: NightscoutAPIError = .NoError
        let startDate = NSDate()
        
        print("STEP 1:  GET Sever Status/Configuration")
        
        nsAPI.fetchServerConfiguration { (result) -> Void in
            switch result {
            case .Error:
                site.disabled = true
                errorToReturn = NightscoutAPIError.DownloadErorr("No configuration was found")
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    handler(returnedSite: site, error: errorToReturn)
                })
            case let .Value(boxedConfiguration):
                let configuration = boxedConfiguration.value
                site.configuration = configuration
                print("\tSTEP 2: GET Sever Pebble/Watch")
        
                nsAPI.fetchDataForWatchEntry({ (watchEntry, errorCode) -> Void in
                    site.watchEntry = watchEntry
                    errorToReturn = errorCode
                
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        print("\t\t\t\t\tCOMPLETE:    All network operations are complete ")
                        print("\t\t\t\t\tDURATION:    The entire process took: \(NSDate().timeIntervalSinceDate(startDate))")
                        print("\t\t\t\t\tSTEP 6 quickFetch:      Return Handler to main thread.")
                        handler(returnedSite: site, error: errorToReturn)
                    })
                })
            }
        }
    }
}

/**
 Fetch the metadata, then entries then calibrations for a given site. The handler
 will always be called on the main thread
 
 - parameter site: Destination site for which we are querying
 - parameter handler: closure with the resulting site or an error as parameters
 
 - returns: none
 */
public func fetchSiteData(site: Site, handler: (returnedSite: Site, error: NightscoutAPIError) -> Void) {
    print(">>> Entering \(#function) <<<")
    print("STARTING fetchSiteData:    Load all available site data for: \(site.url)")
    let nsAPI = NightscoutAPIClient(url: site.url)
    var errorToReturn: NightscoutAPIError = .NoError
    let startDate = NSDate()
    quickFetch(site, handler: { (returnedSite, error) -> Void in
        print("\t\tSTEP 3: GET Sever Entries/SGVs ")
        nsAPI.fetchDataForEntries(Constants.EntryCount.NumberForComplication, completetion: { (entries, errorCode) -> Void in
            site.entries = entries
            errorToReturn = errorCode
            
            print("\t\t\tSTEP 4: GET Sever CALs/Calibrations")
            let numberOfCalsNeeded = ((Constants.EntryCount.NumberForComplication * 5) / 60) / 12 + 1
            nsAPI.fetchCalibrations(numberOfCalsNeeded, completetion: { (calibrations, errorCode) -> Void in
                errorToReturn = errorCode
                
                guard let calibrations = calibrations else {
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        handler(returnedSite: site, error: errorCode)
                    })
                    return
                }
                
                let cals = calibrations.sort{(item1:Entry, item2:Entry) -> Bool in
                    item1.date.compare(item2.date) == .OrderedDescending
                    }.flatMap { $0.cal }
                
                site.calibrations = cals
                
                print("\t\t\t\tSTEP 5: Generate Timeline data for Complication")
                let complicationModels = generateComplicationModels(forSite: site, calibrations: site.calibrations)
                site.complicationModels = complicationModels
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    print("\t\t\t\t\tCOMPLETE:    All network operations are complete")
                    print("\t\t\t\t\tDURATION:    The entire process took: \(NSDate().timeIntervalSinceDate(startDate))")
                    print("\t\t\t\t\tSTEP 6 fetchSiteData:      Return Handler to main thread.")
                    handler(returnedSite: site, error: errorToReturn)
                })
            })
        })
    })
}

public func generateComplicationModels(forSite site: Site, calibrations: [Calibration]) -> [ComplicationModel] {
    
    let cals = calibrations.sort{(item1: Calibration, item2: Calibration) -> Bool in
        item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
    }
    
    guard let configuration = site.configuration, entries = site.entries else {
        return []
    }
    
    var cmodels: [ComplicationModel] = []
    
    // Get prefered Units. mmol/L or mg/dL
    let units: Units = configuration.displayUnits
    
    for (index, entry) in entries.enumerate() {
        
        if let sgvValue = entry.sgv {
            
            // Convert units.
            let boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
            
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
            
            let deltaString = sgvValue.isSGVOk ? "(" + delta.formattedBGDelta(forUnits: units) + ")" : ""
            let deltaStringShort = sgvValue.isSGVOk ? "(" + delta.formattedBGDelta(forUnits: units, appendString: "∆") + ")" : ""
            let sgvColor = colorForDesiredColorState(boundedColor)
            
            var raw: String?
            var rawShort: String?
            
            if let cal = nearestCalibration(calibrations: cals, calibrationsforDate: entry.date) {
                
                var convertedRawValue: String = sgvValue.rawIsigToRawBg(cal).formattedForMgdl
                if configuration.displayUnits == .Mmol {
                    convertedRawValue = sgvValue.rawIsigToRawBg(cal).formattedForMmol
                }
                
                raw = "\(convertedRawValue) : \(sgvValue.noise.description)"
                rawShort = "\(convertedRawValue) : \(sgvValue.noise.description[sgvValue.noise.description.startIndex])"
            }
            
            cmodels.append(ComplicationModel(displayName: configuration.displayName, date: entry.date, sgv: sgvStringWithEmoji, sgvEmoji: sgvEmoji, tintString: sgvColor.toHexString(), delta: deltaString, deltaShort: deltaStringShort, raw: raw, rawShort: rawShort))
            
        }
    }
    
    
    /*
    let minModel = self.models.minElement { (lModel, rModel) -> Bool in
    return rModel.lastReadingDate < lModel.lastReadingDate
    }
    
    guard let model = minModel else {
    return
    }
    */
    
    let model = cmodels.maxElement{ (lModel, rModel) -> Bool in
        return rModel.date.compare(lModel.date) == .OrderedDescending
    }
    
    if let model = model {
        let warningStaleDate = model.date.dateByAddingTimeInterval(60.0 * 60)
        let warnItem = ComplicationModel(displayName:"Data Missing", date: warningStaleDate, sgv: "WARNING", sgvEmoji: " ", tintString: colorForDesiredColorState(.Warning).toHexString(), delta: " ", deltaShort: " ", raw: "Please update.", rawShort: "Please update.")
        
        let urgentStaleDate = model.date.dateByAddingTimeInterval(60.0 * 90)
        let urgentItem = ComplicationModel(displayName:"Data Missing", date: urgentStaleDate, sgv: "URGENT", sgvEmoji: " ", tintString: colorForDesiredColorState(.Alert).toHexString(), delta:" ", deltaShort: " ", raw: "Please update.", rawShort: "Please update.")

        cmodels.append(warnItem)
        cmodels.append(urgentItem)
    }
    
    
    cmodels.sortInPlace{(item1: ComplicationModel, item2: ComplicationModel) -> Bool in
        item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
    }
    
    
    return cmodels
}


private func nearestCalibration(calibrations cals:[Calibration], calibrationsforDate date: NSDate) -> Calibration? {
    
    if cals.isEmpty { return nil }
    
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
        print("NON-FATAL ERROR: No valid index was found... return last calibration if its there.")
        return cals.first
    }
    
    // print("incoming date: \(closestDate.timeIntervalSinceNow) returning date: \(calibrations[index].date.timeIntervalSinceNow)")
    return cals[index]
}

