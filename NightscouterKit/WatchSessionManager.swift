//
//  WatchSessionManager.swift
//  WatchConnectivityDemo
//
//  Created by Natasha Murashev on 9/3/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity

@available(iOSApplicationExtension 9.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    public static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session where session.paired && session.watchAppInstalled {
            return session
        }
        return nil
    }
    
    public func startSession() {
        session?.delegate = self
        session?.activateSession()
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
@available(iOSApplicationExtension 9.0, *)
public extension WatchSessionManager {
    
    // Sender
    public func updateApplicationContext(applicationContext: [String : AnyObject]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        // handle receiving application context
        
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
}

// MARK: User Info
// use when@available(iOSApplicationExtension 9.0, *)
@available(iOSApplicationExtension 9.0, *)
// FIFO queue
extension WatchSessionManager {
    
    // Sender
    public func transferUserInfo(userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        print("transferUserInfo: \(userInfo)")
        return validSession?.transferUserInfo(userInfo)
    }
    
    public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        // handle receiving user info
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
    
}

// MARK: Transfer File
@available(iOSApplicationExtension 9.0, *)
extension WatchSessionManager {
    
    // Sender
    public func transferFile(file: NSURL, metadata: [String : AnyObject]) -> WCSessionFileTransfer? {
        return validSession?.transferFile(file, metadata: metadata)
    }
    
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        // handle filed transfer completion
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // handle receiving file
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
}


// MARK: Interactive Messaging
@available(iOSApplicationExtension 9.0, *)
extension WatchSessionManager {
    
    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        if let session = validSession where session.reachable {
            return session
        }
        return nil
    }
    
    // Sender
    public func sendMessage(message: [String : AnyObject],
        replyHandler: (([String : AnyObject]) -> Void)? = nil,
        errorHandler: ((NSError) -> Void)? = nil)
    {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    public func sendMessageData(data: NSData,
        replyHandler: ((NSData) -> Void)? = nil,
        errorHandler: ((NSError) -> Void)? = nil)
    {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        // handle receiving message
        
        if let updateTask = message["type"] as? String where updateTask == "update" {
            var dictionaryArray: [[String: AnyObject]] = []
            for site in AppDataManager.sharedInstance.sites {
                dictionaryArray.append(site.dictionary)
            }
            let context = ["siteDictionary": dictionaryArray]
            
            replyHandler(context)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
    
    
    public func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        // handle receiving message data
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
}