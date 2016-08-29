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
        
        let model = site.viewModel
        
        let date = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
        
        siteLastReadingLabel.text = date
        siteLastReadingLabel.textColor = UIColor(hexString: model.lastReadingColor)
        
        siteBatteryHeader.hidden = !model.batteryVisible
        siteBatteryLabel.hidden = !model.batteryVisible
        siteBatteryLabel.text = model.batteryString
        siteBatteryLabel.textColor = UIColor(hexString: model.batteryColor)
        
        siteRawLabel?.hidden = !model.rawVisible
        siteRawHeader?.hidden = !model.rawVisible
        
        siteRawLabel.text = model.rawString
        siteRawLabel.textColor = UIColor(hexString: model.rawColor)
        
        siteNameLabel.text = model.displayName
        
        siteColorBlockView.backgroundColor = UIColor(hexString: model.sgvColor)
        
        siteSgvLabel.textColor = UIColor(hexString: model.sgvColor)
        siteSgvLabel.text = model.sgvStringWithEmoji
        
        siteDirectionLabel.text = model.deltaString
        siteDirectionLabel.textColor = UIColor(hexString: model.deltaColor)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        siteNameLabel.text = nil
        siteBatteryLabel.text = nil
        siteRawLabel.text = nil
        siteLastReadingLabel.text = nil
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
