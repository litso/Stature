//
//  ShowMeasurementController.swift
//  Stature
//
//  Created by Robert Manson on 2/21/19.
//  Copyright © 2019 Clutter. All rights reserved.
//

import UIKit

class ShowMeasurementController: UIViewController {
    var measurement: Measurement<UnitLength>!

    @IBOutlet weak var measurementLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        measurementLabel.text = measurement.inchesDescription
    }

    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}
