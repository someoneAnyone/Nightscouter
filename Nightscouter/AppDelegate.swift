//
//  AppDelegate.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SitesDataSourceProvider, BundleRepresentable, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    var sites: [Site] {
        return SitesDataSource.sharedInstance.sites
    }
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: String?
    
    // MARK: AppDelegate Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            print(">>> Entering \(#function)<<")
        #endif
        // Override point for customization after application launch.
        
        Theme.customizeAppAppearance(sharedApplication: UIApplication.shared, forWindow: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.dataManagerDidChange(_:)), name: .nightscoutDataUpdatedNotification, object: nil)
        
        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem.type
        }
        
        return true
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        SitesDataSource.sharedInstance.appIsInBackground = false
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        SitesDataSource.sharedInstance.appIsInBackground = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Background Fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        SitesDataSource.sharedInstance.appIsInBackground = true
        
        sites.forEach { (site) in
            site.fetchDataFromNetwork(completion: { (updatedSite, error) in
                SitesDataSource.sharedInstance.updateSite(updatedSite)
            })
        }
        
        completionHandler(.newData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print("Recieved URL: \(url) with options: \(options)")
        #endif
        // If the incoming scheme is not contained within the array of supported schemes return false.
        guard let schemes = LinkBuilder.supportedSchemes, schemes.contains(url.scheme ?? "") else { return false }
        
        // We now have an acceptable scheme. Pass the URL to the deep linking handler.
        deepLinkToURL(url)
        
        return true
    }
    
    // MARK: Local Notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(">>> Entering \(#function) <<<")
        //print("Received a local notification payload: \(notification) with application: \(application)")
        
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print(shortcutItem)
        
        guard let useCase: CommonUseCasesForShortcuts = CommonUseCasesForShortcuts(shortcutItemString: shortcutItem.type) else {
            completionHandler(false)
            return
        }
        
        switch useCase {
        case .AddNew :
            deepLinkToURL(useCase.linkForUseCase())
        case .ShowDetail:
            if let siteIndex = shortcutItem.userInfo!["siteIndex"] as? Int {
                SitesDataSource.sharedInstance.lastViewedSiteIndex = siteIndex
            }
            #if DEDBUG
                println("User tapped on notification for site: \(site) at index \(siteIndex) with UUID: \(uuid)")
            #endif
            deepLinkToURL(useCase.linkForUseCase())
        default:
            completionHandler(false)
        }
        
        completionHandler(true)
    }
    
    
    // AppDataManagerNotificationDidChange Handler
    @objc func dataManagerDidChange(_ notification: Notification) {
        
        if sites.isEmpty { return }
    
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .denied:
                return
            case .authorized:
                return
            case .notDetermined:
                self.setupNotificationSettings()
            case .provisional:
                self.setupNotificationSettings()
            case .ephemeral:
                self.setupNotificationSettings()
            @unknown default:
                return
            }
        }
        
// Deprecated
//        if UIApplication.shared.currentUserNotificationSettings?.types == .none || !sites.isEmpty{
//            setupNotificationSettings()
//        }
        
        UIApplication.shared.shortcutItems = nil
        for (index, site) in SitesDataSource.sharedInstance.sites.enumerated() {
            
            let model = site.summaryViewModel
            
            let useCase = CommonUseCasesForShortcuts.ShowDetail.applicationShortcutItemType
            
            let shortcut = UIApplicationShortcutItem(type: useCase, localizedTitle: model.nameLabel, localizedSubtitle: model.urlLabel, icon: nil, userInfo: ["uuid": site.uuid.uuidString as NSSecureCoding, "siteIndex": index as NSSecureCoding])
            
            UIApplication.shared.shortcutItems?.append(shortcut)
        }
        // print("currentUserNotificationSettings: \(currentUserNotificationSettings)")
        
        if let alarmObject = AlarmManager.sharedManager.alarmObject {
            schedule(notificationFor: alarmObject)
        }
    }
    
    func schedule(notificationFor alarmObject: AlarmObject) {
        
        
        if #available(iOS 10.0, *) {
            
        } else {
            // Fallback on earlier versions
            
            
            let localNotification = UILocalNotification()
            localNotification.fireDate = Date()
            localNotification.soundName = alarmObject.audioFileURL.absoluteString//UILocalNotificationDefaultSoundName;
            localNotification.category = "Nightscout_Category"
            // localNotification.userInfo = [site.uuid.uuidString: "uuid"]
            
            localNotification.alertAction = "View Site"
            
            let model = alarmObject
            
            localNotification.alertBody = model.snoozeText
            
            // localNotification.alertBody = "Last reading: \(model.lastReadingDate), BG: \(model.sgvLabel) \(model.direction.emojiForDirection) Delta: \(model.deltaLabel) Battery: \(model.batteryLabel)%"
            
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
    }
    
    // MARK: Custom Methods
    
    func deepLinkToURL(_ url: URL) {
        // Maybe this can be expanded to handle icomming messages from remote or local notifications.
        let pathComponents = url.pathComponents
        
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            #if DEBUG
                print("queryItems: \(queryItems)") // Not handling queries at that moment, but might want to.
            #endif
        }
        
        guard let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window else {
            return
        }
        
        if let navController = window.rootViewController as? UINavigationController { // Get the root view controller's navigation controller.
            
            navController.popToRootViewController(animated: false) // Return to root viewcontroller without animation.
            navController.dismiss(animated: false, completion: { () -> Void in
                //
            })
            let storyboard = window
                .rootViewController?.storyboard // Grab the storyboard from the rootview.
            var viewControllers = navController.viewControllers // Grab all the current view controllers in the stack.
            
            for pathComponent in pathComponents { // iterate through all the path components. Currently the app only has one level of deep linking.
                
                // Attempt to create a storyboard identifier out of the string.
                guard let storyboardIdentifier = StoryboardIdentifier(rawValue: pathComponent) else {
                    continue
                }
                
                let linkIsAllowed = StoryboardIdentifier.deepLinkable.contains(storyboardIdentifier) // Check to see if this is an allowed viewcontroller.
                
                if linkIsAllowed {
                    let newViewController = storyboard!.instantiateViewController(withIdentifier: storyboardIdentifier.rawValue)
                    
                    switch (storyboardIdentifier) {
                    case .sitesTableViewController:
                        
                        if let UUIDString = pathComponents[safe: 2], let uuid = UUID(uuidString: UUIDString), let site = (SitesDataSource.sharedInstance.sites.filter { $0.uuid == uuid }.first), let index = SitesDataSource.sharedInstance.sites.firstIndex(of: site) {
                            
                            SitesDataSource.sharedInstance.lastViewedSiteIndex = index
                        }
                        
                        viewControllers.append(newViewController) // Create the view controller and append it to the navigation view controller stack
                    case .formViewNavigationController, .formViewController:
                        navController.present(newViewController, animated: false, completion: { () -> Void in
                            // ...
                        })
                    default:
                        viewControllers.append(newViewController) // Create the view controller and append it to the navigation view controller stack
                    }
                }
            }
            navController.viewControllers = viewControllers // Apply the updated list of view controller to the current navigation controller.
        }
        
        
    }
    
    func setupNotificationSettings() {
        print(">>> Entering \(#function) <<<")
        
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                if let error = error {
                    print("error:\(error)")
                } else if !granted {
                    print("not granted")
                } else {
                    DispatchQueue.main.async(execute: {
                    })
                }
                
            }
        } else {
            // Fallback on earlier versions
            let notificationTypes: UIUserNotificationType = [.alert, .sound, .badge]
            // Specify the notification types.
            
            
            // Register the notification settings.
            let newNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(newNotificationSettings)
            
            // TODO: Enabled remote notifications... need to get a server running.
            
        }
        
        // UIApplication.sharedApplication().registerForRemoteNotifications()
       
        DispatchQueue.main.async {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        //UIApplication.shared.cancelAllLocalNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
}
