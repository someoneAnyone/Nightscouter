/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Helpers for loading images and data.
 */

import Foundation

let siteData: [Site] = load("NightscouterSiteData.json") ?? []

let sharedDefaults = UserDefaults.init(suiteName: "group.com.nothingonline.nightscouter") ?? UserDefaults()

extension Notification.Name {
    static let dataWrittenToDisk = Notification.Name("DataWrittenToDisk")
    static let dataWrittenToDefaults = Notification.Name("DtaWrittenToDefaults")
}

func load<T: Decodable>(_ filename: String, as type: T.Type = T.self) -> T? {
    let data: Data
    
    let pathDirectory = getDocumentsDirectory()
    let filePath = pathDirectory.appendingPathComponent(filename)
    
    do {
        #if os(watchOS)
        
        guard let siteData = sharedDefaults.data(forKey: "siteData") else {
            return nil
        }
        
        data = siteData
        
        #else
        
        data = try Data(contentsOf: filePath)
        
        #endif
        return load(data)
    } catch {
        return nil
    }
}

func load<T: Decodable>(_ data: Data, as type: T.Type = T.self) -> T? {
    
    let dataToDecode: Data
    
    do {
        let decoder = JSONDecoder()
        dataToDecode = data
        
        return try decoder.decode(T.self, from: dataToDecode)
    } catch {
        return nil
    }
}



public func saveSiteData(withSites sites: [Site]) {
    
    let pathDirectory = getDocumentsDirectory()
    try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
    let filePath = pathDirectory.appendingPathComponent("NightscouterSiteData.json")
    
    let sites = sites
    let json = try? JSONEncoder().encode(sites)
    
    do {
        print("Write data.")
        try json!.write(to: filePath)
        
        sharedDefaults.set(json, forKey: "siteData")
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dataWrittenToDisk, object: ["json": json])
        }
    } catch {
        print("Failed to write JSON data: \(error.localizedDescription)")
        fatalError()
    }
    
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

