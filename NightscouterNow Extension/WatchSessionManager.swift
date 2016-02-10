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
        
        sharedDefaults?.setObject("watchOS", forKey: DefaultKey.osPlatform)
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    private let session: WCSession = WCSession.defaultSession()
    
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
            
            //createComplication()
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
    
    public func requestLatestAppContext(watchAction action: WatchAction) -> Bool {
        print("requestLatestAppContext")
        let applicationData = [WatchModel.PropertyKey.actionKey: action.rawValue]
        
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
        
        guard let _ = WatchAction(rawValue: (context[WatchModel.PropertyKey.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(context)")
            return false
        }
        
        guard let payload = context[WatchModel.PropertyKey.contextKey] as? [String: AnyObject] else {
            print("No payload was found.")
            
            print(context)
            return false
            
        }

        // if let defaultSiteString = payload[DefaultKey.defaultSiteKey] as? String, uuid = NSUUID(UUIDString: defaultSiteString)  {
          //  defaultSite = uuid
        // }
        
        if let currentIndex = payload[DefaultKey.currentSiteIndexKey] as? Int {
            currentSiteIndex = currentIndex
        }
        
        if let siteArray = payload[DefaultKey.modelArrayObjectsKey] as? [[String: AnyObject]] {
            models = siteArray.map({ WatchModel(fromDictionary: $0)! })
            updateComplication()
        }
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdateAppContext((self?.models)!) }
            ComplicationController.reloadComplications()
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
        
        let updateInterval: NSTimeInterval = 60.0 * 6.0
        if let date = sharedDefaults?.objectForKey(DefaultKey.complicationLastUpdateDidChangeComplicationDate) as? NSDate {
            return date.dateByAddingTimeInterval( updateInterval )
        }
        
        return NSDate(timeIntervalSinceNow: updateInterval)
    }
    
    public var complicationData: [ComplicationModel] {
        get {
            return self.modelForComplication()?.complicationModels.flatMap{ ComplicationModel(fromDictionary: $0)} ?? []
        }
    }
    
    public func updateComplication() {
        
        if let model = self.modelForComplication() {
            let url = NSURL(string: model.urlString)!
            let siteToLoad = Site(url: url, apiSecret: nil, uuid: NSUUID(UUIDString: model.uuid)!)!
            
            fetchSiteData(forSite: siteToLoad, handler: { (reloaded, returnedSite, returnedIndex, returnedError) -> Void in
                self.updateModel(WatchModel(fromSite: returnedSite))
                
                ComplicationController.reloadComplications()
                return
            })
        }
    }
    
}
