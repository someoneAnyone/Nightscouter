//
//  Dictionary+Extension.swift
//  Nightscouter
//
//  Created by Peter Ina on 3/2/16.
//  Copyright © 2016 Peter Ina. All rights reserved.
//

import Foundation

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {
    public func saveAsPlist(_ fileName: String = "data") -> (successful: Bool, path: URL?) {
        guard let rootPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            print("No documents directory!")
            return (false, nil)
        }
        
        let url = URL(fileURLWithPath: rootPath)
        let plistPathInDocument = url.appendingPathComponent("\(fileName).plist")
        let dict = NSDictionary()
    
        //NSDictionary(objects: self.values.map{ $0 }, forKeys: self.keys.map{ String($0) })
        let ret = dict.write(toFile: plistPathInDocument.absoluteString, atomically: true)
        // print(ret)
        //let resultDictionary = NSMutableDictionary(contentsOfFile: plistPathInDocument.absoluteString)
        //print("Saved GameData.plist file is --> \(resultDictionary?.description)")
        
        return (ret, plistPathInDocument)
    }
}
