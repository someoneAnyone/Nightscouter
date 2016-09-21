//
//  AlarmManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 5/21/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//
import UIKit
import AVFoundation

public protocol AlarmManagerDelgate {
    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, urgent: Bool, snoozed: Bool)
}

public protocol AudioCordinator {
    func startAlarmMonitor()
    func endAlarmMonitor()
    func stop()
    func play()
    func pause()
    func unmuteVolume()
    func muteVolume()
    
    func playAlarmFor(_ urgent: Bool)
    
    func addAlarmManagerDelgate<T>(_ delegate: T) where T : AlarmManagerDelgate, T : Equatable
    func removeAlarmManagerDelgate<T>(_ delegate: T) where T : AlarmManagerDelgate, T : Equatable
}

public protocol Snoozable {
    func snooze(forMiutes minutes : Int)
    var snoozeText: String { get }
    var snoozeTimeRemaining: Int { get }
    var isSnoozed: Bool { get }
}

open class AlarmManager: AudioCordinator, Snoozable {
    
    open static let sharedManager = AlarmManager()
    
    open var snoozeTimeRemaining: Int {
        return AlarmRule.remainingSnoozeMinutes
    }
    
    open var isSnoozed: Bool {
        return AlarmRule.isSnoozed
    }
    
    open var snoozeText: String {
        if AlarmRule.isSnoozed {
            return String(format: Constants.LocalizedString.snoozedForLabel.localized, "\(AlarmRule.remainingSnoozeMinutes)")
        }
        
        return ""
    }
    
    open var alarmCurrentStatus: (alarm: Bool, urgent: Bool, snoozed: Bool) {
        return (self.active, self.urgent, self.isSnoozed)
    }

    
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var muted: Bool = false
    fileprivate var active: Bool = false
    fileprivate var urgent: Bool = false
    fileprivate var updateTimer: Timer?
    fileprivate var alarmManagerDelegates = [AlarmManagerDelgate]()
    
    fileprivate init() {
        AlarmRule.snooze(seconds: 2)
    }
    
    fileprivate func createTimer() {
        let snoozeTimer = Timer.scheduledTimer(timeInterval: TimeInterval.OneMinuteInSeconds, target: self, selector: #selector(AlarmManager.updateDelegates(_:)), userInfo: nil, repeats: true)
        
        updateTimer = snoozeTimer
    }
    
    deinit {
        endAlarmMonitor()
    }
    
    open func addAlarmManagerDelgate<T>(_ delegate: T) where T: AlarmManagerDelgate, T: Equatable {
        alarmManagerDelegates.append(delegate)
        if isSnoozed && updateTimer == nil {
            createTimer()
            return
        }
    }
    
    open func removeAlarmManagerDelgate<T>(_ delegate: T) where T: AlarmManagerDelgate, T: Equatable {
        for (index, indexDelegate) in alarmManagerDelegates.enumerated() {
            if let indexDelegate = indexDelegate as? T , indexDelegate == delegate {
                alarmManagerDelegates.remove(at: index)
                
                break
            }
        }
    }
    
    open func startAlarmMonitor() {
        NotificationCenter.default.addObserver(self, selector: #selector(AlarmManager.dataManagerDidChange(_:)), name: NSNotification.Name(rawValue: AppDataManagerDidChangeNotification), object: nil)
    }
    
    open func endAlarmMonitor() {
        NotificationCenter.default.removeObserver(self)
        updateTimer?.invalidate()
    }
    
    
    @objc fileprivate func updateDelegates(_ notofication: Timer? = nil){
        DispatchQueue.main.async { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self!.active, urgent: self!.urgent, snoozed: self!.isSnoozed) }
        }
    }
    
    @objc fileprivate func dataManagerDidChange(_ notifcation: Notification) {
        
        guard let sites = notifcation.object as? [Site] else {
            return
        }
        
        let (active, urgent, snooze) = AlarmRule.isAlarmActivated(forSites: sites)
        
        self.active = active
        self.urgent = urgent
        
        /*
         If things are active... we need to play...
         but if the player is currently playing we shouldn't start again.
         Also if the alarm rule is snoozing we shouldn't sound again, right?
         */
        if snooze {
            guard updateTimer != nil else {
                createTimer()
                return
            }
            
            return
        }
        
        if active && (audioPlayer == nil) {
            //warning
            // play alarm....
            playAlarmFor(urgent)
        } else if !active {
            stop()
        }
        
        updateDelegates()
        
    }
    
    open func stop() {
        audioPlayer?.stop()
        try! AVAudioSession.sharedInstance().setActive(false)
    }
    
    open func play() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
            try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
            
            // Play endless loops
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.numberOfLoops = -1
            self.audioPlayer?.play()
            
        } catch {
            print("Audio Error: \(error)")
            print("Unable to play sound!")
        }
    }
    
    open func pause() {
        self.audioPlayer?.pause()
    }
    
    open func unmuteVolume(){
        audioPlayer?.volume = 1.0
        muted = false
    }
    
    open func muteVolume() {
        audioPlayer?.volume = 0
        muted = true
    }
    
    open func playAlarmFor(_ urgent: Bool = false) {
        let assetName = urgent ? "alarm2" : "alarm"
        
        let bundle: Bundle = Bundle(for: AlarmManager.self)
        let path: String = bundle.path(forResource: assetName, ofType: "mp3") ?? ""
        let audioUrl = URL(fileURLWithPath: path)
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            self.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    open func presentSnoozePopup(forViewController viewController: UIViewController) {
        if isSnoozed {
            AlarmRule.disableSnooze()
            
            DispatchQueue.main.async { [weak self] in
                self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self?.active ?? false, urgent: self?.urgent ?? false, snoozed: self?.isSnoozed ?? false) }
            }
            
        } else {
            self.muteVolume()
            
            let alertController = UIAlertController(title: Constants.LocalizedString.snoozeLabel.localized, message: Constants.LocalizedString.snoozeMessage.localized, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "30 \(Constants.LocalizedString.minutes.localized)",
                style: UIAlertActionStyle.default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 30)
            }))
            alertController.addAction(UIAlertAction(title: "1 \(Constants.LocalizedString.hour.localized)",
                style: UIAlertActionStyle.default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 60)
            }))
            alertController.addAction(UIAlertAction(title: "1 1/2 \(Constants.LocalizedString.hours.localized)",
                style: UIAlertActionStyle.default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 90)
            }))
            alertController.addAction(UIAlertAction(title: "2 \(Constants.LocalizedString.hours.localized)",
                style: UIAlertActionStyle.default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 120)
            }))
            alertController.addAction(UIAlertAction(title: Constants.LocalizedString.generalCancelLabel.localized
                ,
                style: UIAlertActionStyle.default,
                handler: {(alert: UIAlertAction!) in
                    self.unmuteVolume()
            }))
            
            viewController.present(alertController, animated: true, completion: nil)
            alertController.view.tintColor = NSAssetKit.darkNavColor
        }
    }
    
    open func snooze(forMiutes minutes : Int) {
        
        AlarmRule.snooze(minutes)
        
        AlarmManager.sharedManager.stop()
        AlarmManager.sharedManager.unmuteVolume()
        
        DispatchQueue.main.async { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self?.active ?? false, urgent: self?.urgent ?? false, snoozed: self?.isSnoozed ?? false) }
        }
    }
}
