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
    
    @IBOutlet fileprivate weak var siteLastReadingHeader: UILabel!
    @IBOutlet fileprivate weak var siteLastReadingLabel: UILabel!
    @IBOutlet fileprivate weak var siteBatteryHeader: UILabel!
    @IBOutlet fileprivate weak var siteBatteryLabel: UILabel!
    @IBOutlet fileprivate weak var siteRawHeader: UILabel!
    @IBOutlet fileprivate weak var siteRawLabel: UILabel!
    @IBOutlet fileprivate weak var siteNameLabel: UILabel!
    @IBOutlet fileprivate weak var siteColorBlockView: UIView!
    @IBOutlet fileprivate weak var siteCompassControl: CompassControl!
    @IBOutlet fileprivate weak var siteUrlLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = Color.clear
        
        let highlightView = UIView()
        highlightView.backgroundColor = NSAssetKit.darkNavColor
        selectedBackgroundView = highlightView
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
        
        siteRawLabel.text = dataSource.rawFormatedLabel
        siteRawLabel.textColor = delegate?.rawColor
        
        siteNameLabel.text = dataSource.nameLabel
        siteUrlLabel.text = dataSource.urlLabel
        
//        siteUrlLabel.isHidden = true

        
        siteColorBlockView.backgroundColor = delegate?.sgvColor
        
        siteCompassControl.configure(withDataSource: dataSource, delegate: delegate)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        // siteCompassControl.isHidden = editing
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
