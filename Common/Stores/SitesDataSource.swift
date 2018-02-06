//
//  SitesDataSource.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public enum DefaultKey: String, RawRepresentable, Codable {
    case sites, lastViewedSiteIndex, primarySiteUUID, lastDataUpdateDateFromPhone, updateData, action, error, alarm, version, watchRequestedUpdate
    
    static var payloadAlarmUpdate: [String : String] {
        return [DefaultKey.action.rawValue: DefaultKey.alarm.rawValue]
    }
    
    static var payloadPhoneUpdate: [String : String] {
        return [DefaultKey.action.rawValue: DefaultKey.updateData.rawValue]
    }
    
    static var payloadPhoneUpdateError: [String : String] {
        return [DefaultKey.action.rawValue: DefaultKey.error.rawValue]
    }
    
    static var currentVersion: String {
        return "3.3"
    }
    
    static var lastVersion: String {
        return "3.2"
    }
}

public class SitesDataSource: SiteStoreType {
    
    public static let sharedInstance = SitesDataSource()
    
    private init() {
        
        self.defaults = UserDefaults(suiteName: AppConfiguration.sharedApplicationGroupSuiteName ) ?? UserDefaults.standard
        
//        NotificationCenter.default.addObserver(
//            self, selector: #selector(type(of:self).defaultsChanged(notif:)),
//            name: UserDefaults.didChangeNotification, object: nil
//        )
        
        #if os(iOS)
            
            let iCloudManager = iCloudKeyValueStore()
            iCloudManager.store = self
            iCloudManager.startSession()
            self.sessionManagers.append(iCloudManager)
            
        #endif
        
        // Need logic for !iOS | WatchOS
        /*
        let watchConnectivityManager = WatchSessionManager.sharedManager
        watchConnectivityManager.store = self
        watchConnectivityManager.startSession()
        */
        
        // Need logic for !iOS | WatchOS
        let watchConnectivityManager = WatchConnectivityCordinator.shared
        watchConnectivityManager.store = self
        watchConnectivityManager.startSession()
//        self.sessionManagers.append(watchConnectivityManager as! SessionManagerType)
        
        let alarmManager = AlarmManager.sharedManager
        alarmManager.store = self
        if !appIsInBackground {
            alarmManager.startSession()
        }
        self.sessionManagers.append(alarmManager)

        print("found \(self.sites.count) sites in the store.")
        
        dataStaleTimer(nil)
        
        sites = loadData()
    }
    
    deinit {
        self.timer?.invalidate()
    }
    
    /// Defaults holds the user defaults for the application. This will be intialized during the init() of this class with "initWithSuiteName:(_:)". If that is not successful it will be the standard defaults container.
    private let defaults: UserDefaults
    
    private var sessionManagers: [SessionManagerType] = []
    
    private var timer: Timer?
    
    public var storageLocation: StorageLocation { return .localKeyValueStore }
    
    fileprivate var concurrentQueue = DispatchQueue(label: "com.nothingonline.nightscouter.sitesdatasource", attributes: .concurrent)
    
    public var sites: [Site] = []
    
    public var appIsInBackground: Bool = true
    
    public var lastViewedSiteIndex: Int {
        set {
            if lastViewedSiteIndex != newValue {
                defaults.set(newValue, forKey: DefaultKey.lastViewedSiteIndex.rawValue)
                defaults.synchronize()
            }
        }
        
        get {
            return defaults.object(forKey: DefaultKey.lastViewedSiteIndex.rawValue) as? Int ?? 0
        }
    }
    
    public var primarySite: Site? {
        set{
            if let site = newValue {
                defaults.set(site.uuid.uuidString, forKey: DefaultKey.primarySiteUUID.rawValue)
            } else {
                defaults.removeObject(forKey: DefaultKey.primarySiteUUID.rawValue)
            }
        }
        get {
            if let uuidString = defaults.object(forKey: DefaultKey.primarySiteUUID.rawValue) as? String {
                return sites.filter { $0.uuid.uuidString == uuidString }.first
            } else if let firstSite = sites.first {
                return firstSite
            }
            return nil
        }
    }
    
    
    // MARK: Array modification methods
    @discardableResult
    public func createSite(_ site: Site, atIndex index: Int?) -> Bool {
        var initial: [Site] = self.sites
        
        if initial.isEmpty {
            primarySite = site
        }
        
        if let index = index {
            initial.insert(site, at: index)
        } else {
            initial.append(site)
        }
        
        
//        let siteData = NSKeyedArchiver.archivedData(withRootObject: initial)
        
        let userInfo: [String: [Site]] = [DefaultKey.sites.rawValue : initial]
  
        sites = initial
        saveData()
  
        self.postNotificationOnMainQueue(name: .nightscoutAddedContentNotification, userInfo: userInfo)
        
        return initial.contains(site)
    }
    
    
    public func updateSite(_ site: Site) {
        concurrentQueue.sync {
            var initial = self.sites
            
            let _ = initial.insertOrUpdate(site)
            
            let userInfo: [String: [Site]] = [DefaultKey.sites.rawValue : initial]
            
            sites = initial
            saveData()
        }
    }
    
    @discardableResult
    public func moveSite(fromIndex oldIndex: Int, toIndex newIndex: Int) -> Bool {
        var initial = sites
        
        do {
            try initial.move(fromIndex: oldIndex, toIndex: newIndex)
            
//            let userInfo: [String: [Site]] = [DefaultKey.sites.rawValue : initial]
            
            sites = initial
            saveData()
            
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func deleteSite(_ site: Site) -> Bool {
        
        var initial = sites
        let success = initial.remove(site)
        
        if success == false {
            return false
        }
        
        if site == lastViewedSite {
            lastViewedSiteIndex = 0
        }
        
        if initial.isEmpty {
            lastViewedSiteIndex = 0
            primarySite = nil
            
            clearAllSites()
        }
        
//        let userInfo: [String: [Site]] = [DefaultKey.sites.rawValue : initial]
        
        sites = initial
        saveData()
        
        return success
    }
    
    public func clearAllSites() -> Bool {
        
        primarySite = nil
        defaults.removeObject(forKey: "currentSiteIndexInt")
        defaults.removeObject(forKey: "siteModelArray")
        defaults.removeObject(forKey: DefaultKey.sites.rawValue)
        defaults.removeObject(forKey: DefaultKey.version.rawValue)
        
        return defaults.synchronize()

    }
    
    public func handleApplicationContextPayload(_ payload: [String : Any]) {
        
        if let sites = payload[DefaultKey.sites.rawValue] as? ArrayOfDictionaries {
            var userInfo: [String: Encodable] = [:]
            userInfo[DefaultKey.sites.rawValue] = sites as? Encodable
//            saveData(userInfo)
        } else {
            print("No sites were found.")
        }
        
        if let lastViewedSiteIndex = payload[DefaultKey.lastViewedSiteIndex.rawValue] as? Int {
            self.lastViewedSiteIndex = lastViewedSiteIndex
        } else {
            print("No lastViewedIndex was found.")
        }
        
        if let uuidString = payload[DefaultKey.primarySiteUUID.rawValue] as? String {
            self.primarySite = sites.filter{ $0.uuid.uuidString == uuidString }.first
        } else {
            self.primarySite = nil
            print("No primarySiteUUID was found.")
        }
        
        if let alarm = payload[DefaultKey.alarm.rawValue] as? [String: Any] {
            let data = try? JSONSerialization.data(withJSONObject: alarm, options: .prettyPrinted)
            if let alarmObject = try? JSONDecoder().decode(Alarm.self, from: data!){
                print("Received and alarm from the monitor: \(alarmObject)")
            }
        } else {
            print("No alarm update was found.")
        }
        
        #if os(watchOS)
            if let lastDataUpdateDateFromPhone = payload[DefaultKey.lastDataUpdateDateFromPhone.rawValue] as? Date {
                defaults.set(lastDataUpdateDateFromPhone,forKey: DefaultKey.lastDataUpdateDateFromPhone.rawValue)
            }
        #endif
        
        if let action = payload[DefaultKey.action.rawValue] as? DefaultKey {
            if action == DefaultKey.updateData {
                print("found an action: \(action)")
                for _ in sites {
                    print("Why?")
                    fatalError()
                }
            } else if action == DefaultKey.error {
                print("Received an error.")
                
            } else {
                print("Did not find an action.")
            }
        }
    }
    
    func createUpdateTimer() -> Timer {
        print(">>> Entering \(#function) <<<")
        let localTimer = Timer.scheduledTimer(timeInterval: TimeInterval.FourMinutes, target: self, selector: #selector(SitesDataSource.dataStaleTimer(_:)), userInfo: nil, repeats: true)
        
        return localTimer
    }
    
    @objc func dataStaleTimer(_ timer: Timer?) -> Void {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print("Posting NightscoutDataStaleNotification Notification at \(Date())")
        #endif
        
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
        
        self.postNotificationOnMainQueue(name: .nightscoutDataStaleNotification, object: timer)
    }
    
    public func loadData() -> [Site] {
        
        if defaults.string(forKey: DefaultKey.version.rawValue) != DefaultKey.currentVersion {
            _ = clearAllSites()
        }
        
        guard let sitesDict = defaults.data(forKey: DefaultKey.sites.rawValue) else {
            return []
        }
        
        do {
            return try PropertyListDecoder().decode([Site].self, from: sitesDict)
            
            
        } catch {
            print(error.localizedDescription)
            
            return []
        }
    }
    
    public func saveData() {
        
        let plist = PropertyListEncoder()
            do {
                let encodedSites = try plist.encode(self.sites)
                
                defaults.set(encodedSites, forKey: DefaultKey.sites.rawValue)
                defaults.set(DefaultKey.currentVersion, forKey: DefaultKey.version.rawValue)
                defaults.synchronize()
                
                self.postNotificationOnMainQueue(name: .nightscoutDataUpdatedNotification)
            } catch {
                print(error)
            }
        }

    
    
//
//    @objc func defaultsChanged(notif: Notification) {
//        print(notif)
//    }
    
    
//    var delayDataUpdateNotification: (()->()) {
//        return debounce(delay: 3, queue: DispatchQueue(label: "com.nothingonline.delay", qos: .userInitiated), action: {
//            self.postNotificationOnMainQueue(name: .nightscoutDataUpdatedNotification)
//        })
//    }
}


/// MOVE SOMEWHERE ELSE
public func debounce(delay: Int, queue: DispatchQueue = DispatchQueue.main, action: @escaping (()->()) ) -> ()->() {
    var lastFireTime = DispatchTime.now()
    let dispatchDelay = DispatchTimeInterval.seconds(delay)
    
    return {
        lastFireTime = DispatchTime.now()
        let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
        queue.asyncAfter(deadline: dispatchTime) {
            let when: DispatchTime = lastFireTime + dispatchDelay
            let now = DispatchTime.now()
            if now >= when {
                action()
            }
        }
    }
}
