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
    func dataSourceDidUpdateAppContext(_ models: [WatchModel])
    func dataSourceCouldNotConnectToPhone(_ error: Error)
}

struct Static {
    static var dispatchOnceToken: Int = 0
}

@available(watchOS 2.0, *)
open class WatchSessionManager: NSObject, WCSessionDelegate {
    
    fileprivate let modelInfoQueue = DispatchQueue(label: "com.nothingonline.nightscouter.watchsessionmanager", attributes: [])
    
    let reloadComplications = debounce(delay: 10) { 
        
//    dispatch_debounce_block(10.0, block: {
        DispatchQueue.main.async {
            ComplicationController.reloadComplications()
        }
    }
    
    let postNotificaitonForDefaults = debounce(delay: 4) { //dispatch_debounce_block(4.0, block: {
        OperationQueue.main.addOperation { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: AppDataManagerDidChangeNotification), object: nil)
        }
    }
    
    open static let sharedManager = WatchSessionManager()
    
    fileprivate override init() {
        super.init()
        currentlySendingMessage = false
        
        loadData()
        setupNotifications()
    }
    
    deinit {
        saveData()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate let session : WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    open var validSession: WCSession? {
        guard let session = session , session.isReachable else {
            return nil
        }
        
        return session
    }
    
    open func startSession() {
        if WCSession.isSupported() {
            session?.delegate = self
            session?.activate()
            
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported), Paired Phone Reachable: \(session?.isReachable)")
            #endif
        }
    }
    
    fileprivate var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    open func addDataSourceChangedDelegate<T>(_ delegate: T) where T: DataSourceChangedDelegate, T: Equatable {
        dataSourceChangedDelegates.append(delegate)
    }
    
    open func removeDataSourceChangedDelegate<T>(_ delegate: T) where T: DataSourceChangedDelegate, T: Equatable {
        for (index, indexDelegate) in dataSourceChangedDelegates.enumerated() {
            if let indexDelegate = indexDelegate as? T , indexDelegate == delegate {
                dataSourceChangedDelegates.remove(at: index)
                
                break
            }
        }
    }
    
    fileprivate struct SharedAppGroupKey {
        static let NightscouterGroup = "group.com.nothingonline.nightscouter"
    }
    
    fileprivate let defaults = UserDefaults(suiteName: SharedAppGroupKey.NightscouterGroup)!
    
    open var models: [WatchModel] = [] {
        didSet {
            let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
            
            defaults.set(models, forKey: DefaultKey.sites.rawValue)
            
            if models.isEmpty {
                defaultSiteUUID = nil
                currentSiteIndex = 0
            }
            
            reloadComplications()
        }
    }
    
    open var currentSiteIndex: Int {
        set{
            defaults.set(newValue, forKey: DefaultKey.lastViewedSiteIndex.rawValue)
            
        }
        get{
            return defaults.integer(forKey: DefaultKey.lastViewedSiteIndex.rawValue)
        }
    }
    
    open var defaultSiteUUID: UUID? {
        set{
            defaults.set(newValue?.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
            
            var payload = [String: AnyObject]()
            payload[DefaultKey.primarySiteUUID.rawValue] = newValue?.uuidString as AnyObject?
            session?.transferUserInfo(payload)
            
            updateComplication { complicationData in
                self.reloadComplications()
            }
        }
        get {
            if let uuidString = defaults.object(forKey: DefaultKey.primarySiteUUID.rawValue) as? String {
                return UUID(uuidString: uuidString)
            } else if let firstModel = models.first {
                return UUID(uuidString: firstModel.uuid)
            }
            
            return nil
        }
    }
    
    open func defaultModel() -> WatchModel? {
        
        let uuidString = defaultSiteUUID?.uuidString
        
        let matched = self.models.filter({ (model) -> Bool in
            return model.uuid == uuidString
        })
        
        return matched.first ?? models.first
    }
    
    open func updateModel(_ model: WatchModel)  ->  Bool {
        var success = false
        modelInfoQueue.sync {
            if let index = self.models.index(of: model) {
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
    
    open var lastReloadDate: Date {
        get {
            return defaults.object(forKey: "lastReloadDate") as? Date ?? Date()
        }
        set {
            return defaults.set(newValue, forKey: "lastReloadDate")
        }
    }
    
    open var lastAttmemptToUpdate: Date? {
        get {
            return defaults.object(forKey: "lastAttmemptToUpdate") as?  Date
        }
        set {
            defaults.set(newValue, forKey: "lastAttmemptToUpdate")
        }
    }
    
    open var lastUpdateTimeStamp: Date? {
        get {
            return defaults.object(forKey: "lastUpdateTimeStamp") as?  Date
        }
        set {
            defaults.set(newValue, forKey: "lastUpdateTimeStamp")
        }
    }
    
    fileprivate var currentlySendingMessage: Bool {
        get {
            return defaults.bool(forKey: "currentlySendingMessage")
        }
        set {
            lastAttmemptToUpdate = Date()
            defaults.set(newValue, forKey: "currentlySendingMessage")
        }
    }
    
    
    fileprivate func setupNotifications() {
        // Listen for global update timer.
        NotificationCenter.default.addObserver(self, selector: #selector(WatchSessionManager.dataStaleUpdate(_:)), name: NSNotification.Name(rawValue: NightscoutAPIClientNotification.DataIsStaleUpdateNow), object: nil)
    }
    
    func dataStaleUpdate(_ notif: Notification) {
        updateData(forceRefresh: true)
    }
    
    // MARK: Save and Load Data
    open func saveData() {
        print("Saving Data")
        let models: [[String : AnyObject]] = self.models.flatMap( { $0.dictionary } )
        
        defaults.set(models, forKey: DefaultKey.sites.rawValue)
        defaults.set(currentSiteIndex, forKey: DefaultKey.lastViewedSiteIndex.rawValue)
        defaults.set("watchOS", forKey: DefaultKey.osPlatform.rawValue)
        defaults.set(defaultSiteUUID?.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
    }
    
    open func loadData() {
        
        if let models = defaults.array(forKey: DefaultKey.sites.rawValue) as? [[String : AnyObject]] {
            self.models = models.flatMap{ WatchModel(fromDictionary: $0) }
        }
        
        // Register for settings changes as store might have changed
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: defaults)
    }
    
    
}

@available(watchOSApplicationExtension 2.2, *)
extension WatchSessionManager {
    
    @objc(session:activationDidCompleteWithState:error:) public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        
        // Do not proceed if `session` is not currently `.Activated`.
        guard session.activationState == .activated else { return }
        
        print("\(#function)= session.activationState = \(session.activationState)")
        
        if !session.receivedApplicationContext.isEmpty {
            print("!session.receivedApplicationContext.isEmpty")
            processApplicationContext(WCSession.default().receivedApplicationContext as [String : Any])
        }
        
        updateData(forceRefresh: false)
    }
    
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print(#function)
        // print("\(userInfo)")
        
        DispatchQueue.main.async { [weak self] in
            self?.processApplicationContext(userInfo as [String : Any], updateDelegates: true)
        }
    }
    
    // Receiver
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(#function)
        // print("received: \(applicationContext)")
        
        DispatchQueue.main.async { [weak self] in
            self?.processApplicationContext(applicationContext as [String : Any])
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(#function)
        // print(message)
        
        DispatchQueue.main.async { [weak self] in
            self?.processApplicationContext(message as [String : Any])
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print(#function)
        // print(session)
        
        if session.isReachable == true && currentlySendingMessage == false {
            updateData(forceRefresh: false)
        }
    }
    
}

extension WatchSessionManager {
    
    public func processApplicationContext(_ context: [String : Any], updateDelegates update: Bool = true) {
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
        
        if let modelArray = payload[DefaultKey.sites.rawValue] as? [[String: AnyObject]] {
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
    
    func updateDelegatesForError(_ errorType: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceCouldNotConnectToPhone(errorType) }
        }
    }
    
    func updateDelegatesForModelChange(_ models:[WatchModel]) {
        DispatchQueue.main.async { [weak self] in
            print("\(#function) UPDATING DELEGATES!!!!! -------")
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext(
                models) }
        }
    }
    
}

extension WatchSessionManager {
    
    public func complicationRequestedUpdateBudgetExhausted() {
        
        let requestReceived = "complicationRequestedUpdateBudgetExhausted"
        
        if var updateArray = defaults.array(forKey: requestReceived) as? [Date] {
            if updateArray.count > 5 {
                updateArray.removeLast()
            }
            updateArray.append(Date())
            defaults.set(updateArray, forKey: requestReceived)
        } else {
            defaults.set([Date()], forKey: requestReceived)
        }
        
        updateComplication { complicationData in
            // ComplicationController.reloadComplications()
        }
    }
    
    public var nextRequestedComplicationUpdateDate: Date {
        let updateInterval: TimeInterval = Constants.StandardTimeFrame.OneHourInSeconds
        
        if let defaultModel = defaultModel() {
            return defaultModel.lastReadingDate.addingTimeInterval(updateInterval)
        }
        
        return Date(timeIntervalSinceNow: updateInterval)
    }
    
    public var complicationData: [ComplicationModel] {
        get {
            var complicationModels: [ComplicationModel] = []
            modelInfoQueue.sync {
                complicationModels = self.defaultModel()?.complicationModels.flatMap{ ComplicationModel(fromDictionary: $0) } ?? []
            }
            
            return complicationModels
        }
    }
    
    public func updateComplication(_ completion: @escaping (_ timline: [ComplicationModel]) -> Void) {
        print(#function)
        
        let requestReceived = "requestedUpdateDidBeginRequestRecieved"
        
        if var updateArray = defaults.array(forKey: requestReceived) as? [Date] {
            if updateArray.count > 5 {
                updateArray.removeLast()
            }
            updateArray.append(Date())
            defaults.set(updateArray, forKey: requestReceived)
        } else {
            defaults.set([Date()], forKey: requestReceived)
        }
        
        let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.UpdateComplication.rawValue]
        
        guard let model = self.defaultModel() else {
            print("No model was found... returning empty timline in \(#function)")
            
            completion([])
            return
        }
        
        if model.updateNow {
            
            print("Updating because: model needs updating: \(model.updateNow)")
            self.currentlySendingMessage = true
            
            guard let validSession = validSession else {
                fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                    WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                    completion(returnedSite.complicationModels)
                })
                
                return
            }
            
            validSession.sendMessage(messageToSend, replyHandler: {(context:[String : Any]) -> Void in
                // handle reply from iPhone app here
                print("\(#function): recievedMessageReply from iPhone")
                
                self.currentlySendingMessage = false
                
                DispatchQueue.main.async { [weak self] in
                    print("updateComplication success...")
                    self?.processApplicationContext(context)
                    completion(self?.complicationData ?? [])
                }
                
                }, errorHandler: {(error: Error ) -> Void in
                    print("\(#function): recieved error from phone: \(error)")
                    self.currentlySendingMessage = false
                    
                     let watchErrorCode =  WCError(_nsError: error as NSError).code
                    
                    switch watchErrorCode {
                    case .sessionNotActivated:
                        self.session?.activate()
                    case .messageReplyTimedOut:
                        print(error)
                        
                    default:
                        fetchSiteData(model.generateSite(), handler: { (returnedSite, error) -> Void in
                            WatchSessionManager.sharedManager.updateModel(returnedSite.viewModel)
                            completion(returnedSite.complicationModels)
                        })
                    }
            })
            
        } else {
            completion(self.complicationData)
        }
        
    }
    
    public func updateData(forceRefresh refresh: Bool) {
        print(">>> Entering \(#function) <<<")
        
        let minModel = self.models.min { (lModel, rModel) -> Bool in
            return (rModel.lastReadingDate <= lModel.lastReadingDate)
        }
        
        if let model = minModel , (model.updateNow || refresh == false) && currentlySendingMessage == false {
            
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
            
            validSession.sendMessage(messageToSend, replyHandler: {(context:[String : Any]) -> Void in
                // handle reply from iPhone app here
                print("recievedMessageReply from iPhone")
                DispatchQueue.main.async { [weak self] in
                    print("WatchSession success...")
                    self?.currentlySendingMessage = false
                    self?.processApplicationContext(context)
                }
                
                }, errorHandler: {(error: Error ) -> Void in
                    print("WatchSession Transfer Error: \(error)")
                    self.currentlySendingMessage = false
                    
                    let watchErrorCode =  WCError(_nsError: error as NSError).code
                    
                    
                    switch watchErrorCode {
                    case .sessionNotActivated:
                        self.session?.activate()
                    case .messageReplyTimedOut:
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
    
    func userDefaultsDidChange(_ notification: Notification) {
        //print("userDefaultsDidChange:")
        
        guard let _ = notification.object as? UserDefaults else { return }
        
        postNotificaitonForDefaults()
    }
    
}
