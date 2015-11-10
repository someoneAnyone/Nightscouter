//
//  SiteTableViewswift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit
import NightscouterKit

class SiteNSNowTableViewCell: UITableViewCell {
    
    @IBOutlet weak var siteLastReadingHeader: UILabel!
    @IBOutlet weak var siteLastReadingLabel: UILabel!
    
    @IBOutlet weak var siteBatteryHeader: UILabel!
    @IBOutlet weak var siteBatteryLabel: UILabel!
    
    @IBOutlet weak var siteRawHeader: UILabel!
    @IBOutlet weak var siteRawLabel: UILabel!
    
    @IBOutlet weak var siteNameLabel: UILabel!
    
     @IBOutlet weak var siteColorBlockView: UIView!
    // @IBOutlet weak var siteCompassControl: CompassControl!
    
    @IBOutlet weak var siteSgvLabel: UILabel!
    @IBOutlet weak var siteDirectionLabel: UILabel!
    
    // @IBOutlet weak var siteDeltaHeader: UILabel!
    // @IBOutlet weak var siteDeltaLabel: UILabel!
    
    // @IBOutlet weak var siteUrlLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clearColor()
    }
    
    func configureCell(site: Site) {
        
        // siteUrlLabel.text = site.url.host
        
        let defaultTextColor = Theme.Color.labelTextColor
        
        if let configuration = site.configuration {
            
            siteNameLabel.text = configuration.displayName
            
            let units: Units = configuration.displayUnits
            
            if let watchEntry = site.watchEntry {
                // Configure compass control
                // siteCompassControl.configureWith(site)
                
                // Battery label
                siteBatteryLabel.text = watchEntry.batteryString
                siteBatteryLabel.textColor = colorForDesiredColorState(watchEntry.batteryColorState)
                
                // Last reading label
                siteLastReadingLabel.text = watchEntry.dateTimeAgoString
                
                if let sgvValue = watchEntry.sgv {
                
                    var boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv)
                    if units == .Mmol {
                        boundedColor = configuration.boundedColorForGlucoseValue(sgvValue.sgv.toMgdl)
                    }
                    let color = colorForDesiredColorState(boundedColor)
                    
                    siteColorBlockView.backgroundColor = color
                    
                    siteSgvLabel.text = "\(sgvValue.sgvString) \(sgvValue.direction.emojiForDirection)"
                    siteSgvLabel.textColor = color
                    
                    siteDirectionLabel.text = "\(watchEntry.bgdelta.formattedForBGDelta) \(units.description)"
                    siteDirectionLabel.textColor = color

                    
                    if configuration.displayRawData {
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
                

                    let timeAgo = watchEntry.date.timeIntervalSinceNow
                    let isStaleData = configuration.isDataStaleWith(interval: timeAgo)
                    // siteCompassControl.shouldLookStale(look: isStaleData.warn)
                    
                    if isStaleData.warn {
                        siteBatteryLabel?.text = "---%"
                        siteBatteryLabel?.textColor = defaultTextColor
                        siteRawLabel?.text = "--- : ---"
                        siteRawLabel?.textColor = defaultTextColor
                        siteLastReadingLabel?.textColor = NSAssetKit.predefinedWarningColor
                        siteColorBlockView.backgroundColor = colorForDesiredColorState(DesiredColorState.Neutral)
                        
                        siteSgvLabel.text = "---"
                        siteSgvLabel.textColor = colorForDesiredColorState(.Neutral)
                        
                        siteDirectionLabel.text = "----"
                        siteDirectionLabel.textColor = colorForDesiredColorState(.Neutral)
                    }
                    
                    if isStaleData.urgent{
                        siteLastReadingLabel?.textColor = NSAssetKit.predefinedAlertColor
                    }
                    
                } else {
                    #if DEBUG
                        println("No SGV was found in the watch")
                    #endif
                }
                
            } else {
                // No watch was there...
                #if DEBUG
                    println("No watch data was found...")
                #endif
            }
        } else {
            #if DEBUG
                println("No site current configuration was found for \(site.url)")
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
        // siteCompassControl.shouldLookStale(look: true)
         siteColorBlockView.backgroundColor = colorForDesiredColorState(DesiredColorState.Neutral)
        
        siteSgvLabel.text = nil
        siteSgvLabel.textColor = Theme.Color.labelTextColor
        
        siteDirectionLabel.text = nil
        siteDirectionLabel.textColor = Theme.Color.labelTextColor
        
        siteLastReadingLabel.text = Constants.LocalizedString.tableViewCellLoading.localized
        siteLastReadingLabel.textColor = Theme.Color.labelTextColor
        
        siteRawHeader.hidden = false
        siteRawLabel.hidden = false
        siteRawLabel.textColor = Theme.Color.labelTextColor
    }
}
