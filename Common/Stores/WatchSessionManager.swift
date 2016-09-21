//
//  WatchSessionManager.swift
//  WCApplicationContextDemo
//
//  Created by Natasha Murashev on 9/22/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity

public class WatchSessionManager: NSObject, WCSessionDelegate, SessionManagerType {
    
    public static let sharedManager = WatchSessionManager()
    
    public var store: SiteStoreType?
    
    private override init() {
        super.init()
    }
    
    deinit {
        stopSearching()
    }
    
    private let session: WCSession = WCSession.defaultSession()
    
    public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activateSession()
            
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported()), Paired Phone Reachable: \(session.reachable)")
            #endif
            
            startSearching()
        }
    }
    
    private func startSearching() {
        if !WCSession.defaultSession().receivedApplicationContext.isEmpty {
            processApplicationContext(WCSession.defaultSession().receivedApplicationContext)
        }
        
        requestCompanionAppUpdate()
    }
    
    public func stopSearching() {
        session.delegate = nil
    }
}

extension WatchSessionManager {
    // Sender
    public func updateApplicationContext(applicationContext: [String : AnyObject]) throws {
        #if DEBUG
            print(">>> Entering \(#function)<<")
        #endif
        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            throw error
        }
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // print("didReceiveFile: \(file)")
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("didReceiveUserInfo")
        // print(": \(userInfo)")
        
        dispatch_async(dispatch_get_main_queue()) {
            self.processApplicationContext(userInfo)
        }
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        // print("didReceiveApplicationContext: \(applicationContext)")
        dispatch_async(dispatch_get_main_queue()) {
            self.processApplicationContext(applicationContext)
        }
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        let success =  processApplicationContext(message)
        replyHandler(["response" : "The message was procssed correctly: \(success)", "success": success])
    }
    
}

extension WatchSessionManager {
    
    func processApplicationContext(context: [String : AnyObject]) -> Bool {
        print(">>> Entering \(#function) <<<")
        //print("processApplicationContext \(context)")
        
        //print("Did receive payload: \(context)")
        
        guard let store = store else {
            print("No Store")
            return false
        }
        
        store.handleApplicationContextPayload(context)
        
        return true
    }
}

extension WatchSessionManager { 
    public func requestCompanionAppUpdate() {
        print(">>> Entering \(#function) <<<")
        
        let messageToSend = DefaultKey.payloadPhoneUpdate
        
        self.session.sendMessage(messageToSend, replyHandler: {(context:[String : AnyObject]) -> Void in
            // handle reply from iPhone app here
            print("recievedMessageReply from iPhone")
            dispatch_async(dispatch_get_main_queue()) {
                print("WatchSession success...")
                let success = self.processApplicationContext(context)
                print(success)
            }
            }, errorHandler: {(error: NSError ) -> Void in
                print("WatchSession Transfer Error: \(error)")
                self.processApplicationContext(DefaultKey.payloadPhoneUpdateError)
        })
    }
    
}
