//
//  WatchSessionManager.swift
//  WCApplicationContextDemo
//
//  Created by Natasha Murashev on 9/22/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//
import WatchKit

import WatchConnectivity
import NightscouterWatchOSKit

@available(watchOS 2.0, *)
public protocol DataSourceChangedDelegate {
    func dataSourceDidUpdateAppContext(models: [WatchModel])
    func dataSourceCouldNotConnectToPhone(error: NSError)
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    private let modelInfoQueue = dispatch_queue_create("com.nothingonline.nightscouter.watchsessionmanager", DISPATCH_QUEUE_SERIAL)
    
    public var models: [WatchModel] = [] {
        didSet{
            let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
            defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
            defaults.synchronize()
            
            /*
             iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
             iCloudKeyStore.synchronize()
             */
            
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
            }
            
            
            dispatch_async(dispatch_get_main_queue()) {
                ComplicationController.reloadComplications()
            }
        }
    }
    
    public var currentSiteIndex: Int {
        set{
            defaults.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
            defaults.synchronize()
            
            /*
             iCloudKeyStore.setLongLong(Int64(currentSiteIndex), forKey: DefaultKey.currentSiteIndexKey)
             iCloudKeyStore.synchronize()
             */
            
        }
        get{
            return defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        }
    }
    
    public var defaultSiteUUID: NSUUID? {
        set{
            defaults.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            defaults.synchronize()
            /*
             iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
             iCloudKeyStore.synchronize()
             */
            
            updateComplication { complicationData in
                dispatch_async(dispatch_get_main_queue()) {
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
        dispatch_sync(modelInfoQueue) {
            if let index = self.models.indexOf(model) {
                self.models[index] = model
                success = true
            } else {
                self.models.append(model)
                success = true
            }
        }
        return success
    }
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        currentlySendingMessage = false
        
        loadData()
        setupNotifications()
    }
    
    deinit {
        saveData()
        dataSourceChangedDelegates.removeAll()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    public let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    // public let iCloudKeyStore = NSUbiquitousKeyValueStore.defaultStore()
    
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
        /*
         iCloudKeyStore.setObject(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
         iCloudKeyStore.setArray(models, forKey: DefaultKey.modelArrayObjectsKey)
         iCloudKeyStore.setString(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
         
         iCloudKeyStore.synchronize()
         */
    }
    
    public func loadData() {
        
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            self.models = models.flatMap{ WatchModel(fromDictionary: $0) }
        }
        
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(WatchSessionManager.userDefaultsDidChange(_:)),
                                                         name: NSUserDefaultsDidChangeNotification,
                                                         object: defaults)
        
        /*
         NSNotificationCenter.defaultCenter().addObserver(self,
         selector: #selector(WatchSessionManager.ubiquitousKeyValueStoreDidChange(_:)),
         name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
         object: iCloudKeyStore)
         
         
         iCloudKeyStore.synchronize()
         */
    }
    
    public let session: WCSession = WCSession.defaultSession()
    
    public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activateSession()
            
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported()), Paired Phone Reachable: \(session.reachable)")
            #endif
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

@available(watchOSApplicationExtension 2.2, *)
extension WatchSessionManager {
    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        
        // Do not proceed if `session` is not currently `.Activated`.
        guard session.activationState == .Activated else { return }
        
        if !session.receivedApplicationContext.isEmpty {
            processApplicationContext(WCSession.defaultSession().receivedApplicationContext)
        }
        
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("didReceiveUserInfo:")
        // print("\(userInfo)")
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.processApplicationContext(userInfo)
        }
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("didReceiveApplicationContext")
        // print("received: \(applicationContext)")
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.processApplicationContext(applicationContext)
        }
    }
    
    public func sessionReachabilityDidChange(session: WCSession) {
        print(#function)
        if session.reachable == true && currentlySendingMessage == false {
            updateData(forceRefresh: false)
        }
    }
}

extension WatchSessionManager {
    
    public func processApplicationContext(context: [String : AnyObject], updateDelegates update: Bool = true) -> Bool {
        print("processApplicationContext")
        // print("Incoming context: \(context)")
        
        // Bail out when not watch action isn't recieved.
        /*
         guard let stringValue = context[WatchModel.PropertyKey.actionKey] as? String, _ = WatchAction(rawValue: stringValue) else {
         print("No action was found, didReceiveMessage: \(context)")
         
         return false
         }
         */
        
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
            let models = modelArray.map({ WatchModel(fromDictionary: $0)! })

            self.models = models
            
            if update {
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    print("UPDATING DELEGATES!!!!! -------")
                    self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext(
                        models) }
                }
            }
        }
        
        return true
    }
    
}

extension WatchSessionManager {
    
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
        
        updateComplication { complicationData in
            ComplicationController.reloadComplications()
        }
    }
    
    public var nextRequestedComplicationUpdateDate: NSDate {
        let updateInterval: NSTimeInterval = Constants.StandardTimeFrame.OneHourInSeconds
        
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
    
    public func updateComplication(completion: (timline: [ComplicationModel]) -> Void) {
        
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
            
            completion(timline: self.complicationData)
            return
        }
        
        if model.updateNow {
            
            let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.UpdateComplication.rawValue]
            
            session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("recievedMessageReply from iPhone")
                NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                    self.processApplicationContext(context)
                    completion(timline: self.complicationData)
                }
                
                }, errorHandler: {(error: NSError ) -> Void in
                    print("WatchSession Transfer Error: \(error)")
                    fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                            completion(timline: self.complicationData)
                        })
                    })
            })
        } else {
            completion(timline: self.complicationData)
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
        
        startSession()
        
        if let model = minModel where (model.updateNow || refresh == false) && currentlySendingMessage == false {
            
            print("Updating because: model needs updating: \(model.updateNow) or becasue force refresh is set to: \(refresh)")
            
            let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
            self.currentlySendingMessage = true
            
            self.session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("recievedMessageReply from iPhone")
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    print("WatchSession success...")
                    self?.currentlySendingMessage = false
                    self?.processApplicationContext(context)
                }
                }, errorHandler: {(errorType: NSError ) -> Void in
                    print("WatchSession Transfer Error: \(errorType)")
                    
                    self.currentlySendingMessage = false
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.dataSourceChangedDelegates.forEach { $0.dataSourceCouldNotConnectToPhone(errorType) }
                    }
                    
            })
        } else {
            self.currentlySendingMessage = false
        }
    }
    
    // MARK: Storage Updates
    
    // MARK: Defaults have Changed
    
    func userDefaultsDidChange(notification: NSNotification) {
        print("userDefaultsDidChange:")
        
        guard let _ = notification.object as? NSUserDefaults else { return }
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(AppDataManagerDidChangeNotification, object: nil)
        }
    }
    
    /*
     
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
     }
     }
     }
     */
}