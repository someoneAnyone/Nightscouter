//
//  WatchSessionManager.swift
//  WatchConnectivityDemo
//
//  Created by Natasha Murashev on 9/3/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity

@available(iOSApplicationExtension 9.0, *)
open class WatchSessionManager: NSObject, WCSessionDelegate {
    
    open static let sharedManager = WatchSessionManager()
    fileprivate override init() {
        super.init()
    }
    
    fileprivate let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    open var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session , session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    open func startSession() {
        session?.delegate = self
        session?.activate()
        
        #if DEBUG
            print("WCSession.isSupported: \(WCSession.isSupported()), Paired Watch: \(session?.isPaired), Watch App Installed: \(session?.isWatchAppInstalled)")
        #endif
    }
    
    open func sessionReachabilityDidChange(_ session: WCSession) {
        print("sessionReachabilityDidChange")
        //  print(session)
        //let messageToSend = [WatchModel.PropertyKey.actionKey: WatchAction.AppContext.rawValue]
        //        AppDataManageriOS.sharedInstance.processApplicationContext(messageToSend) { (dictionary) in
        //
        //        }
    }
    
    open func sessionWatchStateDidChange(_ session: WCSession) {
        print("sessionWatchStateDidChange")
        print(session)
    }
    
    open func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
 
        print(">>> Entering \(#function) <<<")
    }
    
    open func sessionDidBecomeInactive(_ session: WCSession) {
        print(">>> Entering \(#function) <<<")
    }
    open func sessionDidDeactivate(_ session: WCSession) {
        print(">>> Entering \(#function) <<<")
    }

}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
@available(iOSApplicationExtension 9.0, *)
public extension WatchSessionManager {
    
    // Sender
    public func updateApplicationContext(_ applicationContext: [String : AnyObject]) throws {
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
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // handle receiving application context
        
        DispatchQueue.main.async {
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
    
    public func transferCurrentComplicationUserInfo(_ userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        #if DEBUG
            print("transferCurrentComplicationUserInfo")
            print("validSession?.complicationEnabled == \(validSession?.isComplicationEnabled)")
        #endif
        
        cleanUpTransfers()
        
        return validSession?.isComplicationEnabled == true ? validSession?.transferCurrentComplicationUserInfo(userInfo) : transferUserInfo(userInfo)
    }
    
    func cleanUpTransfers(){
        validSession?.outstandingUserInfoTransfers.forEach({ $0.cancel() })
    }
    
    // Sender
    public func transferUserInfo(_ userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        #if DEBUG
            print("transferUserInfo")
            //print("transferUserInfo: \(userInfo)")
        #endif
        cleanUpTransfers()

        return validSession?.transferUserInfo(userInfo)
    }
    
    @objc(session:didFinishUserInfoTransfer:error:) public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
    //public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        #if DEBUG
            print("session \(session), didFinishUserInfoTransfer: \(userInfoTransfer), error: \(error)")
            print("on" + NSDate.description())
        #endif
        
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
    }
    
    // Receiver
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        #if DEBUG
            print("session \(session), didReceiveUserInfo: \(userInfo)")
        #endif
        // handle receiving user info
        DispatchQueue.main.async {
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
        if let session = validSession , session.isReachable {
            return session
        }
        return nil
    }
    
    // Sender
    public func sendMessage(_ message: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // Receiver
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // handle receiving message
        #if DEBUG
            print(">>> Entering \(#function)<<")
        #endif
        
        // replyHandler([WatchModel.PropertyKey.successfullyRecieved: true])
        
        DispatchQueue.main.async {
            AppDataManageriOS.sharedInstance.processApplicationContext(message, replyHandler: replyHandler)
        }
    }
}
