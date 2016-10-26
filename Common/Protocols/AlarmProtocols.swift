//
//  AlarmProtocols.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/27/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
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


#if os(iOS)
    import UIKit
    
    public protocol AlarmStuff {
        var alarmObject: AlarmObject? { get }
        func presentSnoozePopup(forViewController viewController: UIViewController)
        func snooze(forMiutes minutes : Int)
    }
    
    public extension AlarmStuff {
        var audioManager: AlarmAudioPlayer { return AlarmAudioPlayer.shared }
        
        var alarmObject: AlarmObject? {
            
            var al: AlarmObject? = nil
            al = AlarmManager.sharedManager.alarmObject
            
            if !SitesDataSource.sharedInstance.appIsInBackground {
                audioManager.alarmObject = al
            }
            return al
        }
        
        public func presentSnoozePopup(forViewController viewController: UIViewController) {
            
            if AlarmRule.isSnoozed {
                AlarmRule.disableSnooze()
                audioManager.play()
            } else {
                AlarmAudioPlayer.shared.muteVolume()
                
                let alertController = UIAlertController(title: LocalizedString.snoozeLabel.localized, message: LocalizedString.snoozeMessage.localized, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "30 \(LocalizedString.minutes.localized)",
                    style: .default,
                    handler: {(alert: UIAlertAction!) in
                        
                        self.snooze(forMiutes: 30)
                }))
                alertController.addAction(UIAlertAction(title: "1 \(LocalizedString.hour.localized)",
                    style: .default,
                    handler: {(alert: UIAlertAction!) in
                        
                        self.snooze(forMiutes: 60)
                }))
                alertController.addAction(UIAlertAction(title: "1 1/2 \(LocalizedString.hours.localized)",
                    style: .default,
                    handler: {(alert: UIAlertAction!) in
                        
                        self.snooze(forMiutes: 90)
                }))
                alertController.addAction(UIAlertAction(title: "2 \(LocalizedString.hours.localized)",
                    style: .default,
                    handler: {(alert: UIAlertAction!) in
                        
                        self.snooze(forMiutes: 120)
                }))
                alertController.addAction(UIAlertAction(title: LocalizedString.generalCancelLabel.localized,
                                                        style: .default,
                                                        handler: {(alert: UIAlertAction!) in
                                                            self.audioManager.unmuteVolume()
                }))
                
                viewController.present(alertController, animated: true, completion: nil)
                alertController.view.tintColor = NSAssetKit.darkNavColor
            }
        }
        
        public func snooze(forMiutes minutes : Int) {
            AlarmRule.snooze(minutes)
            audioManager.stop()
            audioManager.unmuteVolume()
            
            AlarmManager.sharedManager.requestCompanionAppUpdate()
        }
    }
#endif
