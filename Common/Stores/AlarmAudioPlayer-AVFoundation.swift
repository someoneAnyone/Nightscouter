//
//  AlarmAudioPlayer.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/27/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation
import AVFoundation
///
/*
 Not sure how to handle this behavior...
 
 We need the alarming system to track changes to the sites... get updated whenever the site data changes. But where is the best place to do this?
 
 Also once we havse an alarm... who and how is it managed...
 for example, who is responsible to snooze and update the user interface of its status?
 
 presentation of dialogs and stuff should be done in the app layer, but handlig of snooze and
 text should probably come from a one place.si
 
 */
open class AlarmAudioPlayer: AudioCordinator {
    public static let shared: AlarmAudioPlayer = AlarmAudioPlayer()
    
    public var alarmObject: AlarmObject? {
        didSet{
            guard let alarmObject = alarmObject else {
                audioPlayer?.stop()
                return
            }
            
            if oldValue != alarmObject {
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: alarmObject.audioFileURL)
                    
                    audioPlayer?.prepareToPlay()
                    // print("readyToPlayAlarm: \(readyToPlay), will play: \(alarmObject.audioFileURL)")
                    
                    if alarmObject.isSnoozed {
                        muteVolume()
                    } else if alarmObject.warning || alarmObject.urgent || alarmObject.isAlarmingForSgv {
                        play()
                    }
                    
                } catch {
                    return
                }
            }
        }
    }
    
    fileprivate var audioPlayer: AVAudioPlayer?
    
    public var isPlaying: Bool {
        get {
            if let audioPlayer = audioPlayer {
                return audioPlayer.isPlaying
            }
            
            return false
        }
    }
    
    public func play() {
        unmuteVolume()
        
        if !isPlaying && (alarmObject != nil) {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
                try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
                
                // Play endless loops
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.play()
                
            } catch {
                print("Audio Error: \(error)")
                print("Unable to play sound!")
            }
        }
    }
    
    public func pause() {
        audioPlayer?.pause()
    }
    
    public func stop() {
        audioPlayer?.stop()
    }
    
    public func unmuteVolume(){
        audioPlayer?.volume = 1.0
    }
    
    public func muteVolume() {
        audioPlayer?.volume = 0
    }
}
