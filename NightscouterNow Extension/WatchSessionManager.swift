//
//  WatchSessionManager.swift
//  WCApplicationContextDemo
//
//  Created by Natasha Murashev on 9/22/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity

@available(watchOS 2.0, *)
public protocol DataSourceChangedDelegate {
    func dataSourceDidUpdate(dataSource: [Site])
}

@available(watchOS 2.0, *)
public class WatchSessionManager: NSObject, WCSessionDelegate {
    
    public static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private var dataSourceChangedDelegates = [DataSourceChangedDelegate]()
    
    private let session: WCSession = WCSession.defaultSession()
    
    private var sites: [Site] = []
    
    public func startSession() {
        session.delegate = self
        session.activateSession()
    }
    
    public func addDataSourceChangedDelegate<T where T: DataSourceChangedDelegate, T: Equatable>(delegate: T) {
        dataSourceChangedDelegates.append(delegate)
    }
    
    public func removeDataSourceChangedDelegate<T where T: DataSourceChangedDelegate, T: Equatable>(delegate: T) {
        for (index, indexDelegate) in dataSourceChangedDelegates.enumerate() {
            if let indexDelegate = indexDelegate as? T where indexDelegate == delegate {
                dataSourceChangedDelegates.removeAtIndex(index)
                break
            }
        }
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        print("didReceiveFile: \(file)")
        dispatch_async(dispatch_get_main_queue()) {
            // make sure to put on the main queue to update UI!
        }
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("didReceiveUserInfo: \(userInfo)")
    }
    
    // Receiver
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("didReceiveApplicationContext: \(applicationContext)")
        updateDataSource(applicationContext)
    }
    
    public func wakeUp() {
        let applicationData = ["type": "update"]
        session.sendMessage(applicationData, replyHandler: {(context:[String : AnyObject]) -> Void in
            // handle reply from iPhone app here
            
            print("recievedMessageReply: \(context)")
            self.updateDataSource(context)
            
            }, errorHandler: {(error ) -> Void in
                // catch any errors here
                print("error: \(error)")
        })
    }
    
    func updateDataSource(context: [String : AnyObject]) {
        
        sites.removeAll()

        if let siteArray = context["siteDictionary"] as? [[String : AnyObject]] {
            for item in siteArray {
                if let urlString = item["urlString"] as? String {
                    let site = Site(url: NSURL(string: urlString)!, apiSecret: nil)!
                    self.sites.append(site)
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.dataSourceChangedDelegates.forEach { $0.dataSourceDidUpdate(self!.sites) }
            }
        }
    }
}
