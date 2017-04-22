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
    internal var data: Data?

    var sensorGlucoseValues: [SensorGlucoseValue] = []
    var calibrations: [Calibration] = []
    var meteredGlucoseValues: [MeteredGlucoseValue] = []
    
    fileprivate enum SupportedEntryTypes: String {
        case sgv, mbg, cal, pumpdata
    }
    
    public convenience init(withJSONData data: Data?) {
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
            let cleanedData = stringVersion.replacingOccurrences(of: "+", with: "").data(using: .utf8)!
            let entries: [[String: Any]] = try JSONSerialization.jsonObject(with: cleanedData, options: .allowFragments) as! [[String: Any]]
            
            for entry in entries {
             
                guard let typedString = entry["type"] as? String, let type = SupportedEntryTypes(rawValue: typedString) else {
                    let apiError = NightscoutRESTClientError(line: #line, column: #column, kind: .unknown("The JSON parser did not understand an entry type."))
                    self.error = apiError
                    
                    return
                }
                
                switch type {
                case .sgv:
                    if let sgv = SensorGlucoseValue.decode(entry) {
                        sensorGlucoseValues.append(sgv)
                    }
                case .mbg:
                    if let mbg = MeteredGlucoseValue.decode(entry) {
                        meteredGlucoseValues.append(mbg)
                    }
                case .cal:
                    if let cal = Calibration.decode(entry) {
                        calibrations.append(cal)
                    }
                case .pumpdata:
                    continue
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
