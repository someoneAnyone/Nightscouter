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

struct Static {
    static var dispatchOnceToken: dispatch_once_t = 0
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    private let modelInfoQueue = dispatch_queue_create("com.nothingonline.nightscouter.watchsessionmanager", DISPATCH_QUEUE_SERIAL)
    
    let reloadComplications = dispatch_debounce_block(10.0, block: {
        dispatch_async(dispatch_get_main_queue()) {
            ComplicationController.reloadComplications()
        }
    })
    
    let postNotificaitonForDefaults = dispatch_debounce_block(4.0, block: {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(AppDataManagerDidChangeNotification, object: nil)
        }
    })
    
    public static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
        currentlySendingMessage = false
        
        loadData()
        setupNotifications()
    }
    
    deinit {
        saveData()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private let session : WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    public var validSession: WCSession? {
        guard let session = session where session.reachable else {
            return nil
        }
        
        return session
    }
    
    public func startSession() {
        if WCSession.isSupported() {
            session?.delegate = self
            session?.activateSession()
            
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported()), Paired Phone Reachable: \(session?.reachable)")
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
    
    private struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    private let defaults = NSUserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    public var models: [WatchModel] = [] {
        didSet {
            let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
            
            defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
            
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
            }
            
            reloadComplications()
        }
    }
    
    public var currentSiteIndex: Int {
        set{
            defaults.setInteger(newValue, forKey: DefaultKey.currentSiteIndexKey)
            
        }
        get{
            return defaults.integerForKey(DefaultKey.currentSiteIndexKey)
        }
    }
    
    public var defaultSiteUUID: NSUUID? {
        set{
            defaults.setObject(newValue?.UUIDString, forKey: DefaultKey.defaultSiteKey)
            
            var payload = [String: AnyObject]()
            payload[DefaultKey.defaultSiteKey] = newValue?.UUIDString
            session?.transferUserInfo(payload)
            
            updateComplication { complicationData in
                self.reloadComplications()
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
        
        if success {  updateDelegatesForModelChange(self.models) }
        
        return success
    }
    
    public var lastReloadDate: NSDate {
        get {
            return defaults.objectForKey("lastReloadDate") as? NSDate ?? NSDate()
        }
        set {
            return defaults.setObject(newValue, forKey: "lastReloadDate")
        }
    }
    
    public var lastAttmemptToUpdate: NSDate? {
        get {
            return defaults.objectForKey("lastAttmemptToUpdate") as?  NSDate
        }
        set {
            defaults.setObject(newValue, forKey: "lastAttmemptToUpdate")
        }
    }
    
    public var lastUpdateTimeStamp: NSDate? {
        get {
            return defaults.objectForKey("lastUpdateTimeStamp") as?  NSDate
        }
        set {
            defaults.setObject(newValue, forKey: "lastUpdateTimeStamp")
        }
    }
    
    private var currentlySendingMessage: Bool {
        get {
            return defaults.boolForKey("currentlySendingMessage")
        }
        set {
            lastAttmemptToUpdate = NSDate()
            defaults.setBool(newValue, forKey: "currentlySendingMessage")
        }
    }
    
    
    private func setupNotifications() {
        // Listen for global update timer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WatchSessionManager.dataStaleUpdate(_:)), name: NightscoutAPIClientNotification.DataIsStaleUpdateNow, object: nil)
    }
    
    func dataStaleUpdate(notif: NSNotification) {
        updateData(forceRefresh: true)
    }
    
    // MARK: Save and Load Data
    public func saveData() {
        print("Saving Data")
        let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
        
        defaults.setObject(models, forKey: DefaultKey.modelArrayObjectsKey)
        defaults.setInteger(currentSiteIndex, forKey: DefaultKey.currentSiteIndexKey)
        defaults.setObject("watchOS", forKey: DefaultKey.osPlatform)
        defaults.setObject(defaultSiteUUID?.UUIDString, forKey: DefaultKey.defaultSiteKey)
    }
    
    public func loadData() {
        
        if let models = defaults.arrayForKey(DefaultKey.modelArrayObjectsKey) as? [[String : AnyObject]] {
            self.models = models.flatMap{ WatchModel(fromDictionary: $0) }
        }
        
        // Register for settings changes as store might have changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: defaults)
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
        
        print("\(#function)= session.activationState = \(session.activationState)")
        
        if !session.receivedApplicationContext.isEmpty {
            print("!session.receivedApplicationContext.isEmpty")
            processApplicationContext(WCSession.defaultSession().receivedApplicationContext)
        }
        
        updateData(forceRefresh: false)
    }
    
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print(#function)
        // print("\(userInfo)")
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.processApplicationContext(userInfo, updateDelegates: true)
        }
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print(#function)
        // print("received: \(applicationContext)")
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.processApplicationContext(applicationContext)
        }
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        print(#function)
        // print(message)
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.processApplicationContext(message)
        }
    }
    
    public func sessionReachabilityDidChange(session: WCSession) {
        print(#function)
        // print(session)
        
        if session.reachable == true && currentlySendingMessage == false {
            updateData(forceRefresh: false)
        }
    }
    
}

extension WatchSessionManager {
    
    public func processApplicationContext(context: [String : AnyObject], updateDelegates update: Bool = true) {
        print("processApplicationContext")
        // print("Incoming context: \(context)")
        
        // Playload holds the default's dictionary from the iOS...
        guard let payload = context[WatchModel.PropertyKey.contextKey] as? [String: AnyObject] else {
            print("No payload was found.")
            print("Incoming context: \(context)")
            
            return
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
                updateDelegatesForModelChange(models)
            }
            
            reloadComplications()
        }
    }
    
}

extension WatchSessionManager {
    
    func updateDelegatesForError(errorType: NSError) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceCouldNotConnectToPhone(errorType) }
        }
    }
    
    func updateDelegatesForModelChange(models:[WatchModel]) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            print("\(#function) UPDATING DELEGATES!!!!! -------")
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext(
                models) }
        }
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
            // ComplicationController.reloadComplications()
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
            var complicationModels: [ComplicationModel] = []
            dispatch_sync(modelInfoQueue) {
                complicationModels = self.defaultModel()?.complicationModels.flatMap{ ComplicationModel(fromDictionary: $0) } ?? []
            }
            
            return complicationModels
        }
    }
    
    public func updateComplication(completion: (timline: [ComplicationModel]) -> Void) {
        print(#function)
        
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
        
        let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.UpdateComplication.rawValue]
        
        guard let model = self.defaultModel() else {
            print("No model was found... returning empty timline in \(#function)")
            
            completion(timline: [])
            return
        }
        
        if model.updateNow {
            
            print("Updating because: model needs updating: \(model.updateNow)")
            self.currentlySendingMessage = true
            
            guard let validSession = validSession else {
                fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                    WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                    completion(timline: returnedSite.complicationModels)
                })
                
                return
            }
            
            validSession.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("\(#function): recievedMessageReply from iPhone")
                
                self.currentlySendingMessage = false
                
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    print("updateComplication success...")
                    self?.processApplicationContext(context)
                    completion(timline: self?.complicationData ?? [])
                }
                
                }, errorHandler: {(error: NSError ) -> Void in
                    print("\(#function): recieved error from phone: \(error)")
                    self.currentlySendingMessage = false
                    
                    guard let watchErrorCode =  WCErrorCode(rawValue: error.code) else {
                        return
                    }
                    
                    switch watchErrorCode {
                    case .SessionNotActivated:
                        self.session?.activateSession()
                    case .MessageReplyTimedOut:
                        print(error)
                        
                    default:
                        fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                            WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                            completion(timline: returnedSite.complicationModels)
                        })
                    }
            })
            
        } else {
            completion(timline: self.complicationData)
        }
        
    }
    
    public func updateData(forceRefresh refresh: Bool) {
        print(">>> Entering \(#function) <<<")
        
        let minModel = self.models.minElement { (lModel, rModel) -> Bool in
            return rModel.lastReadingDate < lModel.lastReadingDate
        }
        
        if let model = minModel where (model.updateNow || refresh == false) && currentlySendingMessage == false {
            
            print("Updating because: model needs updating: \(model.updateNow) or becasue force refresh is set to: \(refresh), currentlySending: \(currentlySendingMessage.description)")
            
            let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
            
            self.currentlySendingMessage = true
            
            guard let validSession = validSession else {
                print("No valid session...")
                
                session?.transferUserInfo(messageToSend)
                
                let error = NSError(domain: "No session available.", code: 500, userInfo: nil)
                self.updateDelegatesForError(error)
                
                return
            }
            
            validSession.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
                // handle reply from iPhone app here
                print("recievedMessageReply from iPhone")
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    print("WatchSession success...")
                    self?.currentlySendingMessage = false
                    self?.processApplicationContext(context)
                }
                
                }, errorHandler: {(error: NSError ) -> Void in
                    print("WatchSession Transfer Error: \(error)")
                    self.currentlySendingMessage = false
                    
                    guard let watchErrorCode =  WCErrorCode(rawValue: error.code) else {
                        return
                    }
                    
                    switch watchErrorCode {
                    case .SessionNotActivated:
                        self.session?.activateSession()
                    case .MessageReplyTimedOut:
                        print(error)
                    default:
                        self.updateDelegatesForError(error)
                    }
            })
        } else {
            self.currentlySendingMessage = false
        }
    }
    
    // MARK: Storage Updates
    
    // MARK: Defaults have Changed
    
    func userDefaultsDidChange(notification: NSNotification) {
        //print("userDefaultsDidChange:")
        
        guard let _ = notification.object as? NSUserDefaults else { return }
        
        postNotificaitonForDefaults()
    }
    
}