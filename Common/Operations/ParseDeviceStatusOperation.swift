//
//  ParseConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public class ParseDeviceStatusOperation: Operation, NightscouterOperation {
    
    internal var error: NightscoutRESTClientError?
    @objc internal var data: Data?
    
    var deviceStatus: [DeviceStatus] = []
    
    @objc public convenience init(withJSONData data: Data) {
        self.init()
        self.name = "Parse JSON for Nightscout Device Status"
        self.data = data
    }
    
    public override func main() {
        guard let data = data else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown("We expect data to be set at this point in the NightscouterOperation"))
            self.error = apiError
            
            return
        }
        
        guard let stringVersion = String(data: data, encoding: String.Encoding.utf8) else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
            self.error = apiError
            
            return
        }
        
        if self.isCancelled { return }
        
        do {
            // let cleanedData = stringVersion.replacingOccurrences(of: "+", with: "").data(using: .utf8)!
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let deviceRecords = try decoder.decode([DeviceStatus].self, from: stringVersion.data(using: .utf8)!)
            
            deviceStatus.append(contentsOf: deviceRecords)
            
            return
        } catch let error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .invalidJSON(error))
            self.error = apiError
            
            return
        }
    }
    
}
