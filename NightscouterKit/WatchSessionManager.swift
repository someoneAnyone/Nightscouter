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
        
// startSession()
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
        #if DEBUG
            print("WCSession.isSupported: \(WCSession.isSupported()), Paired Watch: \(session?.paired), Watch App Installed: \(session?.watchAppInstalled)")
        #endif
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
// use when your app needs all the data
// FIFO queue
@available(iOSApplicationExtension 9.0, *)
extension WatchSessionManager {
    
    // Sender
    public func transferUserInfo(userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        #if DEBUG
            print("transferUserInfo: \(userInfo)")
        #endif
        return validSession?.transferUserInfo(userInfo)
    }
    
    public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
        #if DEBUG
            print("session \(session), didFinishUserInfoTransfer: \(userInfoTransfer), error: \(error)")
        #endif
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        #if DEBUG
            print("session \(session), didReceiveUserInfo: \(userInfo)")
        #endif
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
        #if DEBUG
            print("session \(session), didFinishFileTransfer: \(fileTransfer), error: \(error)")
        #endif
        // handle filed transfer completion
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        #if DEBUG
            print("session \(session), didReceiveFile: \(file)")
        #endif
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
    public var validReachableSession: WCSession? {
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
        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("session: \(session), didReceiveMessage: \(message)")
        #endif
        
        guard let action = WatchAction(rawValue: (message[WatchPayloadPropertyKeys.actionKey] as? String)!) else {
            print("No action was found, didReceiveMessage: \(message)")
            return
        }
       
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
            switch action {
            case .AppContext:
                print("appContext")
                AppDataManager.sharedInstance.updateWatch(withAction: .AppContext, withSite: AppDataManager.sharedInstance.sites)
            default:
                print("default")
                break
            }
        }
        
    }
    
    public func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {

        #if DEBUG
            print(">>> Entering \(__FUNCTION__) <<<")
            print("session: \(session), messageData: \(messageData)")
        #endif
        
        // handle receiving message data
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
}