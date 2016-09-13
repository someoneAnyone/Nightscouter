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
        self.backgroundColor = UIColor.clear
    }
    
    func configureCell(_ site: Site) {
        
        let model = site.viewModel
        
        let date = Calendar.autoupdatingCurrent.stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
                
        siteLastReadingLabel.text = date
        siteLastReadingLabel.textColor = UIColor(hexString: model.lastReadingColor)

        siteBatteryHeader.isHidden = !model.batteryVisible
        siteBatteryLabel.isHidden = !model.batteryVisible
        siteBatteryLabel.text = model.batteryString
        siteBatteryLabel.textColor = UIColor(hexString: model.batteryColor)
        
        siteRawLabel?.isHidden = !model.rawVisible
        siteRawHeader?.isHidden = !model.rawVisible
        
        siteRawLabel.text = model.rawString
        siteRawLabel.textColor = UIColor(hexString: model.rawColor)
        
        
        siteNameLabel.text = model.displayName
        siteUrlLabel.text = model.displayUrlString
        
        siteColorBlockView.backgroundColor = UIColor(hexString: model.sgvColor)
        
        siteCompassControl.configureWith(model)
        
        setNeedsLayout()
        layoutIfNeeded()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        siteNameLabel.text = nil
        siteBatteryLabel.text = nil
        siteRawLabel.text = nil
        siteLastReadingLabel.text = nil
        siteColorBlockView.backgroundColor = siteCompassControl.color
        siteLastReadingLabel.text = Constants.LocalizedString.tableViewCellLoading.localized
        siteLastReadingLabel.textColor = Theme.Color.labelTextColor
        
        siteRawHeader.isHidden = false
        siteRawLabel.isHidden = false
        siteRawLabel.textColor = Theme.Color.labelTextColor
    }
}
