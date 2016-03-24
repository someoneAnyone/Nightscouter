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
    func dataSourceCouldNotConnectToPhone(error: NSError)
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    public var models: [WatchModel] = [] {
        didSet{
            
            let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
            
            defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
            iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
            iCloudKeyStore.synchronize()
            
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                ComplicationController.reloadComplications()
            }
            defaults.synchronize()
        }
    }
    
    public var currentSiteIndex: Int {
        set{
            defaults.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
            iCloudKeyStore.setLongLong(Int64(currentSiteIndex), forKey: DefaultKey.currentSiteIndexKey)
            
            iCloudKeyStore.synchronize()
            
        }
        get{
            return defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        }
    }
    
    public var defaultSiteUUID: NSUUID? {
        set{
            defaults.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            
            iCloudKeyStore.synchronize()
            
            updateComplication { () -> Void in
                NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                    ComplicationController.reloadComplications()
                }
            }
        }
        get {
            if let uuidString = defaults.objectForKey(DefaultKey.defaultSiteKey) as? String {
                return NSUUID(UUIDString: uuidString)
            } else if let firstModel = models.first {
                return NSUUID(UUIDString: firstModel.uuid)
            }
            
            return nil
        }
    }
    
    public func defaultModel() -> WatchModel? {
        
        let uuidString = defaultSiteUUID?.UUIDString
        
        let matched = self.models.filter({ (model) -> Bool in
            return model.uuid == uuidString
        })
        
        return matched.first ?? models.first
    }
    
    public func updateModel(model: WatchModel)  ->  Bool {
        
        var success = false
        
        if let index = models.indexOf(model) {
            models[index] = model
            success = true
        } else {
            models.append(model)
            success = true
        }
        
        return success
    }
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        
        loadData()
        setupNotifications()
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
    
    func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WatchSessionManager.dataStaleUpdate(_:)), name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    func dataStaleUpdate(notif: NSNotification) {
        updateData(forceRefresh: true)
    }
    
    // MARK: Save and Load Data
    public func saveData() {
        print("Saving Data")
        
        // let userSitesData =  NSKeyedArchiver.archivedDataWithRootObject(self.sites
        // defaults.setObject(userSitesData, forKey: DefaultKey.sitesArrayObjectsKey)
        
        let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
        
        defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
        defaults.setInteger(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        defaults.setObject("watchOS", forKey: DefaultKey.osPlatform)
        defaults.setObject(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        iCloudKeyStore.setObject(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
        iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
        
        iCloudKeyStore.synchronize()
        
    }
    
    public func loadData() {
        
        
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            self.models = models.flatMap{ WatchModel(fromDictionary: $0) }
        }
        
        if self.models.isEmpty {
            updateData(forceRefresh: true)
        }
        //
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(WatchSessionManager.userDefaultsDidChange(_:)),
            name: NSUserDefaultsDidChangeNotification,
            object: defaults)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(WatchSessionManager.ubiquitousKeyValueStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
            object: iCloudKeyStore)
        
        
        
        iCloudKeyStore.synchronize()
        
        //updateData(forceRefresh: true)
        
    }
    
    public let session: WCSession = WCSession.defaultSession()
    
    public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activateSession()
            
            // updateData(forceRefresh: false)
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported()), Paired Phone Reachable: \(session.reachable)")
            #endif
        }
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    public func addDataSourceChangedDelegate<T where T: DataSourceChangedDelegate, T: Equatable>(delegate: T) {
        dataSourceChangedDelegates.append(delegate)
        
        updateDelegates("addDataSourceChangedDelegate")
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
        
        dispatch_async(dispatch_get_main_queue()) {
            self.processApplicationContext(userInfo, updateDelegates:  true)
            //            ComplicationController.reloadComplications()
        }
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("didReceiveApplicationContext")
        // print("received: \(applicationContext)")
        
        dispatch_async(dispatch_get_main_queue()) {
            self.processApplicationContext(applicationContext)
        }
        
    }
    
    public func sessionReachabilityDidChange(session: WCSession) {
        
        if session.reachable && models.isEmpty {
            let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
            
            session.sendMessage(messageToSend, replyHandler: { (context) -> Void in
                self.processApplicationContext(context, updateDelegates: false)
                self.updateData(forceRefresh: false)
                
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        }
    }
}

extension WatchSessionManager {
    
    public func processApplicationContext(context: [String : AnyObject], updateDelegates update: Bool = true) -> Bool {
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
            print("Incoming context: \(context)")
            
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
            self.models = modelArray.map({ WatchModel(fromDictionary: $0)! })
        }
        
        if update {
            updateDelegates("processApplicationContext")
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            ComplicationController.reloadComplications()
        }
        
        
        return true
    }
    
}

extension WatchSessionManager {
    
    func updateDelegates(sender: String) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            guard let items = self?.models else {
                
                return
            }
            print("UPDATING DELEGATES!!!!! ------- from sender \(sender)")
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext(items) }
        }
    }
    
    public func complicationRequestedUpdateBudgetExhausted() {
        
        let requestReceived = "complicationRequestedUpdateBudgetExhausted"
        
        if var updateArray = defaults.arrayForKey(requestReceived) as? [NSDate] {
            if updateArray.count > 5 {
                updateArray.removeLast()
            }
            updateArray.append(NSDate())
            defaults.setObject(updateArray, forKey: requestReceived)
        } else {
            defaults.setObject([NSDate()], forKey: requestReceived)
        }
        
        updateComplication { () -> Void in
            
        }
    }
    
    public var nextRequestedComplicationUpdateDate: NSDate {
        let updateInterval: NSTimeInterval = Constants.StandardTimeFrame.ThirtyMinutesInSeconds
        
        if let defaultModel = defaultModel() {
            return defaultModel.lastReadingDate.dateByAddingTimeInterval(updateInterval)
        }
        
        return NSDate(timeIntervalSinceNow: updateInterval)
    }
    
    public var complicationData: [ComplicationModel] {
        get {
            return self.defaultModel()?.complicationModels.flatMap{ ComplicationModel(fromDictionary: $0) } ?? []
        }
    }
    
    public func updateComplication(completion: () -> Void) {
        
        startSession()
        let requestReceived = "requestedUpdateDidBeginRequestRecieved"
        
        if var updateArray = defaults.arrayForKey(requestReceived) as? [NSDate] {
            if updateArray.count > 5 {
                updateArray.removeLast()
            }
            updateArray.append(NSDate())
            defaults.setObject(updateArray, forKey: requestReceived)
        } else {
            defaults.setObject([NSDate()], forKey: requestReceived)
        }
        
        print("updateComplication")
        guard let model = self.defaultModel() else {
            print("No model was found...")
            
            return
        }
        
        if model.updateNow {
            
            
            let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.UpdateComplication.rawValue]
            
            session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("recievedMessageReply from iPhone")
                NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                    self.processApplicationContext(context, updateDelegates: true)
                    // ComplicationController.reloadComplications()
                }
                
                completion()
                }, errorHandler: {(error: NSError ) -> Void in
                    print("WatchSession Transfer Error: \(error)")
                    fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                            // ComplicationController.reloadComplications()
                            
                            completion()
                        })
                    })
            })
        } else {
            updateDelegates(#function)
            completion()
        }
        
    }
    
    var currentlySendingMessage:Bool {
        get {
            return defaults.boolForKey("currentlySendingMessage")
        }
        set {
            defaults.setBool(newValue, forKey: "currentlySendingMessage")
        }
    }
    
    public func updateData(forceRefresh refresh: Bool) {
        print(">>> Entering \(#function) <<<")
        
        let minModel = self.models.minElement { (lModel, rModel) -> Bool in
            return rModel.lastReadingDate < lModel.lastReadingDate
        }
        
        guard let _ = minModel else {
            return
        }
        
        if let model = minModel where (model.updateNow || refresh == false) && currentlySendingMessage == false {
            
            print("Updating because: model needs updating: \(model.updateNow) or becasue force refresh is set to: \(refresh)")
            
            let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
            self.currentlySendingMessage = true
            
            self.session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("recievedMessageReply from iPhone")
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    print("WatchSession success...")
                    self.currentlySendingMessage = false
                    self.processApplicationContext(context)
                })
                }, errorHandler: {(error: NSError ) -> Void in
                    print("WatchSession Transfer Error: \(error)")
                    self.currentlySendingMessage = false
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.dataSourceChangedDelegates.forEach { $0.dataSourceCouldNotConnectToPhone(error) }
                    }
            })
        }
    }
    
    // MARK: Storage Updates
    
    // MARK: Defaults have Changed
    
    func userDefaultsDidChange(notification: NSNotification) {
        print("userDefaultsDidChange:")
        
        
        guard let _ = notification.object as? NSUserDefaults else { return }
        //print(defaultObject.dictionaryRepresentation())
        
    }
    
    // MARK: iCloud Key Store Changed
    
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
                
                if key == DefaultKey.modelArrayObjectsKey {
                    if let models = store.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
                        self.models = models.flatMap( { WatchModel(fromDictionary: $0) } )
                    }
                }
                
                if key == DefaultKey.defaultSiteKey {
                    print(key)
                }
                
                if key == DefaultKey.currentSiteIndexKey {
                    self.currentSiteIndex = store.objectForKey(DefaultKey.currentSiteIndexKey) as! Int
                }
                
                // updateDelegates(#function)
            }
        }
    }
}