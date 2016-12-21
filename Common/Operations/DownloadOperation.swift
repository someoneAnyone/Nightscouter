//
//  DownloadConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/30/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

class DownloadOperation: Operation {
    
    var request: URLRequest
    
    var data: Data?
    var error: NightscoutRESTClientError?
    var isBackground: Bool
    
    public init(withURLRequest request: URLRequest, isBackground background: Bool) {
        self.request = request
        self.isBackground = background
        
        super.init()
        
        self.name = "Download data from \(request.url)"
    }
    
    override func main() {
        
        if self.isCancelled { return }
        
        let disGroup = DispatchGroup()
        
        disGroup.enter()
        
        let config = !isBackground ? URLSessionConfiguration.default :
            URLSessionConfiguration.background(withIdentifier: NightscoutRESTClientError.errorDomain)
        
        let session = URLSession(configuration: config)
        
        let downloadTask = session.downloadTask(with: self.request) { (location, response, error) in
            print(">>> downloadTask task for \(self.request.url) is complete. <<<")
            //print(">>> downloadTask: {\nlocation: \(location),\nresponse: \(response),\nerror: \(error)\n} <<<")
            
            if self.isCancelled {
                disGroup.leave()
                return
            }
            
            if let err = error {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown(err.localizedDescription))
                self.error = apiError
                disGroup.leave()
                return
            }
            
            // Is there a file at the location provided?
            guard let location = location else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .downloadedLocationIsMissing)
                self.error = apiError
                disGroup.leave()
                return
            }
            
            guard let dataFromLocation = try? Data(contentsOf: location) else {
                let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
                self.error = apiError
                disGroup.leave()
                return
            }
            
            self.data = dataFromLocation
            
            disGroup.leave()
        }
        
        downloadTask.resume()
        
        disGroup.wait()
    }
}
