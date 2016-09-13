//
//  AppDelegate.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/25/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit
import AVFoundation
import NightscouterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, BundleRepresentable {
    
    var window: UIWindow?
    
    var sites: [Site] {
        return AppDataManageriOS.sharedInstance.sites
    }
    
    var timer: Timer?
    
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: String?
    
    // MARK: AppDelegate Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            print(">>> Entering \(#function)<<")
        #endif
        // Override point for customization after application launch.

        AppThemeManager.themeApp
        window?.tintColor = Theme.Color.windowTintColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.dataManagerDidChange(_:)), name: NSNotification.Name(rawValue: AppDataManagerDidChangeNotification), object: nil)

        WatchSessionManager.sharedManager.startSession()
        AlarmManager.sharedManager.startAlarmMonitor()

        
        // If a shortcut was launched, display its information and take the appropriate action
            if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
                
                launchedShortcutItem = shortcutItem.type
                
            }

        return true
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        self.timer?.invalidate()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        updateDataNotification(nil)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppDataManageriOS.sharedInstance.saveData()
        AlarmManager.sharedManager.endAlarmMonitor()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Background Fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
        #endif
        
        AppDataManageriOS.sharedInstance.generateData(forSites: self.sites) { (updatedSites) in
            
            for site in updatedSites {
                AppDataManageriOS.sharedInstance.updateSite(site)
            }
            
            print("returning completionHandler() for \(#function)")
            completionHandler(.newData)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print("Recieved URL: \(url) with options: \(options)")
        #endif
        let schemes = supportedSchemes!
        if (!schemes.contains((url.scheme)!)) { // If the incoming scheme is not contained within the array of supported schemes return false.
            return false
        }
        
        // We now have an acceptable scheme. Pass the URL to the deep linking handler.
        deepLinkToURL(url)
        
        return true
    }
    
    // MARK: Local Notifications
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print(">>> Entering \(#function) <<<")
        print("Received a local notification payload: \(notification) with application: \(application)")
        
        processLocalNotification(notification)
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print(shortcutItem)
        
        switch shortcutItem.type {
        case "com.nothingonline.Nightscouter.AddNew":
            let url = URL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteFormViewNavigationController.rawValue)")
            deepLinkToURL(url!)
        case "com.nothingonline.Nightscouter.ViewSite":
            let siteIndex = shortcutItem.userInfo!["siteIndex"] as! Int
            AppDataManageriOS.sharedInstance.currentSiteIndex = siteIndex
            
            #if DEDBUG
                println("User tapped on notification for site: \(site) at index \(siteIndex) with UUID: \(uuid)")
            #endif
            
            let url = URL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
            deepLinkToURL(url!)
        default:
            completionHandler(false)
            
        }
        
        completionHandler(true)
    }
    
    
    // AppDataManagerNotificationDidChange Handler
    func dataManagerDidChange(_ notification: Notification) {
        if UIApplication.shared.currentUserNotificationSettings?.types == .none || !sites.isEmpty{
            setupNotificationSettings()
        }
        
            UIApplication.shared.shortcutItems = nil
            for (index, site) in AppDataManageriOS.sharedInstance.sites.enumerated() {
                UIApplication.shared.shortcutItems?.append(UIApplicationShortcutItem(type: "com.nothingonline.Nightscouter.ViewSite", localizedTitle: site.viewModel.displayName, localizedSubtitle: site.viewModel.displayUrlString, icon: nil, userInfo: ["uuid": site.uuid.uuidString, "siteIndex": index]))
            }
        // print("currentUserNotificationSettings: \(currentUserNotificationSettings)")
    }

    
    // MARK: Custom Methods
    func processLocalNotification(_ notification: UILocalNotification) {
        if let userInfoDict : [AnyHashable: Any] = notification.userInfo {
            if let uuidString = userInfoDict[Site.PropertyKey.uuidKey] as? String {
                let uuid = UUID(uuidString: uuidString) // Get the uuid from the notification.
                
                _ = URL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)/\(uuidString)")
                if let site = (sites.filter{ $0.uuid == uuid }.first) { // Use the uuid value to get the site object from the array.
                    if let siteIndex = sites.index(of: site) { // Use the site object to get its index position in the array.
                        
                        AppDataManageriOS.sharedInstance.currentSiteIndex = siteIndex
                        
                        #if DEDBUG
                            println("User tapped on notification for site: \(site) at index \(siteIndex) with UUID: \(uuid)")
                        #endif
                        
                        let url = URL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteListPageViewController.rawValue)")
                        deepLinkToURL(url!)
                    }
                }
                //                }
            } else {
                let url = URL(string: "nightscouter://link/\(Constants.StoryboardViewControllerIdentifier.SiteFormViewController.rawValue)")
                deepLinkToURL(url!)
            }
        }
    }
    
    func deepLinkToURL(_ url: URL) {
        // Maybe this can be expanded to handle icomming messages from remote or local notifications.
         let pathComponents = url.pathComponents
            
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                #if DEBUG
                    print("queryItems: \(queryItems)") // Not handling queries at that moment, but might want to.
                #endif
            }
            
            if let navController = self.window?.rootViewController as? UINavigationController { // Get the root view controller's navigation controller.
                navController.popToRootViewController(animated: false) // Return to root viewcontroller without animation.
                let storyboard = self.window?.rootViewController?.storyboard // Grab the storyboard from the rootview.
                var viewControllers = navController.viewControllers // Grab all the current view controllers in the stack.
                for stringID in pathComponents { // iterate through all the path components. Currently the app only has one level of deep linking.
                    if let stor = Constants.StoryboardViewControllerIdentifier(rawValue: stringID) { // Attempt to create a storyboard identifier out of the string.
                        let linkIsAllowed = Constants.StoryboardViewControllerIdentifier.deepLinkableStoryboards.contains(stor) // Check to see if this is an allowed viewcontroller.
                        if linkIsAllowed {
                            let newViewController = storyboard!.instantiateViewController(withIdentifier: stringID)
                            
                            switch (stor) {
                            case .SiteListPageViewController:
                                viewControllers.append(newViewController) // Create the view controller and append it to the navigation view controller stack
                            case .SiteFormViewNavigationController, .SiteFormViewController:
                                navController.present(newViewController, animated: false, completion: { () -> Void in
                                    // ...
                                })
                            default:
                                viewControllers.append(newViewController) // Create the view controller and append it to the navigation view controller stack
                            }
                        }
                    }
                }
                navController.viewControllers = viewControllers // Apply the updated list of view controller to the current navigation controller.
            }
        
    }
    
    func createUpdateTimer() -> Timer {
        let localTimer = Timer.scheduledTimer(timeInterval: Constants.NotableTime.StandardRefreshTime, target: self, selector: #selector(AppDelegate.updateDataNotification(_:)), userInfo: nil, repeats: true)
        
        return localTimer
    }
    
    func updateDataNotification(_ timer: Timer?) -> Void {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print("Posting \(NightscoutAPIClientNotification.DataIsStaleUpdateNow) Notification at \(NSDate())")
        #endif
        
        OperationQueue.main.addOperation { () -> Void in
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NightscoutAPIClientNotification.DataIsStaleUpdateNow), object: self))
            //AppDataManageriOS.sharedInstance.updateWatch(withAction: .UserInfo
        }
        if (self.timer == nil) {
            self.timer = createUpdateTimer()
        }
    }
    
    func scheduleLocalNotification(_ site: Site) {
        #if DEBUG
            print(">>> Entering \(#function) <<<")
            print("Scheduling a notification for site: \(site.url) and is allowed: \(site.allowNotifications)")
        #endif
        
        if (site.allowNotifications == false) { return }
        
        let dateFor = DateFormatter()
        dateFor.timeStyle = .short
        dateFor.dateStyle = .short
        dateFor.doesRelativeDateFormatting = true
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = Date().addingTimeInterval(TimeInterval(arc4random_uniform(UInt32(sites.count))))
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.category = "Nightscout_Category"
        localNotification.userInfo = NSDictionary(object: site.uuid.uuidString, forKey: Site.PropertyKey.uuidKey as NSCopying) as! [AnyHashable: Any]
        localNotification.alertAction = "View Site"
        
        if let config = site.configuration {
            localNotification.alertTitle = "Update for \(config.displayName)"
            
            let units = config.displayUnits
            if let watch: WatchEntry = site.watchEntry {
                localNotification.alertBody = "Last reading: \(dateFor.string(from: watch.date)), BG: \(watch.sgv!.sgvString(forUnits: units)) \(watch.sgv!.direction.emojiForDirection) Delta: \(watch.bgdelta.formattedBGDelta(forUnits: units)) Battery: \(watch.batteryString)%"
            }
        }
        
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    func setupNotificationSettings() {
        print(">>> Entering \(#function) <<<")
        // Specify the notification types.
        let notificationTypes: UIUserNotificationType = [.alert, .sound, .badge]
        
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        UIApplication.shared.registerUserNotificationSettings(newNotificationSettings)
        
        // TODO: Enabled remote notifications... need to get a server running.
        // UIApplication.sharedApplication().registerForRemoteNotifications()
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    var supportedSchemes: [String]? {
        if let info = infoDictionary {
            var schemes = [String]() // Create an empty array we can later set append available schemes.
            if let bundleURLTypes = info["CFBundleURLTypes"] as? [AnyObject] {
                for (index, _) in bundleURLTypes.enumerated() {
                    if let urlTypeDictionary = bundleURLTypes[index] as? [String : AnyObject] {
                        if let urlScheme = urlTypeDictionary["CFBundleURLSchemes"] as? [String] {
                            schemes += urlScheme // We've found the supported schemes appending to the array.
                            return schemes
                        }
                    }
                }
            }
        }
        
        return nil
    }
}
