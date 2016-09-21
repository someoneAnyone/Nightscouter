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
        self.backgroundColor = UIColor.clear
    }
    
    func configureCell(_ site: Site) {
        
        let model = site.summaryViewModel
        
        let date = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
        
        siteLastReadingLabel.text = date
        siteLastReadingLabel.textColor = model.lastReadingColor
        
        siteBatteryHeader.isHidden = model.batteryHidden
        siteBatteryLabel.isHidden = model.batteryHidden
        siteBatteryLabel.text = model.batteryLabel
        siteBatteryLabel.textColor = model.batteryColor
        
        siteRawLabel?.isHidden = model.rawHidden
        siteRawHeader?.isHidden = model.rawHidden
        
        siteRawLabel.text = model.rawLabel
        siteRawLabel.textColor = model.rawColor
        
        siteNameLabel.text = model.nameLabel
        
        siteColorBlockView.backgroundColor = model.sgvColor
        
        siteSgvLabel.textColor = model.sgvColor
        
        //:warn /// EMJOI?
        siteSgvLabel.text = model.sgvLabel
        
        siteDirectionLabel.text = model.deltaLabel
        siteDirectionLabel.textColor = model.deltaColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        siteNameLabel.text = nil
        siteBatteryLabel.text = nil
        siteRawLabel.text = nil
        siteLastReadingLabel.text = nil
        siteColorBlockView.backgroundColor = DesiredColorState.neutral.colorValue
        
        siteSgvLabel.text = nil
//        siteSgvLabel.textColor = Theme.Color.labelTextColor
        
        siteDirectionLabel.text = nil
//        siteDirectionLabel.textColor = Theme.Color.labelTextColor
        
//        siteLastReadingLabel.text = Constants.LocalizedString.tableViewCellLoading.localized
//        siteLastReadingLabel.textColor = Theme.Color.labelTextColor
        
        siteRawHeader.isHidden = false
        siteRawLabel.isHidden = false
//        siteRawLabel.textColor = Theme.Color.labelTextColor
    }
}
