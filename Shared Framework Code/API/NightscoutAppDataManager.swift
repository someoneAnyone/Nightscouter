//
//  NightscoutAppDataManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 12/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import Foundation

let updateInterval: NSTimeInterval = Constants.NotableTime.StandardRefreshTime


public func fetchSiteData(forSite site: Site, index: Int? = nil, forceRefresh: Bool = false, handler:(reloaded: Bool, returnedSite: Site, returnedIndex: Int?, returnedError: NSError?) -> Void) -> Void {
    
    var siteToReturn: Site = site
    let indexToReturn: Int? = index
    var errorToReturn: NSError? = nil
    var successfullyReloaded: Bool = false

    // Don't fetch data if its within the standard refresh time frame.
    // This can be orrvidden by the forceRefresh param.
    if let lastConnectedDate = site.lastConnectedDate  where forceRefresh == false {
        let nextUpdateDate = NSDate(timeIntervalSinceNow: updateInterval)
        if lastConnectedDate.compare(nextUpdateDate) == .OrderedAscending {
            errorToReturn = NSError(domain: "Attemping to update site data too soon.", code: 0, userInfo: nil)
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                handler(reloaded: successfullyReloaded, returnedSite: siteToReturn, returnedIndex: indexToReturn, returnedError: errorToReturn)
            })
            return
        }
    }
    
    // Get the HTTP Client.
    let nsApi = NightscoutAPIClient(url: site.url)
    
    // get site data that incluldes chart data.
    loadDataFor(site, index: index, withEntries: true, completetion: { (returnedSite, returnedIndex, returnedError) -> Void in
        
        errorToReturn = returnedError
        guard let site = returnedSite else {
            
            successfullyReloaded = true
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                handler(reloaded: successfullyReloaded, returnedSite: siteToReturn, returnedIndex: indexToReturn, returnedError: errorToReturn)
            })
            return
        }
        
        let numberOfCalsNeeded = ((Constants.EntryCount.NumberForComplication * 5) / 60) / 12
        
        nsApi.fetchCalibrations(numberOfCalsNeeded, completetion: { (calibrations, errorCode) -> Void in

            guard let calibrations = calibrations else {
                errorToReturn = NSError(domain: "No calibrations were found", code: 0, userInfo: nil)
                return
            }

            let models = generateComplicationModels(forSite: site, calibrations: calibrations.flatMap{ $0.cal } ?? [])
            
            let cals = calibrations.sort{(item1:Entry, item2:Entry) -> Bool in
                item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
                }.flatMap { $0.cal }

            returnedSite?.complicationModels = models
            returnedSite?.calibrations = cals
            
            successfullyReloaded = true
            siteToReturn = returnedSite ?? site
            errorToReturn = returnedError
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                handler(reloaded: successfullyReloaded, returnedSite: siteToReturn, returnedIndex: indexToReturn, returnedError: errorToReturn)
            })
            
            return
        })
    })
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


public func loadDataFor(model: WatchModel, replyHandler:(model: WatchModel) -> Void) {
    print(">>> Entering \(__FUNCTION__) <<<")
    
    // Start up the API
    let url = NSURL(string: model.urlString)!
    let site = Site(url: url, apiSecret: nil)!
    
    loadDataFor(site, index: nil) { (returnedSite, returnedIndex, returnedError) -> Void in
        
        guard let site = returnedSite else {
            return
        }
        
        replyHandler(model: site.viewModel)
    }
}


private func loadDataFor(site: Site, index: Int?, withEntries: Bool = false, completetion:(returnedSite: Site?, returnedIndex: Int?, returnedError: NSError?) -> Void) {
    // Start up the API
    let nsApi = NightscoutAPIClient(url: site.url)
    //TODO: 1. There should be reachabiltiy checks before doing anything.
    //TODO: 2. We should fail gracefully if things go wrong. Need to present a UI for reporting errors.
    //TODO: 3. Probably need to move this code to the application delegate?
    
    // Get settings for a given site.
    print("Loading data for \(site.url)")
    nsApi.fetchServerConfiguration { (result) -> Void in
        switch (result) {
        case let .Error(error):
            // display error message
            print("loadUpData ERROR recieved: \(error)")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                site.disabled = true
                completetion(returnedSite: nil, returnedIndex: index, returnedError: error)
            })
            
        case let .Value(boxedConfiguration):
            let configuration:ServerConfiguration = boxedConfiguration.value
            // do something with user
            nsApi.fetchDataForWatchEntry({ (watchEntry, watchEntryErrorCode) -> Void in
                // Get back on the main queue to update the user interface
                site.configuration = configuration
                site.watchEntry = watchEntry
                
                if !withEntries {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completetion(returnedSite: site, returnedIndex: index, returnedError: nil)
                    })
                } else {
                    
                    nsApi.fetchDataForEntries(Constants.EntryCount.NumberForComplication) { (entries, errorCode) -> Void in
                        if let entries = entries {
                            site.entries = entries
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completetion(returnedSite: site, returnedIndex: index, returnedError: nil)
                            })
                        }
                    }
                }
            })
        }
    }
    
}
