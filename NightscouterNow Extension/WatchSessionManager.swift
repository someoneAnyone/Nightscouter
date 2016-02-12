//
//  WatchSessionManager.swift
//  WCApplicationContextDemo
//
//  Created by Natasha Murashev on 9/22/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity
import NightscouterWatchOSKit

@available(watchOS 2.0, *)
public protocol DataSourceChangedDelegate {
    func dataSourceDidUpdateAppContext(models: [WatchModel])
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    private let sharedDefaults = NSUserDefaults(suiteName: "group.com.nothingonline.nightscouter")
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        sharedDefaults?.setObject("watchOS", forKey: DefaultKey.osPlatform)
        
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userDefaultsDidChange:"), name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func userDefaultsDidChange(notification: NSNotification) {
        if let _ = notification.object as? NSUserDefaults {
            print("Defaults Changed update delegates")
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
            }
        }
    }
    
    public var models: [WatchModel] {
        set{
            let dictArray = newValue.map{ $0.dictionary }
            sharedDefaults?.setObject(dictArray, forKey: DefaultKey.modelArrayObjectsKey)
        }
        get {
            guard let dictArray = sharedDefaults?.objectForKey(DefaultKey.modelArrayObjectsKey) as? Array<[String: AnyObject]> else {
                
                return []
            }
            
            return dictArray.flatMap{ WatchModel(fromDictionary: $0) }
        }
    }
    
    public var defaultSite: NSUUID? {
        set {
            sharedDefaults?.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            updateComplication()
        }
        get {
            guard let uuidString = sharedDefaults?.objectForKey(DefaultKey.defaultSiteKey) as? String else {
                if let firstModel = models.first {
                    let newUUID = firstModel.uuid
                    sharedDefaults?.setObject(newUUID, forKey: DefaultKey.defaultSiteKey)
                    
                    return  NSUUID(UUIDString: newUUID)
                }
                
                return nil
            }
            
            return NSUUID(UUIDString: uuidString)
        }
    }
    
    private let session: WCSession = WCSession.defaultSession()
    
    public func updateModel(site: WatchModel)  ->  Bool {
        if let index = models.indexOf(site) {
            models[index] = site
            return true
        }
        
        return false
    }
    
    public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activateSession()
            
            if models.isEmpty {
                requestLatestAppContext(watchAction: .AppContext)
            }
        }
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
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
        print("didReceiveUserInfo:")
        // print("\(userInfo)")
        processApplicationContext(userInfo)
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("didReceiveApplicationContext")
        // print("received: \(applicationContext)")
        processApplicationContext(applicationContext)
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        let success =  processApplicationContext(message)
        replyHandler(["response" : "The message was procssed with success: \(success)", "success": success])
    }
}

extension WatchSessionManager {
    
    public func requestLatestAppContext(watchAction action: WatchAction) -> Bool {
        print("requestLatestAppContext for watchAction: \(action.rawValue)")
        
        let applicationData = [WatchModel.PropertyKey.actionKey: action.rawValue]
        var returnBool = false
        
        session.sendMessage(applicationData, replyHandler: {(context:[String : AnyObject]) -> Void in
            // handle reply from iPhone app here
            
            print("recievedMessageReply from iPhone")
            returnBool = self.processApplicationContext(context)
            
            }, errorHandler: {(error ) -> Void in
                // catch any errors here
                print("WatchSession Transfer Error: \(error)")
                
                returnBool = false
                
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
                }
        })
        
        return returnBool
    }
    
    func processApplicationContext(context: [String : AnyObject]) -> Bool {
        print("processApplicationContext")
        // print("Incoming context: \(context)")
        
        // Bail out when not watch action isn't recieved.
        guard let _ = WatchAction(rawValue: (context[WatchModel.PropertyKey.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(context)")
            
            return false
        }
        
        // Playload holds the default's dictionary from the iOS...
        guard let payload = context[WatchModel.PropertyKey.contextKey] as? [String: AnyObject] else {
            print("No payload was found.")
            print(context)
            
            return false
        }
        
        /*
        if let defaultSiteString = payload[DefaultKey.defaultSiteKey] as? String, uuid = NSUUID(UUIDString: defaultSiteString)  {
        defaultSite = uuid
        }
        
        if let currentIndex = payload[DefaultKey.currentSiteIndexKey] as? Int {
        currentSiteIndex = currentIndex
        }
        */
        
        if let siteArray = payload[DefaultKey.modelArrayObjectsKey] as? [[String: AnyObject]] {
            models = siteArray.map({ WatchModel(fromDictionary: $0)! })
        }
        
        return true
    }
}

extension WatchSessionManager {
    
    public func complicationRequestedUpdateBudgetExhausted() {
        sharedDefaults?.setObject(NSDate(), forKey: "requestedUpdateBudgetExhausted")
        updateComplication()
    }
    
    public func modelForComplication() -> WatchModel? {
        return self.models.filter({ (model) -> Bool in
            
            return model.uuid == defaultSite?.UUIDString
        }).first
    }
    
    public var nextUpdateDate: NSDate {
        let updateInterval: NSTimeInterval = Constants.StandardTimeFrame.TenMinutesInSeconds
        if let date = modelForComplication()?.lastReadingDate {
            return date.dateByAddingTimeInterval( updateInterval )
        }
        
        return NSDate(timeIntervalSinceNow: updateInterval)
    }
    
    public var complicationData: [ComplicationModel] {
        get {
            
            return self.modelForComplication()?.complicationModels.flatMap{ ComplicationModel(fromDictionary: $0) } ?? []
        }
    }
    
    public func updateComplication() {
        if let model = self.modelForComplication() {
            if (model.lastReadingDate.timeIntervalSinceNow < Constants.NotableTime.StandardRefreshTime.inThePast) {
                fetchSiteData(forSite: model.generateSite(), handler: { (reloaded, returnedSite, returnedIndex, returnedError) -> Void in
                    self.updateModel(returnedSite.viewModel)
                    
                    return
                })
            }
        }
    }
    
}
