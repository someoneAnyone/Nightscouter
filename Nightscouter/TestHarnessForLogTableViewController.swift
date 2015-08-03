//
//  TestHarnessForLogTableViewController.swift
//  Nightscout
//
//  Created by Peter Ina on 6/4/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//

import UIKit

class TestHarnessForLogTableViewController: UITableViewController {
    var dataForTable = Array<Entry>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 100; // set to whatever your "average" cell height is
        
        let url: NSURL = NSUserDefaults.standardUserDefaults().URLForKey("url")!// NSURL(string:  ")!
        let nsAPI = NightscoutAPIClient(url:url)
        
        nsAPI.fetchDataForEntries(count: 100) { (entries, errorCode) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in

            if let entriesForTable = entries {
                self.dataForTable = entriesForTable
            }
            self.navigationItem.title = "\(self.dataForTable.count) : Entries Listed"
            self.tableView.reloadData()
            })
        }
              
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.dataForTable.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nsLogCell", forIndexPath: indexPath) as! TestHarnessEntryLogTableViewCell
        
        let entry: Entry = self.dataForTable[indexPath.row] as Entry
        
        if let sgValue: SensorGlucoseValue = entry.sgv {
            cell.sgv.text =  "\(sgValue.sgv)"
            cell.direction.text = sgValue.direction.rawValue
            cell.rssi.text = "rssi: \(sgValue.rssi)"
            cell.unfiltered.text = "unfiltered: \(sgValue.unfiltered)"
            cell.filtered.text = "filtered: \(sgValue.filtered)"
            cell.noise.text = "noise: \(sgValue.noise)"
        }

        if let type = entry.type {
            cell.type.text = "type: \(type.rawValue)"
        } else {
            cell.type.text = "type: \(Type().rawValue)"
        }

        cell.device.text = entry.device
        cell.idString.text = "id:\(entry.idString)"
        cell.dateString.text = entry.dateString
        
        let dateFormatter = NSDateFormatter()
        //To prevent displaying either date or time, set the desired style to NoStyle.
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle //Set time style
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle //Set date style
        dateFormatter.timeZone = NSTimeZone()
        let localDate = dateFormatter.stringFromDate(entry.date)
        
        cell.date.text = localDate
        
        return cell
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
