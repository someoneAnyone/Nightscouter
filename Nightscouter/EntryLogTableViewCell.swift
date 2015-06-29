//
//  EntryLogTableViewCell.swift
//  Nightscout
//
//  Created by Peter Ina on 6/9/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class EntryLogTableViewCell: UITableViewCell {
    @IBOutlet weak var sgv: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var dateString: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var filtered: UILabel!
    @IBOutlet weak var unfiltered: UILabel!
    @IBOutlet weak var direction: UILabel!
    @IBOutlet weak var idString: UILabel!
    @IBOutlet weak var noise: UILabel!
    @IBOutlet weak var rssi: UILabel!
    @IBOutlet weak var raw: UILabel!
    @IBOutlet weak var device: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
