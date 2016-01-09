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
        
//        if let model = WatchModel(fromSite: site) {
      let model = WatchModel(fromSite: site)

            let date = NSCalendar.autoupdatingCurrentCalendar().stringRepresentationOfElapsedTimeSinceNow(model.lastReadingDate)
            
            siteLastReadingLabel.text = date
            siteLastReadingLabel.textColor = UIColor(hexString: model.lastReadingColor)
            
            siteBatteryLabel.text = model.batteryString
            siteBatteryLabel.textColor = UIColor(hexString: model.batteryColor)
            
            siteRawLabel?.hidden = !model.rawVisible
            siteRawHeader?.hidden = !model.rawVisible
            
            siteRawLabel.text = model.rawString
            siteRawLabel.textColor = UIColor(hexString: model.rawColor)
            
            
            siteNameLabel.text = model.displayName
            siteUrlLabel.text = model.displayUrlString
            
            siteColorBlockView.backgroundColor = UIColor(hexString: model.sgvColor)
            
            siteCompassControl.configureWith(model)

//        }
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
        siteColorBlockView.backgroundColor = siteCompassControl.color
        siteLastReadingLabel.text = Constants.LocalizedString.tableViewCellLoading.localized
        siteLastReadingLabel.textColor = Theme.Color.labelTextColor
        
        siteRawHeader.hidden = false
        siteRawLabel.hidden = false
        siteRawLabel.textColor = Theme.Color.labelTextColor
    }
}
