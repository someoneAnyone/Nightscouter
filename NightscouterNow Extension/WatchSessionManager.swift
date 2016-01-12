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
    func dataSourceDidUpdateSiteModel(model: WatchModel, atIndex index: Int)
    func dataSourceDidAddSiteModel(model: WatchModel, atIndex index: Int)
    func dataSourceDidDeleteSiteModel(model: WatchModel, atIndex index: Int)
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    public var currentSiteIndex: Int {
        set {
            
            #if DEBUG
                // print("currentSiteIndex is: \(currentSiteIndex) and is changing to \(newValue)")
            #endif
            
            sharedDefaults?.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
            // sharedDefaults?.synchronize()
            generateTimelineData()
        }
        get {
            return (sharedDefaults?.integerForKey(DefaultKey.currentSiteIndexKey))!
        }
    }
    
    private let sharedDefaults = NSUserDefaults(suiteName: "group.com.nothingonline.nightscouter")
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        if let dictArray = sharedDefaults?.objectForKey(DefaultKey.modelArrayObjectsKey) as? [[String: AnyObject]] {
            print("Loading models from default.")
            models = dictArray.map({ WatchModel(fromDictionary: $0)! })
        }
        
        // generateTimelineData()
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    private let session: WCSession = WCSession.defaultSession()
    
    private var sites: [Site] = []
    
    public var models: [WatchModel] = [] {
        didSet{
            let dictArray = models.map({ $0.dictionary })
            sharedDefaults?.setObject(dictArray, forKey: DefaultKey.modelArrayObjectsKey)
            
            // generateTimelineData()
        }
    }
    
    private var calibrations: [Entry] = []
    
    public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activateSession()
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
        
        if let currentSiteIndex = context[WatchModel.PropertyKey.currentIndexKey] as? Int {
            self.currentSiteIndex = currentSiteIndex
        }
        
        defer {
            generateTimelineData()
        }
        
        switch action {
            
        case .Update, .Create:
            print("update on watch framework")
            
            if let modelArray = context[WatchModel.PropertyKey.modelsKey] as? [[String: AnyObject]]{//, model = WatchModel(fromDictionary: modelDict) {
                for modelDict in modelArray {
                    
                    if let model = WatchModel(fromDictionary: modelDict) {
                        if let pos = models.indexOf(model){
                            models[pos] = model
                            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                                self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateSiteModel(model, atIndex: pos) }
                            }
                            
                        } else {
                            models.append(model)
                            
                            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                                self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidAddSiteModel(model, atIndex: self!.models.count - 1)}
                            }
                            
                        }
                    }
                }
            }
        case .Delete:
            if let modelArray = context[WatchModel.PropertyKey.modelsKey] as? [[String: AnyObject]]{
                for modelDict in modelArray {
                    let model = WatchModel(fromDictionary: modelDict)!
                    
                    if let pos = models.indexOf(model){
                        models.removeAtIndex(pos)
                        dispatch_async(dispatch_get_main_queue()) { [weak self] in
                            self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidDeleteSiteModel(model, atIndex: pos) }
                        }
                    }
                }
            }
        case .AppContext, .UserInfo, .Read:
            if let modelArray = context[WatchModel.PropertyKey.modelsKey] as? [[String: AnyObject]] {
                models.removeAll()
                for modelDict in modelArray {
                    let model = WatchModel(fromDictionary: modelDict)!
                    models.append(model)
                }
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
                }
            }
            
        }
        
        return true
    }
    
}

public struct ComplicationModel: DictionaryConvertible {
    
    public let displayName: String
    public let date: NSDate
    public let sgv: String// = "000 >"// model.sgvStringWithEmoji
    public let sgvEmoji: String
    public let tintString: String//  = UIColor.redColor().toHexString() //model.sgvColor
    
    public let delta: String//  = "DEL" // model.deltaString
    public let deltaShort: String//  = "DE" // model.deltaStringShort
    public var raw: String?//  =  ""
    public var rawShort: String?//  = ""
    public var rawVisible: Bool {
        return (raw != nil)
    }
    
}
extension WatchSessionManager {
    
    public func modelForComplication() -> WatchModel? {
        if models.count >= currentSiteIndex && !models.isEmpty {
            return self.models[self.currentSiteIndex]
        }
        return nil
    }
    
    public func generateTimelineData() -> Void {
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
                
                var cmodels: [[String: AnyObject]] = []
                
                
                // Get prefered Units. mmol/L or mg/dL
                let configUnits: Units = configuration.displayUnits
                
                for (index, entry) in entries.enumerate() {
                    
                    if let sgvValue = entry.sgv {
                        
                        // Convert units.
                        var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
                        // Convert units.
                        
                        if configUnits == .Mmol {
                            boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
                        }
                        
                        let sgvString =  "\(sgvValue.sgvString(forUnits: configUnits))"
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
                        
                        cmodels.append( ComplicationModel(displayName: displayName, date: entry.date, sgv: sgvStringWithEmoji, sgvEmoji: sgvEmoji, tintString: sgvColor.toHexString(), delta: deltaString, deltaShort: deltaStringShort, raw: raw, rawShort: rawShort).dictionary)
                        
                    }
                    
                }
                
                
                self.sharedDefaults?.setObject(cmodels, forKey: "cModels")
                // self.sharedDefaults?.synchronize()
                
                ComplicationController.reloadComplications()
            })
        }
    }
    
    
    
    public func timelineDataForComplication() -> [ComplicationModel]? {
        if let dicts = sharedDefaults?.arrayForKey("cModels") as? [[String : AnyObject]]{
            
            var cModels = [ComplicationModel]()
            for d in dicts {
                
                guard let displayName = d["displayName"] as? String, sgv = d["sgv"] as? String, date = d["date"] as? NSDate, sgvEmoji = d["sgvEmoji"] as? String, tintString = d["tintString"] as? String, delta = d["delta"] as? String, deltaShort = d["deltaShort"] as? String, raw = d["raw"] as? String, rawShort = d["rawShort"] as? String else {
                    return nil
                }
                
                cModels.append(ComplicationModel(displayName: displayName, date: date, sgv: sgv, sgvEmoji: sgvEmoji, tintString: tintString, delta: delta, deltaShort: deltaShort, raw: raw, rawShort: rawShort))
            }
            return cModels
        }
        
        return nil
    }
    
    
    
    
    public func nearestCalibration(forDate date: NSDate) -> Calibration? {
        
        
        //        let greaterThan = NSPredicate(format:"startDate <= %@", date.timeIntervalSinceNow)
        //        let lessThan = NSPredicate(format:"endDate >= %@", date.timeIntervalSinceNow)
        //        let between = NSCompoundPredicate(andPredicateWithSubpredicates: [greaterThan, lessThan])
        
        
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
