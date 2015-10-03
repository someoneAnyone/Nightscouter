//
//  SiteTableViewswift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var siteLastReadingHeader: UILabel!
    @IBOutlet weak var siteLastReadingLabel: UILabel!
    
    @IBOutlet weak var siteBatteryHeader: UILabel!
    @IBOutlet weak var siteBatteryLabel: UILabel!
    
    @IBOutlet weak var siteRawHeader: UILabel!
    @IBOutlet weak var siteRawLabel: UILabel!
    
    @IBOutlet weak var siteNameLabel: UILabel!
    
    @IBOutlet weak var siteColorBlockView: UIView!
    @IBOutlet weak var siteCompassControl: CompassControl!
    
    @IBOutlet weak var siteUrlLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clearColor()
    }
    
    func configureCell(site: Site) {
        
        siteUrlLabel.text = site.url.host
        
        let defaultTextColor = Theme.Color.labelTextColor
        
        if let configuration = site.configuration {
            
//            let maxValue: NSTimeInterval?
//            if let defaults = configuration.defaults {
//                maxValue = max(Constants.NotableTime.StaleDataTimeFrame, defaults.alarms.alarmTimeAgoWarnMins)
//            } else {
//                maxValue = Constants.NotableTime.StaleDataTimeFrame
//            }
            
            siteNameLabel.text = configuration.displayName
            
            if let watchEntry = site.watchEntry {
                // Configure compass control
                siteCompassControl.configureWith(site)
                
                // Battery label
                siteBatteryLabel.text = watchEntry.batteryString
                siteBatteryLabel.textColor = colorForDesiredColorState(watchEntry.batteryColorState)
                
                // Last reading label
                siteLastReadingLabel.text = watchEntry.dateTimeAgoString
                
                if let sgvValue = watchEntry.sgv {
                    
                    var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
                    if configuration.displayUnits == .Mmol {
                        boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
                    }
                    let color = colorForDesiredColorState(boundedColor)
                    
                    siteColorBlockView.backgroundColor = color
                    
                    if let enabledOptions = configuration.enabledOptions {
                        let rawEnabled =  enabledOptions.contains(EnabledOptions.rawbg)
                        if rawEnabled {
                            if let rawValue = watchEntry.raw {
                                let color = colorForDesiredColorState(configuration.boundedColorForGlucoseValue(rawValue))
                                
                                var raw = "\(rawValue.formattedForMgdl)"
                                if configuration.displayUnits == .Mmol {
                                    raw = rawValue.formattedForMmol
                                }
                                
                                siteRawLabel?.textColor = color
                                siteRawLabel.text = "\(raw) : \(sgvValue.noise)"
                            }
                        } else {
                            siteRawHeader.hidden = true
                            siteRawLabel.hidden = true
                        }
                    }
                    
                    let timeAgo = watchEntry.date.timeIntervalSinceNow
                    let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
                    siteCompassControl.shouldLookStale(look: isStaleData.warn)
                    
                    if isStaleData.warn {
                        siteBatteryLabel?.text = "---%"
                        siteBatteryLabel?.textColor = defaultTextColor
                        siteRawLabel?.text = "--- : ---"
                        siteRawLabel?.textColor = defaultTextColor
                        siteLastReadingLabel?.textColor = NSAssetKit.predefinedWarningColor
                        siteColorBlockView.backgroundColor = colorForDesiredColorState(DesiredColorState.Neutral)
                    }
                    
                    if isStaleData.urgent{
                        siteLastReadingLabel?.textColor = NSAssetKit.predefinedAlertColor
                    }
                    
                } else {
                    #if DEBUG
                        print("No SGV was found in the watch")
                    #endif
                }
                
            } else {
                // No watch was there...
                #if DEBUG
                    print("No watch data was found...")
                #endif
            }
        } else {
            #if DEBUG
                print("No site current configuration was found for \(site.url)")
            #endif
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        siteNameLabel.text = nil
        siteBatteryLabel.text = nil
        siteRawLabel.text = nil
        siteLastReadingLabel.text = nil
        siteCompassControl.shouldLookStale(look: true)
        siteColorBlockView.backgroundColor = siteCompassControl.color
        siteLastReadingLabel.text = Constants.LocalizedString.tableViewCellLoading.localized
        siteLastReadingLabel.textColor = Theme.Color.labelTextColor
        
        siteRawHeader.hidden = false
        siteRawLabel.hidden = false
        siteRawLabel.textColor = Theme.Color.labelTextColor
    }
}
