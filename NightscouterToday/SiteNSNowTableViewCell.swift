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
    @IBOutlet weak var siteSgvLabel: UILabel!
    @IBOutlet weak var siteDirectionLabel: UILabel!
    
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
        
        siteColorBlockView.backgroundColor = delegate?.sgvColor

        siteSgvLabel.text = dataSource.sgvLabel + " " + dataSource.direction.emojiForDirection
        siteSgvLabel.textColor = delegate?.sgvColor
        
        siteDirectionLabel.text = dataSource.deltaLabel
        siteDirectionLabel.textColor = delegate?.deltaColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        siteNameLabel.text = nil
        siteBatteryLabel.text = nil
        siteRawLabel.text = nil
        siteLastReadingLabel.text = nil
        siteColorBlockView.backgroundColor = DesiredColorState.neutral.colorValue
        siteSgvLabel.text = nil
        siteSgvLabel.textColor = Theme.AppColor.labelTextColor
        siteDirectionLabel.text = nil
        siteDirectionLabel.textColor = Theme.AppColor.labelTextColor
        siteLastReadingLabel.text = LocalizedString.tableViewCellLoading.localized
        siteLastReadingLabel.textColor = Theme.AppColor.labelTextColor
        siteRawHeader.isHidden = false
        siteRawLabel.isHidden = false
        siteRawLabel.textColor = Theme.AppColor.labelTextColor
    }
}
