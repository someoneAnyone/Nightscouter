//
//  AlarmManager.swift
//  Nightscouter
//
//  Created by Peter Ina on 5/21/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//
import UIKit
import AVFoundation

@objc public protocol AlarmManagerDelgate {
    func alarmManagerHasChangedAlarmingState(isActive alarm: Bool, urgent: Bool, snoozed: Bool)
}

public protocol AudioCordinator {
    var alarmManagerDelegates: [AlarmManagerDelgate] { get set }
    func addAlarmManagerDelgate<T where T: AlarmManagerDelgate, T: Equatable>(delegate: T)
    func removeAlarmManagerDelgate<T where T: AlarmManagerDelgate, T: Equatable>(delegate: T)
    func startAlarmMonitor()
    func endAlarmMonitor()
    func stop()
    func paly()
    func pause()
    func unmuteVolume()
    func muteVolume()
}

public protocol Snoozable {
    func snooze(forMiutes minutes : Int)
    func updateSnoozeButtonText()
}

public class AlarmManager {
    
    public static let sharedManager = AlarmManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private var mute : Bool = false
    
    public var snoozeText: String = Constants.LocalizedString.snoozeLabel.localized
    
    private var active: Bool = false
    private var urgent: Bool = false
    
    private init() {
        AlarmRule.snoozeSeconds(4)
    }
    
    deinit {
        endAlarmMonitor()
    }
    
    private var alarmManagerDelegates = [AlarmManagerDelgate]()
    
    public func addAlarmManagerDelgate<T where T: AlarmManagerDelgate, T: Equatable>(delegate: T) {
        alarmManagerDelegates.append(delegate)
        
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self?.active ?? false, urgent: self?.urgent ?? false, snoozed: AlarmRule.isSnoozed()) }
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dataManagerDidChange(_:)), name: AppDataManagerDidChangeNotification, object: nil)
    }
    
    public func endAlarmMonitor() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc private func dataManagerDidChange(notifcation: NSNotification) {
        
        guard let sites = notifcation.object as? [Site] else {
            return
        }
        
        let (active, alarmUrl, urgent) = AlarmRule.isAlarmActivated(forSites: sites)
        
        self.active = active
        self.urgent = urgent
        
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
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: active, urgent: urgent, snoozed: AlarmRule.isSnoozed()) }
        }
    }
    
    public func stop() {
        audioPlayer?.stop()
        //try! AVAudioSession.sharedInstance().setActive(false)
    }
    
    public func play() {
        do {
            //try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
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
        mute = false
    }
    
    public func muteVolume() {
        audioPlayer?.volume = 0
        mute = true
    }
    
    public func playAlarmFor(url: NSURL, urgent: Bool = false) {
        
        let assetName = urgent ? "alarm2" : "alarm"
        
        let bundle = NSBundle(forClass: AlarmManager.self)
        
        let audioUrl = NSURL.fileURLWithPath(
            bundle.pathForResource(assetName,
                ofType: "mp3")!)
        
        
        // let audioUrl = url.URLByAppendingPathComponent("/audio/\(assetName).mp3")
        /*
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
         */
        //downloadTask.resume()
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: audioUrl)
            self.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
        
    }
    
    public func updateSnoozeButtonText() {
        // var snoozeText: String = "Snooze"
        if AlarmRule.isSnoozed() {
            snoozeText = String(format: Constants.LocalizedString.snoozeMessage.localized, AlarmRule.getRemainingSnoozeMinutes())
            
                //"Snoozed for " + String(AlarmRule.getRemainingSnoozeMinutes()) +  Constants.LocalizedString.min.localized
            print(snoozeText)
        }
    }
    
    public func presentSnoozePopup(forViewController viewController: UIViewController) {
        if AlarmRule.isSnoozed() {
            AlarmRule.disableSnooze()
            snoozeText = Constants.LocalizedString.snoozeLabel.localized
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
            self?.alarmManagerDelegates.forEach { $0.alarmManagerHasChangedAlarmingState(isActive: self?.active ?? false, urgent: self?.urgent ?? false, snoozed: AlarmRule.isSnoozed()) }
        }
        
        self.updateSnoozeButtonText()
    }
    
}
