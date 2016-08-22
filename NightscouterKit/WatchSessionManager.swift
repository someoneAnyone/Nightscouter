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
    
    public var validSession: WCSession? {
        
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
    
    public func sessionReachabilityDidChange(session: WCSession) {
        print("sessionReachabilityDidChange")
        //  print(session)
        //let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
        //        AppDataManageriOS.sharedInstance.processApplicationContext(messageToSend) { (dictionary) in
        //
        //        }
    }
    
    public func sessionWatchStateDidChange(session: WCSession) {
        print("sessionWatchStateDidChange")
        print(session)
    }
    
    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
 
        print(">>> Entering \(#function) <<<")
    }
    
    public func sessionDidBecomeInactive(session: WCSession) {
        print(">>> Entering \(#function) <<<")
    }
    public func sessionDidDeactivate(session: WCSession) {
        print(">>> Entering \(#function) <<<")
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
                cleanUpTransfers()
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
            AppDataManageriOS.sharedInstance.processApplicationContext(applicationContext)
        }
    }
}

// MARK: User Info
// use when your app needs all the data
// FIFO queue
@available(iOSApplicationExtension 9.0, *)
extension WatchSessionManager {
    
    public func transferCurrentComplicationUserInfo(userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        #if DEBUG
            print("transferCurrentComplicationUserInfo")
            print("validSession?.complicationEnabled == \(validSession?.complicationEnabled)")
        #endif
        
        cleanUpTransfers()
        
        return validSession?.complicationEnabled == true ? validSession?.transferCurrentComplicationUserInfo(userInfo) : transferUserInfo(userInfo)
    }
    
    func cleanUpTransfers(){
        validSession?.outstandingUserInfoTransfers.forEach({ $0.cancel() })
    }
    
    // Sender
    public func transferUserInfo(userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        #if DEBUG
            print("transferUserInfo")
            //print("transferUserInfo: \(userInfo)")
        #endif
        cleanUpTransfers()

        return validSession?.transferUserInfo(userInfo)
    }
    
    public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
        #if DEBUG
            print("session \(session), didFinishUserInfoTransfer: \(userInfoTransfer), error: \(error)")
            print("on" + NSDate.description())
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
            AppDataManageriOS.sharedInstance.processApplicationContext(userInfo)
        }
    }
    
}

// MARK: Interactive Messaging
@available(iOSApplicationExtension 9.0, *)
public extension WatchSessionManager {
    
    // Live messaging! App has to be reachable
    public var validReachableSession: WCSession? {
        if let session = validSession where session.reachable {
            return session
        }
        return nil
    }
    
    // Sender
    public func sendMessage(message: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)? = nil, errorHandler: ((NSError) -> Void)? = nil)
    {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        // handle receiving message
        #if DEBUG
            print(">>> Entering \(#function)<<")
        #endif
        
        // replyHandler([WatchModel.PropertyKey.successfullyRecieved: true])
        
        dispatch_async(dispatch_get_main_queue()) {
            AppDataManageriOS.sharedInstance.processApplicationContext(message, replyHandler: replyHandler)
        }
    }
}
