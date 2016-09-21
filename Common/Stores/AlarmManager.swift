//
//  AlarmManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/20/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

//#if os(iOS)
//    import AVFoundation
//#elseif os(watchOS)
//    import AVKit
//#elseif os(OSX)
//#endif

public protocol AlarmManagerDelgate {
    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, urgent: Bool, snoozed: Bool)
}

public protocol AudioCordinator {
    //func startAlarmMonitor()
    //func endAlarmMonitor()
    func stop()
    func play()
    func pause()
    func unmuteVolume()
    func muteVolume()
    
    func playAlarmFor(_ urgent: Bool)
    
    //func addAlarmManagerDelgate<T>(_ delegate: T) where T : AlarmManagerDelgate, T : Equatable
    //func removeAlarmManagerDelgate<T>(_ delegate: T) where T : AlarmManagerDelgate, T : Equatable
}

public struct AlarmObject {
    
    let warning: Bool
    let urgent: Bool
    let isAlarmingForSgv: Bool
    let isSnoozed: Bool
    let snoozeText: String
    let snoozeTimeRemaining: Int
    
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

public protocol Snoozable {
    func snooze(forMiutes minutes : Int)
    var snoozeText: String { get }
    var snoozeTimeRemaining: Int { get }
    var isSnoozed: Bool { get }
}

class AlarmManager: NSObject, SessionManagerType  {
    
    public static let sharedManager = AlarmManager()
    
    /// The store that the session manager should interact with.
    public var store: SiteStoreType?
    
//    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var muted: Bool = false
    fileprivate var active: Bool = false
    fileprivate var urgent: Bool = false
    fileprivate var isAlarmingForSgv: Bool = false
    fileprivate var updateTimer: Timer?
    
    fileprivate func createTimer() {
        let snoozeTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(AlarmManager.requestCompanionAppUpdate), userInfo: nil, repeats: true)
        updateTimer = snoozeTimer
    }
    
    private override init() {
        super.init()
        
    }
    
    func startSession() {
        AlarmRule.snooze(seconds: 3)
    }
    
    func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        
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
            stop()
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
        
        /*
        if active && (audioPlayer == nil) {
            //warning
            // play alarm....
            playAlarmFor(urgent)
        } else if !active && audioPlayer!.isPlaying {
            stop()
        }*/
        
    }
}

///
/*
 Not sure how to handle this behavior...
 
 We need the alarming system to track changes to the sites... get updated whenever the site data changes. But where is the best place to do this?
 
 Also once we havse an alarm... who and how is it managed...
 for example, who is responsible to snooze and update the user interface of its status?
 
 presentation of dialogs and stuff should be done in the app layer, but handlig of snooze and
 text should probably come from a one place.si
 
 */

extension AlarmManager: AudioCordinator {
    
    open func stop() {
//        audioPlayer?.stop()
//        try! AVAudioSession.sharedInstance().setActive(false)
    }
    
    open func play() {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
//            try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
//            
//            // Play endless loops
//            self.audioPlayer?.prepareToPlay()
//            self.audioPlayer?.numberOfLoops = -1
//            self.audioPlayer?.play()
//            
//        } catch {
//            print("Audio Error: \(error)")
//            print("Unable to play sound!")
//        }
    }
    
    open func pause() {
//        self.audioPlayer?.pause()
    }
    
    open func unmuteVolume(){
//        audioPlayer?.volume = 1.0
        muted = false
    }
    
    open func muteVolume() {
//        audioPlayer?.volume = 0
        muted = true
    }
    
    open func playAlarmFor(_ urgent: Bool = false) {
        let assetName = urgent ? "alarm2" : "alarm"
        
        let bundle: Bundle = Bundle(for: AlarmManager.self)
        let path: String = bundle.path(forResource: assetName, ofType: "mp3") ?? ""
        let audioUrl = URL(fileURLWithPath: path)
        
        do {
//            self.audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            self.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
}

extension AlarmManager {
    public func requestCompanionAppUpdate() {
        print(">>> Entering \(#function) <<<")
        var messageToSend: [String: Any] = DefaultKey.payloadAlarmUpdate
        
        let alarmObject = AlarmObject(warning: active, urgent: urgent, isAlarmingForSgv: isAlarmingForSgv, isSnoozed: isSnoozed, snoozeText: snoozeText, snoozeTimeRemaining: snoozeTimeRemaining)
        
        messageToSend["object"] = alarmObject.encode()
        
        store?.handleApplicationContextPayload(messageToSend)
    }
}

extension AlarmManager: Snoozable {
    
    public func snooze(forMiutes minutes: Int) {
        AlarmRule.snooze(minutes)
        
        AlarmManager.sharedManager.stop()
        AlarmManager.sharedManager.unmuteVolume()
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
