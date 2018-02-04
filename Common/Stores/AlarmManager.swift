//
//  AlarmManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/20/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation


open class AlarmManager: NSObject, SessionManagerType  {
    
    @objc public static let sharedManager = AlarmManager()
    
    /// The store that the session manager should interact with.
    public var store: SiteStoreType?
    
    fileprivate var updateTimer: Timer?
    
    public var alarmObject: AlarmObject? {
        get {
            guard let sites = store?.sites else {
                return nil
            }
            
            var urgent: Bool = false
            var alarmForSGV: Bool = false
            
            let alarmingSites = sites.filter { site in
                if site.alarmDetails.isAlarming {
                    urgent = site.alarmDetails.urgent
                    alarmForSGV = site.alarmDetails.alarmForSGV
                    return true
                }
                
                return false
            }
            
            var snoozeText: String = LocalizedString.generalAlarmMessage.localized
            
            if AlarmRule.isSnoozed {
                snoozeText = String(format: LocalizedString.snoozedForLabel.localized, "\(AlarmRule.remainingSnoozeMinutes)")
            }
            
            let warningsFound: Bool = !alarmingSites.isEmpty
            
            if !warningsFound {
                AlarmRule.disableSnooze()
                updateTimer?.invalidate()
                updateTimer = nil
                return nil
            }
            
            let isSnoozed = AlarmRule.isSnoozed
            let snoozeTimeRemaining = AlarmRule.remainingSnoozeMinutes
            
            let alarmObject = AlarmObject(warning: warningsFound, urgent: urgent, isAlarmingForSgv: alarmForSGV, isSnoozed: isSnoozed, snoozeText: snoozeText, snoozeTimeRemaining: snoozeTimeRemaining)
            
            /*
             If things are active... we need to play...
             but if the player is currently playing we shouldn't start again.
             Also if the alarm rule is snoozing we shouldn't sound again, right?
             */
            if isSnoozed && updateTimer == nil {
                createTimer()
            }
            
            return alarmObject
        }
    }
    
    fileprivate func createTimer() {
        let snoozeTimer = Timer.scheduledTimer(timeInterval: TimeInterval.OneMinute, target: self, selector: #selector(AlarmManager.postAlarmUpdateNotifiaction), userInfo: nil, repeats: true)
        updateTimer = snoozeTimer
    }
    
    private override init() {
        super.init()
    }
    
    @objc public func startSession() {
        AlarmRule.snooze(seconds: 5)
    }
    
    public func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        delayPost()
    }

    @objc var delayPost = debounce(delay: 3) {
        NotificationCenter.default.post(name: .nightscoutAlarmNotification, object: AlarmManager.sharedManager.alarmObject)
    }

    @objc func requestCompanionAppUpdate() {
        print(">>> Entering \(#function) <<<")
        var messageToSend: [String : Any] = DefaultKey.payloadAlarmUpdate
        
        let encoder = JSONEncoder()
        messageToSend[DefaultKey.alarm.rawValue] = try? encoder.encode(alarmObject)
      //  store?.handleApplicationContextPayload(messageToSend)
    }
    
    @objc func postAlarmUpdateNotifiaction() {
        print(">>> Entering \(#function) <<<")
        self.store?.postNotificationOnMainQueue(name: .nightscoutAlarmNotification, object: self.alarmObject)
    }
}


