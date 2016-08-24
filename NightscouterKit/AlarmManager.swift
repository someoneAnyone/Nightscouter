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
}

public protocol Snoozable {
    func snooze(forMiutes minutes : Int)
    var snoozeText: String { get }
    var snoozeTimeRemaining: Int { get }
}


public class AlarmManager: AudioCordinator, Snoozable {
    
    public static let sharedManager = AlarmManager()
    
    public var snoozeTimeRemaining: Int {
        return AlarmRule.remainingSnoozeMinutes
    }
    
    public var isSnoozed: Bool {
        return AlarmRule.isSnoozed
    }
    
    public var snoozeText: String {
        if AlarmRule.isSnoozed {
            return String(format: Constants.LocalizedString.snoozedForLabel.localized, "\(AlarmRule.remainingSnoozeMinutes)")
        }
        
        return ""
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var muted: Bool = false
    private var active: Bool = false
    private var urgent: Bool = false
    private var updateTimer: NSTimer?
    private var alarmManagerDelegates = [AlarmManagerDelgate]()
    
    private init() {
        // AlarmRule.snoozeSeconds(0)
    }
    
    private func createTimer() {
        let snoozeTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.StandardTimeFrame.OneMinuteInSeconds, target: self, selector: #selector(AlarmManager.updateDelegates(_:)), userInfo: nil, repeats: true)
        
        updateTimer = snoozeTimer
    }
    
    deinit {
        endAlarmMonitor()
    }
    
    public func addAlarmManagerDelgate<T where T: AlarmManagerDelgate, T: Equatable>(delegate: T) {
        alarmManagerDelegates.append(delegate)
        if isSnoozed && updateTimer == nil {
            createTimer()
            return
        }
    }
    
    public func removeAlarmManagerDelgate<T where T: AlarmManagerDelgate, T: Equatable>(delegate: T) {
        for (index, indexDelegate) in alarmManagerDelegates.enumerate() {
            if let indexDelegate = indexDelegate as? T where indexDelegate == delegate {
                alarmManagerDelegates.removeAtIndex(index)
                
                break
            }
        }
    }
    
    public func startAlarmMonitor() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AlarmManager.dataManagerDidChange(_:)), name: AppDataManagerDidChangeNotification, object: nil)
    }
    
    public func endAlarmMonitor() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        updateTimer?.invalidate()
    }
    
    
    @objc private func updateDelegates(notofication: NSTimer? = nil){
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self!.active, urgent: self!.urgent, snoozed: self!.isSnoozed) }
        }
    }
    
    @objc private func dataManagerDidChange(notifcation: NSNotification) {
        
        guard let sites = notifcation.object as? [Site] else {
            return
        }
        
        let (active, urgent) = AlarmRule.isAlarmActivated(forSites: sites)
        
        self.active = active
        self.urgent = urgent
        
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
        
        if active && (audioPlayer == nil) {
            //warning
            // play alarm....
            playAlarmFor(urgent)
        } else if !active {
            stop()
        }
        
        updateDelegates()
        
    }
    
    public func stop() {
        audioPlayer?.stop()
        try! AVAudioSession.sharedInstance().setActive(false)
    }
    
    public func play() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
            try AVAudioSession.sharedInstance().setActive(true, withOptions: .NotifyOthersOnDeactivation)
            
            // Play endless loops
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.numberOfLoops = -1
            self.audioPlayer?.play()
            
        } catch {
            print("Audio Error: \(error)")
            print("Unable to play sound!")
        }
    }
    
    public func pause() {
        self.audioPlayer?.pause()
    }
    
    public func unmuteVolume(){
        audioPlayer?.volume = 1.0
        muted = false
    }
    
    public func muteVolume() {
        audioPlayer?.volume = 0
        muted = true
    }
    
    public func playAlarmFor(urgent: Bool = false) {
        let assetName = urgent ? "alarm2" : "alarm"
        
        let bundle: NSBundle = NSBundle(forClass: AlarmManager.self)
        let path: String = bundle.pathForResource(assetName, ofType: "mp3") ?? ""
        let audioUrl = NSURL.fileURLWithPath(path)
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: audioUrl)
            self.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    public func presentSnoozePopup(forViewController viewController: UIViewController) {
        if AlarmRule.isSnoozed {
            AlarmRule.disableSnooze()
        } else {
            
            self.muteVolume()
            
            let alertController = UIAlertController(title: Constants.LocalizedString.snoozeLabel.localized, message: Constants.LocalizedString.snoozeMessage.localized, preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction(title: "30 \(Constants.LocalizedString.minutes.localized)",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 30)
            }))
            alertController.addAction(UIAlertAction(title: "1 \(Constants.LocalizedString.hour.localized)",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 60)
            }))
            alertController.addAction(UIAlertAction(title: "1 1/2 \(Constants.LocalizedString.hours.localized)",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 90)
            }))
            alertController.addAction(UIAlertAction(title: "2 \(Constants.LocalizedString.hours.localized)",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snooze(forMiutes: 120)
            }))
            alertController.addAction(UIAlertAction(title: Constants.LocalizedString.generalCancelLabel.localized
                ,
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    self.unmuteVolume()
            }))
            
            viewController.presentViewController(alertController, animated: true, completion: nil)
            alertController.view.tintColor = NSAssetKit.darkNavColor
        }
        
    }
    
    public func snooze(forMiutes minutes : Int) {
        
        AlarmRule.snooze(minutes)
        
        AlarmManager.sharedManager.stop()
        AlarmManager.sharedManager.unmuteVolume()
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self?.active ?? false, urgent: self?.urgent ?? false, snoozed: self?.isSnoozed ?? false) }
        }
        
        //self.updateSnoozeButtonText()
    }
    
}
