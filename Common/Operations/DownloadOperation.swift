//
//  DownloadConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/30/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

class DownloadOperation: Operation, URLSessionDelegate, URLSessionDownloadDelegate  {
    
    var request: URLRequest
    
    var data: Data?
    var error: NightscoutRESTClientError?
    var isBackground: Bool
    var disGroup: DispatchGroup?
    
    var downloadTask: URLSessionDownloadTask?
    
    public init(withURLRequest request: URLRequest, isBackground background: Bool) {
        self.request = request
        self.isBackground = background
        
        super.init()
        
        self.name = "Download data from \(String(describing: request.url))"
    }
    
    override func main() {
        
        if self.isCancelled { return }
        
        disGroup = DispatchGroup()
        disGroup?.enter()
        
        let config = !isBackground ? URLSessionConfiguration.default :
            URLSessionConfiguration.background(withIdentifier: NightscoutRESTClientError.errorDomain)
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        downloadTask = session.downloadTask(with: self.request)
        
        /*
         let disableddownloadTask = session.downloadTask(with: self.request) { (location, response, error) in
         print(">>> downloadTask task for \(String(describing: self.request.url)) is complete. <<<")
         //print(">>> downloadTask: {\nlocation: \(location),\nresponse: \(response),\nerror: \(error)\n} <<<")
         
         if self.isCancelled {
         self.disGroup.leave()
         return
         }
         
         if let err = error {
         let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
         self.error = apiError
         self.disGroup.leave()
         return
         }
         
         // Is there a file at the location provided?
         guard let location = location else {
         let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .downloadedLocationIsMissing)
         self.error = apiError
         self.disGroup.leave()
         return
         }
         
         guard let dataFromLocation = try? Data(contentsOf: location) else {
         let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
         self.error = apiError
         self.disGroup.leave()
         return
         }
         
         self.data = dataFromLocation
         
         self.disGroup.leave()
         }
         
         */
        
        downloadTask?.resume()
        disGroup?.wait()
    }
    
    //MARK: session delegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("session error: \(String(describing: error?.localizedDescription)).")
        if let err = error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
            self.error = apiError
            disGroup?.leave()
            return
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
        
        guard let dataFromLocation = try? Data(contentsOf: location) else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
            self.error = apiError
            disGroup?.leave()
            return
        }
        
        self.data = dataFromLocation
        disGroup?.leave()
        
        return
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let err = error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
            self.error = apiError
            disGroup?.leave()
            
            return
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("background session \(session) finished events.")
        
        if let sessionId = session.configuration.identifier {
            print(sessionId)
        }
    }
    
}
