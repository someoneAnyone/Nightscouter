//
//  SiteTableViewCell.swift
//  Nightscouter
//
//  Created by Peter Ina on 6/16/15.
//  Copyright © 2015 Peter Ina. All rights reserved.
//

import UIKit

class SiteTableViewCell: UITableViewCell {

    @IBOutlet weak var siteName: UILabel!
    @IBOutlet weak var siteBatteryLevel: UILabel!
    @IBOutlet weak var siteRaw: UILabel!
    @IBOutlet weak var siteTimeAgo: UILabel!
    @IBOutlet weak var siteColorBlock: UIView!
    @IBOutlet weak var compassControl: CompassControl!
    @IBOutlet weak var siteURL: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    override func prepareForReuse() {
        super.prepareForReuse()
//        compassControl.configireDrawRect(isDoubleUp: false, isArrowVisible: false, isUncomputable: false, angle: 0, sgvText: "---")
    }
}
