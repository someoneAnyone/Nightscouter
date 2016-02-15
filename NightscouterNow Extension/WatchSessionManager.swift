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
    public var sites: [Site] = []
    
    
    public var models: [WatchModel] = [] {
        didSet{
            
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
            } else if defaultSiteUUID == nil {
                defaultSiteUUID = NSUUID(UUIDString: (models.first?.uuid)!)
            }
            
            
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
            }
            
            saveData()
        }
    }
    public var currentSiteIndex: Int = 0
    
    public var defaultSiteUUID: NSUUID? {
        didSet{
            updateComplication()
        }
    }
    
    public func defaultModel() -> WatchModel? {
        
        let uuidString = defaultSiteUUID?.UUIDString
        let matched = self.models.filter({ (model) -> Bool in
            return model.uuid == uuidString
        })
        
        return matched.first ?? models.first
    }
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        
        loadData()
    }
    
    deinit {
        saveData()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    public let iCloudKeyStore = NSUbiquitousKeyValueStore.defaultStore()
    
    // MARK: Save and Load Data
    private func saveData() {
        
        let userSitesData =  NSKeyedArchiver.archivedDataWithRootObject(self.sites)
        defaults.setObject(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
        
        let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
        
        defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
        defaults.setInteger(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        defaults.setObject("watchOS", forKey: DefaultKey.osPlatform)
        defaults.setObject(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        // Save To iCloud
        iCloudKeyStore.setData(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
        iCloudKeyStore.setObject(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
        iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        iCloudKeyStore.synchronize()
        
    }
    
    public func loadData() {
        
        currentSiteIndex = defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            self.models = models.flatMap{ WatchModel(fromDictionary: $0) }
        }
        
        if let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String {
            self.defaultSiteUUID =  NSUUID(UUIDString: uuidString)
        } else  if let firstModel = sites.first {
            self.defaultSiteUUID = firstModel.uuid
        }
        
        /*
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("userDefaultsDidChange:"),
            name: NSUserDefaultsDidChangeNotification,
            object: defaults)
        */
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "ubiquitousKeyValueStoreDidChange:",
            name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
            object: iCloudKeyStore)
        
        iCloudKeyStore.synchronize()
    }
    
    private let session: WCSession = WCSession.defaultSession()
    
    public func updateModel(model: WatchModel)  ->  Bool {
        if let index = models.indexOf(model) {
            models[index] = model
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
    
    public func endSession() {
        saveData()
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
            // print("Incoming context: \(context)")
            
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
        
        if let modelArray = payload[DefaultKey.modelArrayObjectsKey] as? [[String: AnyObject]] {
            models = modelArray.map({ WatchModel(fromDictionary: $0)! })
        }
        
        return true
    }
}

extension WatchSessionManager {
    
    public func complicationRequestedUpdateBudgetExhausted() {
        defaults.setObject(NSDate(), forKey: "complicationRequestedUpdateBudgetExhausted")
        updateComplication()
    }
    
    public var nextRequestedComplicationUpdateDate: NSDate {
        let updateInterval: NSTimeInterval = Constants.StandardTimeFrame.TenMinutesInSeconds
        if let date = defaultModel()?.lastReadingDate {
            return date.dateByAddingTimeInterval( updateInterval )
        }
        
        return NSDate(timeIntervalSinceNow: updateInterval)
    }
    
    public var nextRefreshDate: NSDate {
        let date = NSDate().dateByAddingTimeInterval(Constants.NotableTime.StandardRefreshTime.inThePast)
        print("nextRefreshDate: " + date.description)
        return date
    }
    
    public var complicationData: [ComplicationModel] {
        get {
            return self.defaultModel()?.complicationModels.flatMap{ ComplicationModel(fromDictionary: $0) } ?? []
        }
    }
    
    public func updateComplication() {
        print("updateComplication")
        if let model = self.defaultModel() {
            if model.lastReadingDate.compare(nextRefreshDate) == .OrderedAscending {
                fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                        self.updateModel(returnedSite.viewModel)
                        ComplicationController.reloadComplications()
                })
            }
        }
    }
    
    
    /*
    // MARK: Defaults have Changed
    func userDefaultsDidChange(notification: NSNotification) {
        print("userDefaultsDidChange:")
        
        // guard let defaultObject = notification.object as? NSUserDefaults else { return }
    }
    */
    
    func ubiquitousKeyValueStoreDidChange(notification: NSNotification) {
        print("ubiquitousKeyValueStoreDidChange:")
        
        guard let userInfo = notification.userInfo as? [String: AnyObject], changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else {
            return
        }
        let reason = changeReason.integerValue
        
        if (reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as! [String]
            let store = NSUbiquitousKeyValueStore.defaultStore()
            
            for key in changedKeys {
                
                // Update Data Source
                switch key {
                case DefaultKey.modelArrayObjectsKey:
                    if let models = store.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
                        self.models = models.flatMap( { WatchModel(fromDictionary: $0) } )
                    }
                case DefaultKey.defaultSiteKey:
                    if let uuidString = store.stringForKey(DefaultKey.defaultSiteKey) {
                        self.defaultSiteUUID =  NSUUID(UUIDString: uuidString)
                    }
                case DefaultKey.currentSiteIndexKey:
                    currentSiteIndex = store.objectForKey(DefaultKey.currentSiteIndexKey) as? Int ?? 0
                default:
                    break
                }
            }
        }
    }
}
