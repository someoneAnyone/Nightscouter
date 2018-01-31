//
//  WatchConnectivityCordinator.swift
//  Nightscouter
//
//  Created by Peter Ina on 11/25/17.
//  Copyright © 2017 Peter Ina. All rights reserved.
//

import UIKit
import WatchConnectivity

#if os(watchOS)
    import ClockKit
#endif

// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.
//
enum Channel: String, Codable {
    case updateAppContext = "UpdateAppContext"
    case sendMessage = "SendMessage"
    case sendMessageData = "SendMessageData"
    case transferUserInfo = "TransferUserInfo"
    case transferFile = "TransferFile"
    case transferCurrentComplicationUserInfo = "TransferCurrentComplicationUserInfo"
}

class WatchConnectivityCordinator: NSObject, SessionManagerType {
    
    static let shared = WatchConnectivityCordinator()
    
    var store: SiteStoreType?
    
    // private: prevent clients from creating another instance.
    //
    private override init() {
        super.init()
    }
    
    func startSession() {
        print(">>> Entering \(#function) <<<")

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported()), Paired Phone Reachable: \(WCSession.default.isReachable)")
            #endif
        }
    }
     public func updateApplicationContext(_ applicationContext: [String : Any]) throws {
            guard WCSession.default.activationState == .activated else {
                return
            }
            
            print(applicationContext)
        }
    

    func processApplicationContext(context: [String : Any]) -> Bool {
        print(">>> Entering \(#function) <<<")
        
        print("Did receive payload")
        
        guard let store = store else {
            print("No Store")
            return false
        }
        
        store.handleApplicationContextPayload(context)
        
        return true
    }

}

extension WatchConnectivityCordinator {
    public func requestCompanionAppUpdate() {
        print(">>> Entering \(#function) <<<")
    }
}

extension WatchConnectivityCordinator: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(">>> Entering \(#function) <<<")

        
        let userInfo: [DefaultKey : Any] = [DefaultKey.watchRequestedUpdate: activationState]
        
        print(userInfo)
        
        if activationState == .activated {
            requestCompanionAppUpdate()
        }
    }
    
    // WCSessionDelegate methods for iOS only.
    //
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print(">>> Entering \(#function) <<<")

        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
}

