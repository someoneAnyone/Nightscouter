//
//  GetConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 8/18/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

/// Need to do some conversion here... still need figure out how.
extension String {
    func sha1() -> String {
        // Temp extension
        return self
    }
}

fileprivate let API_DOMAIN = "com.Nightscout.RESTClient"

public struct NightscoutRESTClientError: Error {
    /// The domain of the error.
    public static var errorDomain: String = API_DOMAIN
    
    public let line: Int
    public let column: Int
    public let kind: ErrorKind
    
    public enum ErrorKind: CustomStringConvertible {
        case downloadedLocationIsMissing
        case couldNotCreateDataFromDownloadedFile
        case invalidJSON(Error?)
        case unknown(String)
        
        public var description: String {
            switch  self {
            case .downloadedLocationIsMissing:
                return "The file required for the app was not downloaded was not available."
            case .couldNotCreateDataFromDownloadedFile:
                return "The contents of the file were not able to be converted to data."
            case .invalidJSON:
                return "The file could not be parsed correctly."
            case .unknown:
                return "Don't know why this was thrown go investigate and fix it."
            }
        }
    }
}

internal protocol NightscouterOperation {
    var data: Data? { set get }
    var error: NightscoutRESTClientError? { set get }
    
    func parse(JSONData data: Data)
}

public class NightscouterBaseOperation: Operation, NightscouterOperation {
    
    internal var error: NightscoutRESTClientError?
    internal var data: Data?
    
    public override func main() {
        
        if self.isCancelled { return }
        
        guard let data = self.data, self.error == nil else {
            fatalError()
        }
        
        parse(JSONData: data)
    }
    
    internal func parse(JSONData data: Data) {
        
    }
}


public class Nightscout {
    
    
    // MARK: - Variables
    
    public let processingQueue: OperationQueue = OperationQueue()
    
    fileprivate lazy var session: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: self.processingQueue)
    }()
    
    enum APIRoutes: String {
        case status, entries, pebble, devicestatus
    }
    
    // MARK: - Private Methods
    
    fileprivate func generateConfigurationRequestHeader(withBaseURL url: URL, withApiSecretString APISecret: String? = nil, forAPIRoute APIRoute: APIRoutes = .status) -> URLRequest {
        var headers = [String: String]()
        
        // Set the headers.
        // 1. Content type.
        headers["Content-Type"] = "application/json"
        // 2. Provide the API key, passphrase or api-secret token. User of the api prvides a string and this will convert to a SHA1 string.
        headers["api-secret"] = APISecret?.sha1()
        
        var requstURL: URL
        
        let pathExtension = "json"
        
        let apiVersion = "api/v1"
        
        switch APIRoute {
        case .entries:
            let entryCout = 300
            let queryItemCount = URLQueryItem(name: "count", value: "\(entryCout)")
            
            var comps = URLComponents(url: url.appendingPathComponent("\(apiVersion)/\(APIRoute.rawValue)").appendingPathExtension(pathExtension) , resolvingAgainstBaseURL: true)
            comps!.queryItems = [queryItemCount]
            requstURL = comps!.url!
            
        case .pebble:
            requstURL = url.appendingPathComponent(APIRoute.rawValue).appendingPathExtension(pathExtension)
            
        case .devicestatus:
            requstURL = url.appendingPathComponent("\(apiVersion)/\(APIRoute.rawValue)").appendingPathExtension(pathExtension)
        default:
            requstURL = url.appendingPathComponent("\(apiVersion)/\(APIRoute.rawValue)").appendingPathExtension(pathExtension)
        }
        
        var request = URLRequest(url: requstURL)
        
        for (headerField, headerValue) in headers {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }
        
        return request
    }
    
    
    // MARK: - Public Methods
    
    public init() {
        processingQueue.name = API_DOMAIN
    }
    
    
    // Need to wrap this up into a new class and an Operation block, that can be canceled as well as monitored.
    public func networkRequest(forNightscoutURL url: URL, apiPassword password: String? = nil, userInitiated: Bool = false, completion:@escaping (_ configuration: ServerConfiguration?,_ sensorGlucoseValues: [SensorGlucoseValue]?, _ calibrations: [Calibration]?, _ meteredGlucoseValues:[MeteredGlucoseValue]?, _ deviceStatus: [DeviceStatus]?, _ error: NightscoutRESTClientError?) -> Void) {
        
        print(">>> Entering \(#function) for \(url) <<<")
        
        var configuration: ServerConfiguration?
        //var serverConfigError: NightscoutRESTClientError?
        
        var sgvs: [SensorGlucoseValue]?
        var mbgs: [MeteredGlucoseValue]?
        var cals: [Calibration]?
        //var entriesError: NightscoutRESTClientError?
        
        var device: [DeviceStatus]?
        //var deviceError: NightscoutRESTClientError?
    
        // Request JSON data for the Site's configuration.
        var configurationRequest = generateConfigurationRequestHeader(withBaseURL: url, withApiSecretString: nil, forAPIRoute: .status)
        configurationRequest.networkServiceType = userInitiated ? .default : .background
        
        let serverConfigTask = session.downloadTask(with: configurationRequest) { (location, response, error) in
            print(">>> serverConfigTask task is complete. <<<")
            //print(">>> downloadTask: {\nlocation: \(location),\nresponse: \(response),\nerror: \(error)\n} <<<")
            
            if let err = error {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
                
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            // Is there a file at the location provided?
            guard let location = location else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .downloadedLocationIsMissing)
                
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            guard let dataFromLocation = try? Data(contentsOf: location) else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            let parseConfig = ParseConfigurationOperation(withJSONData: dataFromLocation)
            parseConfig.completionBlock = {
                configuration = parseConfig.configuration
            }
            
            self.processingQueue.addOperation(parseConfig)
        }
        serverConfigTask.resume()
        
        
        var downloadReadingsRequest = generateConfigurationRequestHeader(withBaseURL: url, withApiSecretString: nil, forAPIRoute: .entries)
        downloadReadingsRequest.networkServiceType = userInitiated ? .default : .background
        let downloadReadingsTask = session.downloadTask(with: downloadReadingsRequest) { (location, response, error) in
            print(">>> downloadReadingsTask task is complete. <<<")
            //print(">>> downloadTask: {\nlocation: \(location),\nresponse: \(response),\nerror: \(error)\n} <<<")
            
            // Is there a file at the location provided?
            guard let location = location else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .downloadedLocationIsMissing)
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            guard let dataFromLocation = try? Data(contentsOf: location) else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            let parseReadingsData = ParseReadingsOperation(withJSONData: dataFromLocation)
            parseReadingsData.completionBlock = {
                sgvs = parseReadingsData.sensorGlucoseValues
                mbgs = parseReadingsData.meteredGlucoseValues
                cals = parseReadingsData.calibrations
                
                FIXME()
                ///Need a task here to generate complication data.
                
//                OperationQueue.main.addOperation {
//                    completion(configuration, sgvs, cals, mbgs, device, nil)
//                }
            }
            
            self.processingQueue.addOperation(parseReadingsData)
        }
        
        print(">>> Starting network request for \(url) <<<")
        downloadReadingsTask.resume()
        
        var requestDevice = generateConfigurationRequestHeader(withBaseURL: url, withApiSecretString: nil, forAPIRoute: .devicestatus)
        requestDevice.networkServiceType = userInitiated ? .default : .background
        
        let deviceTask = session.downloadTask(with: requestDevice) { (location, response, error) in
            print(">>> deviceTask task is complete. <<<")
            //print(">>> downloadTask: {\nlocation: \(location),\nresponse: \(response),\nerror: \(error)\n} <<<")
            
            // Is there a file at the location provided?
            guard let location = location else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .downloadedLocationIsMissing)
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            guard let dataFromLocation = try? Data(contentsOf: location) else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
                OperationQueue.main.addOperation {
                    completion(nil, nil, nil, nil, nil, apiError)
                }
                return
            }
            
            let parseDeviceData = ParseDeviceStatusOperation(withJSONData: dataFromLocation)
            parseDeviceData.completionBlock = {
                device = parseDeviceData.deviceStatus
                
                OperationQueue.main.addOperation {
                    completion(configuration, sgvs, cals, mbgs, device, nil)
                }
            }
            
            self.processingQueue.addOperation(parseDeviceData)
        }
        
        deviceTask.resume()
    }
    
}

public extension Site {
    public func fetchDataFromNetwrok(userInitiated: Bool = false, completion:@escaping (_ updatedSite: Site, _ error: NightscoutRESTClientError?) -> Void) {
        
        var updatedSite = self

        Nightscout().networkRequest(forNightscoutURL: self.url, apiPassword: self.apiSecret, userInitiated: userInitiated) { (config, sgvs, cals, mbgs, devices, err) in
            
            if let error = err {
                print(error.kind)
                // We need to propogate the error to UI.
                updatedSite.disabled = true
                completion(updatedSite, error)

                //fatalError()
            }
            
            // Process the updates to the site.
            
            if let conf = config {
                updatedSite.configuration = conf
            }
            
            if let sgvs = sgvs {
                updatedSite.sgvs = sgvs
            }
            
            if let mbgs = mbgs {
                updatedSite.mbgs = mbgs
            }
            
            if let cals = cals {
                updatedSite.cals = cals
            }
            
            if let deviceStatus = devices {
                updatedSite.deviceStatuses = deviceStatus
            }
            
            updatedSite.lastUpdatedDate = Date()
            OperationQueue.current?.addOperation {
                updatedSite.generateComplicationData()
            }
            
            completion(updatedSite, nil)
        }
    }
}
