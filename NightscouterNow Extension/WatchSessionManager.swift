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
            
            self.createComplicationData { (reloaded) -> Void in
                //..
            }
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
        
        if let dictArray = sharedDefaults?.objectForKey(DefaultKey.modelArrayObjectsKey) as? [[String: AnyObject]] {
            print("Loading models from default.")
            models = dictArray.map({ WatchModel(fromDictionary: $0)! })
        }
        if let item = session.outstandingUserInfoTransfers.first {
            processApplicationContext(item.userInfo)
        }
        
        sharedDefaults?.setObject("watchOS", forKey: DefaultKey.osPlatform)
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    private let session: WCSession = WCSession.defaultSession()
    
    
    public var models: [WatchModel] {
        set{
            let dictArray = models.map{ $0.dictionary }
            sharedDefaults?.setObject(dictArray, forKey: DefaultKey.modelArrayObjectsKey)
            
            self.createComplicationData { (reloaded) -> Void in
                if reloaded {
                    ComplicationController.reloadComplications()
                }
            }
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
            
            if models.isEmpty {
                requestLatestAppContext()
            }
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
        
        // if let cModels = context["cModels"] as? [[String: AnyObject]] {
        //  complicationDataDictoinary = cModels
        // }
        
        if let defaultSiteString = context["defaultSite"] as? String, defaultSite = NSUUID(UUIDString: defaultSiteString) {
            self.defaultSite = defaultSite
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
        self.createComplicationData { (reloaded) -> Void in
            //
        }
    }
    
    public func modelForComplication() -> WatchModel? {
        return self.models.filter({ (model) -> Bool in
            return model.uuid == defaultSite?.UUIDString
        }).first
    }
    
    public var nextUpdateDate: NSDate {
        if let date = sharedDefaults?.objectForKey(DefaultKey.complicationLastUpdateDidChangeComplicationDate) as? NSDate {
            return date.dateByAddingTimeInterval( 60.0 * 4.0)
        }
        
        return NSDate(timeIntervalSinceNow: 60.0 * 4.0)
    }
    
    public func createComplicationData(handler:(reloaded: Bool) -> Void) -> Void {
        sharedDefaults?.setObject(NSDate(), forKey: DefaultKey.complicationLastUpdateStartDate)
        
        
        if let model = modelForComplication() {
            
            
            if let date = sharedDefaults?.objectForKey(DefaultKey.complicationUpdateEndDate) as? NSDate {
                
            
            
            if date.compare(nextUpdateDate) == .OrderedAscending {
                self.sharedDefaults?.setObject(NSDate(), forKey: DefaultKey.complicationUpdateEndDate)
                handler(reloaded: false)
                return
                }
            }
            
            let url = NSURL(string: model.urlString)!
            let site = Site(url: url, apiSecret: nil, uuid: NSUUID(UUIDString: model.uuid)!)!
            let nsApi = NightscoutAPIClient(url: site.url)
            
            loadDataFor(site, index: nil, withChart: true, completetion: { (returnedModel, returnedSite, returnedIndex, returnedError) -> Void in
                
                guard let site = returnedSite, model = returnedModel else {
                    self.sharedDefaults?.setObject(NSDate(), forKey: DefaultKey.complicationUpdateEndDate)
                    
                    handler(reloaded: false)
                    return
                }
                
                nsApi.fetchCalibrations(10, completetion: { (calibrations, errorCode) -> Void in
                    
                    if let index = self.models.indexOf(model){
                        self.models[index] = model
                    }
                    
                    let models = generateComplicationModels(forSite: site, calibrations: calibrations?.flatMap{ $0.cal } ?? [])
                    
                    var calModels: [[String: AnyObject]] = []
                    if let cals = calibrations {
                        
                        self.calibrations = cals.sort{(item1:Entry, item2:Entry) -> Bool in
                            item1.date.compare(item2.date) == NSComparisonResult.OrderedDescending
                        }
                        
                        calModels = self.calibrations.flatMap { $0.cal?.dictionary }
                    }
                    
                    self.sharedDefaults?.setObject(calModels, forKey: DefaultKey.calibrations)
                    self.complicationDataDictoinary = models.flatMap { $0.dictionary }
                    self.sharedDefaults?.setObject(NSDate(), forKey: DefaultKey.complicationUpdateEndDate)
                    
                    handler(reloaded: true)
                    return
                })
            })
        }
        self.sharedDefaults?.setObject(NSDate(), forKey: DefaultKey.complicationUpdateEndDate)
        
        handler(reloaded: false)
        
    }
    
    public var complicationDataFromDefaults: [ComplicationModel] {
        
        var complicationModels = [ComplicationModel]()
        for d in complicationDataDictoinary {
            
            if let complication = ComplicationModel(fromDictionary: d) {
                complicationModels.append(complication)
            }
        }
        complicationModels.sortInPlace{ $0.date.compare($1.date) == NSComparisonResult.OrderedDescending }
        
        return complicationModels
    }
    
    public var complicationDataDictoinary: [[String: AnyObject]] {
        set{
            sharedDefaults?.setObject(newValue, forKey: DefaultKey.complicationModels)
            sharedDefaults?.setObject(NSDate(), forKey: DefaultKey.complicationLastUpdateDidChangeComplicationDate)
        }
        get {
            guard let complicationDictArray = sharedDefaults?.arrayForKey(DefaultKey.complicationModels) as? [[String : AnyObject]] else {
                return []
            }
            return complicationDictArray
        }
    }
}
