//
//  ParseConfigurationOperation.swift
//  Nightscouter
//
//  Created by Peter Ina on 9/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public class ParseReadingsOperation: Operation, NightscouterOperation {
    
    internal var error: NightscoutRESTClientError?
    @objc internal var data: Data?
    
    var sensorGlucoseValues: [SensorGlucoseValue] = []
    var calibrations: [Calibration] = []
    var meteredGlucoseValues: [MeteredGlucoseValue] = []
    
    fileprivate enum SupportedEntryTypes: String {
        case sgv, mbg, cal
    }
    
    @objc public convenience init(withJSONData data: Data?) {
        self.init()
        self.name = "Parse JSON for Parse Readings Operation"
        self.data = data
    }
    
    public override func main() {
        guard let data = data, let stringVersion = String(data: data, encoding: String.Encoding.utf8) else {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .couldNotCreateDataFromDownloadedFile)
            self.error = apiError
            
            return
        }
        
        if self.isCancelled { return }
        
        do {
            
            // remove any + notation from the API. This was causing a crash a while back.
            let cleanedData = stringVersion.replacingOccurrences(of: "+", with: "").data(using: .utf8)!
            
            // create an json array of objects.
            let entries: [[String: Any]] = try JSONSerialization.jsonObject(with: cleanedData, options: .allowFragments) as! [[String: Any]]
            
            // iterate through entries
            for entry in entries {
                
                guard let typedString = entry["type"] as? String, let type = SupportedEntryTypes(rawValue: typedString) else {
                    let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown("The JSON parser did not understand an entry type."))
                    self.error = apiError
                    
                    return
                }
                
                let decoder = JSONDecoder()
                let entryData = try JSONSerialization.data(withJSONObject: entry, options: .prettyPrinted)
                
                switch type {
                case .sgv:
                    let sgvEntry = try decoder.decode(SensorGlucoseValue.self, from: entryData)
                    sensorGlucoseValues.append(sgvEntry)
                case .cal:
                    let calEntry = try decoder.decode(Calibration.self, from: entryData)
                    calibrations.append(calEntry)
                case .mbg:
                    let mbgEntry = try decoder.decode(MeteredGlucoseValue.self, from: entryData)
                    meteredGlucoseValues.append(mbgEntry)
                }
            }
            
            return
        } catch let error {
            let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .invalidJSON(error))
           self.error = apiError
            
            return
        }
    }
    
}
