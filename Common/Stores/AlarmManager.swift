//
//  AlarmManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/20/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation



/*
open class AlarmManager: NSObject, SessionManagerType  {
    
    public static let sharedManager = AlarmManager()
    
    /// The store that the session manager should interact with.
    public var store: SiteStoreType?
    
    var alarmObject: AlarmObject {
        return AlarmObject(warning: active, urgent: urgent, isAlarmingForSgv: isAlarmingForSgv, isSnoozed: isSnoozed, snoozeText: snoozeText, snoozeTimeRemaining: snoozeTimeRemaining)
    }
    
    fileprivate var active: Bool = false
    fileprivate var urgent: Bool = false
    fileprivate var isAlarmingForSgv: Bool = false
    fileprivate var updateTimer: Timer?
    
    fileprivate func createTimer() {
        let snoozeTimer = Timer.scheduledTimer(timeInterval: TimeInterval.OneMinute, target: self, selector: #selector(AlarmManager.requestCompanionAppUpdate), userInfo: nil, repeats: true)
        updateTimer = snoozeTimer
    }
    
    private override init() {
        super.init()
    }
    
    public func startSession() {
        AlarmRule.snooze(seconds: 3)
    }
    
    public func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        
        guard let sites = store?.sites else {
            return
        }
        
        let alarmingSites = sites.filter { site in
            let viewModel = site.isAlarming
            if viewModel.warn || viewModel.urgent || viewModel.alarmForSGV {
                urgent = viewModel.urgent
                return true
            } else {
                return false
            }
        }
        
        if alarmingSites.isEmpty {
            AlarmRule.disableSnooze()
        }
        
        self.active = !alarmingSites.isEmpty
        
        /*
         If things are active... we need to play...
         but if the player is currently playing we shouldn't start again.
         Also if the alarm rule is snoozing we shouldn't sound again, right?
         */
        if isSnoozed {
            guard updateTimer != nil else {
                createTimer()
                return
            }
            
            return
        }
        
        DispatchQueue.main.async {
            self.postAlarmUpdateNotifiaction()
        }
        
    }
}

extension AlarmManager: Snoozable {
    public func snooze(forMiutes minutes: Int) {
        AlarmRule.snooze(minutes)
    }
    
    open var snoozeTimeRemaining: Int {
        return AlarmRule.remainingSnoozeMinutes
    }
    
    open var isSnoozed: Bool {
        return AlarmRule.isSnoozed
    }
    
    open var snoozeText: String {
        if AlarmRule.isSnoozed {
            return String(format: LocalizedString.snoozedForLabel.localized, "\(AlarmRule.remainingSnoozeMinutes)")
        }
        
        return ""
    }
}

extension AlarmManager {
    public func requestCompanionAppUpdate() {
        print(">>> Entering \(#function) <<<")
        var messageToSend: [String: Any] = DefaultKey.payloadAlarmUpdate
        messageToSend[DefaultKey.alarm.rawValue] = alarmObject.encode()
        store?.handleApplicationContextPayload(messageToSend)
    }
    
    fileprivate func postAlarmUpdateNotifiaction() {
        print(">>> Entering \(#function) <<<")
        NotificationCenter.default.post(name: .NightscoutAlarmNotification, object: alarmObject)
    }
}
*/


