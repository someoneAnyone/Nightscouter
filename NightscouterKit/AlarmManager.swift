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
    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, snoozed: Bool)
}

public class AlarmManager {
    
    public static let sharedManager = AlarmManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private var mute : Bool = false
    
    public var snoozeText: String = "Snooze"
    
    private var active: Bool = false
    
    private init() {
        AlarmRule.snoozeSeconds(15)
    }
    
    deinit {
        endAlarmMonitor()
    }
    
    private var alarmManagerDelegates = [AlarmManagerDelgate]()
    
    public func addAlarmManagerDelgate<T where T: AlarmManagerDelgate, T: Equatable>(delegate: T) {
        alarmManagerDelegates.append(delegate)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dataManagerDidChange(_:)), name: AppDataManagerDidChangeNotification, object: nil)
    }
    
    public func endAlarmMonitor() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private var lastHashOfSite: Int?
    
    @objc private func dataManagerDidChange(notifcation: NSNotification) {
        
        guard let sites = notifcation.object as? [Site] else {
            return
        }
        
        
        let (active, alarmUrl, urgent) = AlarmRule.isAlarmActivated(forSites: sites)
        
        self.active = active
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: active, snoozed: AlarmRule.isSnoozed()) }
        }
        /*
         If things are active... we need to play...
         but if the player is currently playing we shouldn't start again.
         Also if the alarm rule is snoozing we shouldn't sound again?
         */
        if AlarmRule.isSnoozed() {
            return
        }
        
        if active && (audioPlayer == nil) {
            //warning
            // play alarm....
            playAlarmFor((alarmUrl!), urgent: urgent)
        } else if !active {
            stop()
        }
    }
    
    public func stop() {
        audioPlayer?.stop()
    }
    
    public func play() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Play endless loops
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.numberOfLoops = -1
            self.audioPlayer?.play()
            
            if #available(iOSApplicationExtension 9.0, *) {
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate), {
                    
                })
            } else {
                // Fallback on earlier versions
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            
            
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
        mute = false
    }
    
    public func muteVolume() {
        audioPlayer?.volume = 0
        mute = true
    }
    
    public func playAlarmFor(url: NSURL, urgent: Bool = false) {
        let assetName = urgent ? "alarm2" : "alarm"
        let audioUrl = url.URLByAppendingPathComponent("/audio/\(assetName).mp3")
        
        var downloadTask:NSURLSessionDownloadTask
        downloadTask = NSURLSession.sharedSession().downloadTaskWithURL(audioUrl, completionHandler: { (URL, response, error) -> Void in
            
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOfURL: URL!)
                self.play()
            } catch let error as NSError {
                print(error.localizedDescription)
            } catch {
                print("AVAudioPlayer init failed")
            }
        })
        
        downloadTask.resume()
    }
    
    public func updateSnoozeButtonText() {
        // var snoozeText: String = "Snooze"
        if AlarmRule.isSnoozed() {
            snoozeText = "Snoozed for " + String(AlarmRule.getRemainingSnoozeMinutes()) + "min"
            print(snoozeText)
        }
    }
    
    public func presentSnoozePopup(forViewController viewController: UIViewController) {
        if AlarmRule.isSnoozed() {
            AlarmRule.disableSnooze()
            snoozeText = "Snooze"
        } else {
            
            self.muteVolume()
            
            let alertController = UIAlertController(title: "Snooze", message: "How long should the alarm be ignored?", preferredStyle: UIAlertControllerStyle.Alert)
            
            alertController.addAction(UIAlertAction(title: "30 Minutes",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snoozeMinutes(30)
            }))
            alertController.addAction(UIAlertAction(title: "1 Hour",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snoozeMinutes(60)
            }))
            alertController.addAction(UIAlertAction(title: "1 1/2 Hours",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snoozeMinutes(90)
            }))
            alertController.addAction(UIAlertAction(title: "2 Hours",
                style: UIAlertActionStyle.Default,
                handler: {(alert: UIAlertAction!) in
                    
                    self.snoozeMinutes(120)
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
    
    public func snoozeMinutes(minutes : Int) {
        
        AlarmRule.snooze(minutes)
        
        AlarmManager.sharedManager.stop()
        AlarmManager.sharedManager.unmuteVolume()
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self?.active ?? false, snoozed: AlarmRule.isSnoozed()) }
        }
        
        self.updateSnoozeButtonText()
    }
    
}