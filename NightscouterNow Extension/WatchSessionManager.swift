//
//  WatchSessionManager.swift
//  WCApplicationContextDemo
//
//  Created by Natasha Murashev on 9/22/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity
import ClockKit
import NightscouterWatchOSKit

@available(watchOS 2.0, *)
public protocol DataSourceChangedDelegate {
    func dataSourceDidUpdateAppContext(models: [WatchModel])
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    public var defaultSite: NSUUID? {
        set {
            sharedDefaults?.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        }
        get {
            guard let uuidString = sharedDefaults?.objectForKey(DefaultKey.defaultSiteKey) as? String else {
                if let firstModel = models.first {
                    return NSUUID(UUIDString: firstModel.uuid)
                }
                return nil
            }
            
            return NSUUID(UUIDString: uuidString)
        }
    }
    
    public var currentSiteIndex: Int {
        set {
            sharedDefaults?.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
        }
        get {
            return sharedDefaults?.integerForKey(DefaultKey.currentSiteIndexKey) ?? 0
        }
    }
    
    private let sharedDefaults = NSUserDefaults(suiteName: "group.com.nothingonline.nightscouter")
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        
//        if let dictArray = sharedDefaults?.objectForKey(DefaultKey.modelArrayObjectsKey) as? [[String: AnyObject]] {
//            print("Loading models from default.")
//            models = dictArray.map({ WatchModel(fromDictionary: $0)! })
//        }
//        if let item = session.outstandingUserInfoTransfers.first {
//            processApplicationContext(item.userInfo)
//        }
        
        sharedDefaults?.setObject("watchOS", forKey: "osPlatform")
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    private let session: WCSession = WCSession.defaultSession()
    
    // private var sites: [Site] = []
    
    public var models: [WatchModel] {
        set{
            let dictArray = models.map{ $0.dictionary }
            sharedDefaults?.setObject(dictArray, forKey: DefaultKey.modelArrayObjectsKey)

            self.createComplicationData()
            
            
        }
        get {
            guard let dictArray = sharedDefaults?.objectForKey(DefaultKey.modelArrayObjectsKey) as? Array<[String: AnyObject]> else {
                return []
            }
            return dictArray.flatMap{ WatchModel(fromDictionary: $0) }
        }
    }
    
    private var calibrations: [Entry] = []
    
    public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activateSession()
            
            requestLatestAppContext()
        }
    }
    
    public func addDataSourceChangedDelegate<T where T: DataSourceChangedDelegate, T: Equatable>(delegate: T) {
        dataSourceChangedDelegates.append(delegate)
    }
    
    public func removeDataSourceChangedDelegate<T where T: DataSourceChangedDelegate, T: Equatable>(delegate: T) {
        for (index, indexDelegate) in dataSourceChangedDelegates.enumerate() {
            if let indexDelegate = indexDelegate as? T where indexDelegate == delegate {
                dataSourceChangedDelegates.removeAtIndex(index)
                break
            }
        }
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // print("didReceiveFile: \(file)")
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        // print("didReceiveUserInfo: \(userInfo)")
        processApplicationContext(userInfo)
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        // print("didReceiveApplicationContext: \(applicationContext)")
        processApplicationContext(applicationContext)
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        let success =  processApplicationContext(message)
        replyHandler(["response" : "The message was procssed correctly: \(success)", "success": success])
    }
    
}

extension WatchSessionManager {
    
    public func requestLatestAppContext() -> Bool {
        print("requestLatestAppContext")
        let applicationData = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
        
        var returnBool = false
        
        session.sendMessage(applicationData, replyHandler: {(context:[String : AnyObject]) -> Void in
            // handle reply from iPhone app here
            
            // print("recievedMessageReply: \(context)")
            returnBool = self.processApplicationContext(context)
            
            }, errorHandler: {(error ) -> Void in
                // catch any errors here
                print("error: \(error)")
                
                returnBool = false
                
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
                }
                
        })
        return returnBool
    }
    
    func processApplicationContext(context: [String : AnyObject]) -> Bool {
        print("processApplicationContext \(context)")
        
        guard let action = WatchAction(rawValue: (context[WatchModel.PropertyKey.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(context)")
            return false
        }
        
        print("Action recieved: \(action)")
        if let currentSiteIndex = context[WatchModel.PropertyKey.currentIndexKey] as? Int {
            self.currentSiteIndex = currentSiteIndex
        }
        
        if let modelArray = context[WatchModel.PropertyKey.modelsKey] as? [[String: AnyObject]] {
            sharedDefaults?.setObject(modelArray, forKey: DefaultKey.modelArrayObjectsKey)

        }
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
        }
        return true
    }
}

extension WatchSessionManager {
    public func complicationRequestedUpdateBudgetExhausted() {
        sharedDefaults?.setObject(NSDate(), forKey: "requestedUpdateBudgetExhausted")
        self.createComplicationData()
    }
    
    public func modelForComplication() -> WatchModel? {
        return self.models.filter({ (model) -> Bool in
            return model.uuid == defaultSite?.UUIDString
        }).first
    }
    
    public func createComplicationData() -> Void {
        if let model = modelForComplication() {
            let url = NSURL(string: model.urlString)!
            let site = Site(url: url, apiSecret: nil)!
            let nsApi = NightscoutAPIClient(url: site.url)
            
            nsApi.fetchCalibrations(4, completetion: { (calibrations, errorCode) -> Void in
                
                var calModels: [[String: AnyObject]] = []
                
                
                if let cals = calibrations {
                    
                    self.calibrations = cals.sort{(item1:Entry, item2:Entry) -> Bool in
                        item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
                    }
                    
                    for cal in cals {
                        if let dict = cal.cal?.dictionary {
                            calModels.append(dict)
                        }
                    }
                    
                }
                
                self.sharedDefaults?.setObject(calModels, forKey: "calibrations")
                self.sharedDefaults?.synchronize()
                
            })
            
            loadDataFor(site, index: nil, withChart: true, completetion: { (returnedModel, returnedSite, returnedIndex, returnedError) -> Void in
                
                guard let configuration = returnedSite?.configuration, displayName = returnedSite?.configuration?.displayName, entries = returnedSite?.entries else {
                    return
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
                        
                        let deltaString = "\(delta.formattedForBGDelta) \(configuration.displayUnits.description)"
                        let deltaStringShort = "\(delta.formattedForBGDelta) Δ"
                        
                        let sgvColor = colorForDesiredColorState(boundedColor)
                        
                        var raw = ""
                        var rawShort = ""
                        
                        if let cal = self.nearestCalibration(forDate: entry.date) {
                            
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
                self.complicationDataDictoinary = cmodels.flatMap { $0.dictionary }
            })
        }
    }
    
    public var complicationDataFromDefaults: [ComplicationModel] {
        
        var complicationModels = [ComplicationModel]()
        for d in complicationDataDictoinary {
            
            guard let displayName = d["displayName"] as? String, sgv = d["sgv"] as? String, date = d["date"] as? NSDate, sgvEmoji = d["sgvEmoji"] as? String, tintString = d["tintString"] as? String, delta = d["delta"] as? String, deltaShort = d["deltaShort"] as? String, raw = d["raw"] as? String, rawShort = d["rawShort"] as? String else {
                return []
            }
            
            complicationModels.append(ComplicationModel(displayName: displayName, date: date, sgv: sgv, sgvEmoji: sgvEmoji, tintString: tintString, delta: delta, deltaShort: deltaShort, raw: raw, rawShort: rawShort))
        }
        
        return complicationModels
    }
    
    public var complicationDataDictoinary: [[String: AnyObject]] {
        set{
            sharedDefaults?.setObject(newValue, forKey: "cModels")
            sharedDefaults?.setObject(NSDate(), forKey: "complicationTimeStamp")
            ComplicationController.reloadComplications()
        }
        get {
            guard let complicationDictArray = sharedDefaults?.arrayForKey("cModels") as? [[String : AnyObject]] else {
                return []
            }
            return complicationDictArray
        }
    }
    
    public func nearestCalibration(forDate date: NSDate) -> Calibration? {
        var desiredIndex: Int?
        var minDate: NSTimeInterval = fabs(NSDate().timeIntervalSinceNow)
        for (index, entry) in calibrations.enumerate() {
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
            return calibrations.first?.cal
        }
        
        // print("incoming date: \(closestDate.timeIntervalSinceNow) returning date: \(calibrations[index].date.timeIntervalSinceNow)")
        return calibrations[index].cal
    }
    
}
