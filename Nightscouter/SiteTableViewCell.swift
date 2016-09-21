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
    
    func configure(withDataSource dataSource: TableViewRowWithCompassDataSource, delegate: TableViewRowWithCompassDelegate?) {
        

        siteLastReadingHeader.text = LocalizedString.lastReadingLabel.localized
        siteLastReadingLabel.text = dataSource.lastReadingDate.timeAgoSinceNow
        siteLastReadingLabel.textColor = delegate?.lastReadingColor

        siteBatteryHeader.text = LocalizedString.batteryLabel.localized
        siteBatteryHeader.isHidden = dataSource.batteryHidden
        siteBatteryLabel.isHidden = dataSource.batteryHidden
        siteBatteryLabel.text = dataSource.batteryLabel
        siteBatteryLabel.textColor = delegate?.batteryColor
        
        siteRawHeader.text = LocalizedString.rawLabel.localized
        siteRawLabel?.isHidden = dataSource.rawHidden
        siteRawHeader?.isHidden = dataSource.rawHidden
        
        siteRawLabel.text = dataSource.rawLabel
        siteRawLabel.textColor = delegate?.rawColor
        
        
        siteNameLabel.text = dataSource.nameLabel
        siteUrlLabel.text = dataSource.urlLabel
        
        siteColorBlockView.backgroundColor = delegate?.sgvColor
        
        siteCompassControl.configure(withDataSource: dataSource, delegate: delegate)
        
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
        siteLastReadingLabel.text = LocalizedString.tableViewCellLoading.localized
        siteLastReadingLabel.textColor = Theme.AppColor.labelTextColor
        
        siteRawHeader.isHidden = false
        siteRawLabel.isHidden = false
        siteRawLabel.textColor = Theme.AppColor.labelTextColor
    }
}
