//
//  HTTPClient.swift
//  Nightscouter
//
//  Created by Peter Ina on 2/13/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

open class HTTPClient {
    
    enum RequestMethod: String {
        case GET
        case POST
        case PUT
        case DELETE
    }
    
    internal struct URLPart {
        static let ApiVersion = "api/v1"
        static let Entries = "entries"
        static let Pebble = "pebble"
        static let CountParameter = "count"
        static let Status = "status"
        static let Cals = "cal"
        static let ExperimentTest = "experiments/test"
        
        static let FileExtension = "json"
    }
    
    internal struct HeaderPart {
        static let APISecretKey = "api-secret"
        static let ContentTypeKey = "Content-Type"
        static let ContentTypeValueApplicationJSON = "application/json"
    }
    
    fileprivate let url: URL
    fileprivate let baseURL: URL
    fileprivate let pebbleURL: URL
    fileprivate let entriesURL: URL
    fileprivate let statusURL: URL
    fileprivate let calsURL: URL
    
    internal let NightscoutAPIErrorDomain: String = "com.nightscout.nightscouter.api"
    
    public typealias JSON = Any
    public typealias JSONDictionary = Dictionary<String, JSON>
    public typealias JSONArray = Array<JSONDictionary>
    public typealias EntryArray = Array<Entry>
    
    
    // MARK: Lifecycle
    
    init(url: URL) {
        self.url = url
        self.pebbleURL = URL(string: URLPart.Pebble, relativeTo: url)!
        self.baseURL = url.appendingPathComponent(URLPart.ApiVersion)
        self.entriesURL = baseURL.appendingPathComponent(URLPart.Entries).appendingPathExtension(URLPart.FileExtension)
        self.statusURL = baseURL.appendingPathComponent(URLPart.Status).appendingPathExtension(URLPart.FileExtension)
        self.calsURL = baseURL.appendingPathComponent(URLPart.Entries).appendingPathComponent(URLPart.Cals).appendingPathExtension(URLPart.FileExtension)
    }
    
    
    
    
    lazy var config: URLSessionConfiguration = URLSessionConfiguration.default
    lazy var session: URLSession = {
        return URLSession(configuration: self.config)
    }()
    
    
    func fetchSiteData() {
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.GET.rawValue
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        
        
        
        let downloadTask = session.dataTask(with: request, completionHandler: {
            (
            data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print(dataString)
            
        })
        
        downloadTask.resume()
    }
}
