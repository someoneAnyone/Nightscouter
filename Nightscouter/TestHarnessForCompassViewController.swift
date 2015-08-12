//
//  ViewController.swift
//  Nightscout Watch Face
//
//  Created by Peter Ina on 4/30/15.
//  Copyright (c) 2015 Peter Ina. All rights reserved.
//


// This is a test harness for a UI Control that simulates a compass dial and displays SGV value

import UIKit
import NightscouterKit

class TestHarnessForCompassViewController: UIViewController {
    
    @IBOutlet weak var imageRep: UIImageView!

    @IBOutlet weak var compassControlView: CompassControl!
    @IBOutlet weak var sgvSlider: UISlider!
    @IBOutlet weak var deltaText: UITextField!
    @IBOutlet weak var modeSwitch: UISegmentedControl!
    
    @IBOutlet weak var sgvLabel: UILabel!
    @IBOutlet weak var modeLabel: UILabel!
    
    let placeholderSgvString: String = "SGV value"
    let placeholderModeString: String = "Compass Mode"

    let bgUnits: String = "mg/dl"
    var oldValue: Int = 0
    var newValue: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setModeSwitch()
        updateDelta()
        updateSgv()
        
        self.view.tintColor = compassControlView.color

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        compassControlView.setNeedsDisplay()
        
        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
            print("land")
        } else {
            print("port")
        }
        
    }
    
    @IBAction func sgvValueChanged(sender: UISlider) {
        newValue = Int(sender.value)
        updateSgv()
    }
    
    @IBAction func sgvValueBeginEdit(sender: UISlider) {
        oldValue = Int(sender.value);
    }
    
    @IBAction func sgvValueEditingEnd(sender: UISlider) {
        newValue = Int(sender.value);
        updateDelta()
    }
    
    @IBAction func modeValueChanged(sender: UISegmentedControl) {
        let currentIndex = sender.selectedSegmentIndex
        
        
        compassControlView.direction = Direction.allValues[currentIndex]
        
        modeLabel.text = placeholderModeString + ": " + sender.titleForSegmentAtIndex(currentIndex)!
        updateSgv()

    }

}

extension TestHarnessForCompassViewController {
    func setModeSwitch (){
        self.modeSwitch.removeAllSegments()
        for (index, value) in enumerate(Direction.allValues) {
            self.modeSwitch.insertSegmentWithTitle("\(value.emojiForDirection)", atIndex: index, animated: true)
        }
        self.modeSwitch.selectedSegmentIndex = 0
        self.modeLabel.text = placeholderModeString + ": " + self.modeSwitch.titleForSegmentAtIndex(self.modeSwitch.selectedSegmentIndex)!
    }
    
    func updateDelta(){
        print("newValue: \(newValue); oldValue: \(oldValue); delta: \(newValue - oldValue)")
        let deltaValue = newValue - oldValue
        compassControlView.delta = "\(deltaValue.formattedForBGDelta) " + bgUnits
    }
    
    func updateSgv(){
        sgvLabel.text = placeholderSgvString + ": " + NSNumberFormatter.localizedStringFromNumber(self.sgvSlider.value, numberStyle: .NoStyle)
        compassControlView.sgvText = String(stringInterpolationSegment:NSNumberFormatter.localizedStringFromNumber(self.sgvSlider.value, numberStyle: .NoStyle))

        compassControlView.color = NSAssetKit.predefinedNeutralColor
        self.view.tintColor = compassControlView.color
    }
}