//
//  NightscoutAPIClient.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/26/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import Foundation
import SystemConfiguration 
/*:
Create protocol for setting base URL, API Token, etc...
TODO:// Create methods for getting settings.
*/

typealias JSONDictionary = Dictionary<String, AnyObject> //([String: AnyObject]?) -> ()
typealias JSONArray = Array<JSONDictionary>
typealias EntryArray = Array<Entry>

struct URLPart {
    static let ApiVersion = "api/v1"
    static let Entries = "entries"
    static let Pebble = "pebble"
    static let CountParameter = "count"
    static let Status = "status"
    static let FileExtension = "json"
}

enum NightscoutAPIError {
    case DownloadErorr(String)
    case JSONParseError(String)
}

class NightscoutAPIClient {
    
    let sharedSession = NSURLSession.sharedSession()
    var url: NSURL!
    
    class var sharedClient: NightscoutAPIClient {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: NightscoutAPIClient? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = NightscoutAPIClient()
        }
        return Static.instance!
    }
    
    
    /*! Initializes the calss with a Nightscout site URL.
    * \param url This class only needs the base URL to the site. For example, https://nightscout.hostingcompany.com, the class will discover the API. Currently uses veriion 1.
    *
    */
    init(url: NSURL){
        self.url = url
    }
    convenience init() {
        self.init(url: NSURL())
    }
}

// MARK: - Meat and Potatoes of the API
extension NightscoutAPIClient {
    
    func fetchDataForEntries(count: Int = 1, completetion:(entries: EntryArray, errorCode: NightscoutAPIError) -> Void) {
        let entriesWithCountURL = NSURL(string:self.stringForEntriesWithCount(count))
        self.fetchJSONWithURL(entriesWithCountURL!, completetion: { (result, errorCode) -> Void in
            if let entries = result as? JSONArray {
                var finalArray = Array<Entry>()
                for jsonDictionary: JSONDictionary in entries {
                    let entry: Entry = Entry(jsonDictionary: jsonDictionary)
                    finalArray.append(entry)
                }
                completetion(entries: finalArray, errorCode: errorCode)
            }
        })
    }
    
    func fetchDataForWatchEntry(completetion:(watchEntry: WatchEntry, errorCode: NightscoutAPIError) -> Void) {
        let watchEntryUrl = self.urlForWatchEntry
        self.fetchJSONWithURL(watchEntryUrl, completetion: { (result, errorCode) -> Void in
            if let jsonDictionary = result as? JSONDictionary {
                let watchEntry: WatchEntry = WatchEntry(watchEntryDictionary: jsonDictionary)
                completetion(watchEntry: watchEntry, errorCode: errorCode)
            }
        })
    }
    
    func fetchServerConfigurationData(completetion:(configuration: ServerConfiguration, errorCode: NightscoutAPIError) -> Void) {
        let settingsUrl = self.urlForStatus
        self.fetchJSONWithURL(settingsUrl, completetion: { (result, errorCode) -> Void in
            if let settingsDictionary = result as? JSONDictionary {
                let settingObject: ServerConfiguration = ServerConfiguration(jsonDictionary: settingsDictionary)
                completetion(configuration: settingObject, errorCode: errorCode)
            }
        })
    }
}

// MARK: - Convenience Methods
extension NightscoutAPIClient {
    var baseURL: String {
        return url.absoluteString!.stringByAppendingPathComponent(URLPart.ApiVersion)
    }
    
    var entriesString: String {
        return baseURL.stringByAppendingPathComponent(URLPart.Entries).stringByAppendingPathExtension(URLPart.FileExtension)!
    }
    
    var urlForWatchEntry: NSURL {
        return NSURL(string: URLPart.Pebble, relativeToURL: url)!
    }
    
    var urlForStatus: NSURL {
        let temp = baseURL.stringByAppendingPathComponent(URLPart.Status).stringByAppendingPathExtension(URLPart.FileExtension)
        return NSURL(string: temp!)!
    }
    
    func  stringForEntriesWithCount(count: Int) -> String {
        let numberOfEntries = "?\(URLPart.CountParameter)=\(count)"
        return entriesString.stringByAppendingString(numberOfEntries)
    }
    
}

// MARK: - Private Methods
private extension NightscoutAPIClient {
    func fetchJSONWithURL(url: NSURL, completetion:(result: AnyObject, errorCode: NightscoutAPIError) -> Void) {
        // Logging and debugging.

        print("Fetching: \(url.absoluteString)")
        // Start timer for how long this took.
        let fetchStart = NSDate()
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(url, completionHandler: { (location: NSURL!, response: NSURLResponse!, downloadError: NSError!) -> Void in
            
            var nsAPIError: NightscoutAPIError = NightscoutAPIError.DownloadErorr("None")
            
            if (downloadError != nil) {
                print("failed to download")
                nsAPIError = NightscoutAPIError.DownloadErorr("There was a problem downloading data. Error code: \(downloadError)")
            } else {
                if let dataObject: NSData = NSData(contentsOfURL: location) {
                    var stringVersion = NSString(data: dataObject, encoding: NSUTF8StringEncoding)
                    stringVersion = stringVersion?.stringByReplacingOccurrencesOfString("+", withString: "")
                    
                    var jsonError: NSError?
                    if let responseObject: AnyObject = NSJSONSerialization.JSONObjectWithData(dataObject, options: .AllowFragments, error:&jsonError){
                        if (jsonError != nil) {
                            println("jsonError")
                            nsAPIError = NightscoutAPIError.DownloadErorr("There was a problem processing the JSON data. Error code: \(jsonError)")
                        } else {
                            completetion(result: responseObject, errorCode: nsAPIError)
                        }
                    }
                }
            }            
            // Logging and debugging.
            let fetchEnd = NSDate()
            let fetchTimeElapsed = fetchEnd .timeIntervalSinceDate(fetchStart)
            println("Finished request for \(url) in \(fetchTimeElapsed) seconds.")
        })
    
        
        downloadTask.resume()
        
    }
}