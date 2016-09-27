//
//  AlarmManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/20/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation


public protocol AudioCordinator {
    var alarmObject: AlarmObject? { get set }
    func stop()
    func play()
    func pause()
    func unmuteVolume()
    func muteVolume()
}

public protocol Snoozable {
    func snooze(forMiutes minutes : Int)
    var snoozeText: String { get }
    var snoozeTimeRemaining: Int { get }
    var isSnoozed: Bool { get }
}

public struct AlarmObject {
    public let warning: Bool
    public let urgent: Bool
    public let isAlarmingForSgv: Bool
    public let isSnoozed: Bool
    public let snoozeText: String
    public let snoozeTimeRemaining: Int
    public var audioFileURL: URL {
        let assetName = urgent ? "alarm2" : "alarm"
        let bundle: Bundle = Bundle(for: AlarmManager.self)
        let path: String = bundle.path(forResource: assetName, ofType: "mp3") ?? ""
        let audioUrl = URL(fileURLWithPath: path)
        print("url is valid file?: \(audioUrl.isFileURL) && \(FileManager.default.fileExists(atPath: audioUrl.path))")
        return audioUrl
    }
}

extension AlarmObject: Encodable, Decodable {
    struct JSONKey {
        static let warning = "warning"
        static let urgent = "urgent"
        static let isAlarmingForSgv = "isAlarmingForSgv"
        static let isSnoozed = "isSnoozed"
        static let snoozeText = "snoozeText"
        static let snoozeTimeRemaining = "snoozeTimeRemaining"
    }
    
    public func encode() -> [String : Any] {
        return [
            JSONKey.warning: warning,
            JSONKey.urgent: urgent,
            JSONKey.isAlarmingForSgv: isAlarmingForSgv,
            JSONKey.isSnoozed: isSnoozed,
            JSONKey.snoozeText: snoozeText,
            JSONKey.snoozeTimeRemaining: snoozeTimeRemaining,
        ]
    }
    
    public static func decode(_ dict: [String : Any]) -> AlarmObject? {
        guard
            let warning = dict[JSONKey.warning] as? Bool,
            let urgent = dict[JSONKey.urgent] as? Bool,
            let isAlarmingForSgv = dict[JSONKey.isAlarmingForSgv] as? Bool,
            let isSnoozed = dict[JSONKey.isSnoozed] as? Bool,
            let snoozeText = dict[JSONKey.snoozeText] as? String,
            let snoozeTimeRemaining = dict[JSONKey.snoozeTimeRemaining] as? Int
            else {
                return nil
        }
        
        return AlarmObject(warning: warning, urgent: urgent, isAlarmingForSgv: isAlarmingForSgv, isSnoozed: isSnoozed, snoozeText: snoozeText, snoozeTimeRemaining: snoozeTimeRemaining)
    }
}


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



