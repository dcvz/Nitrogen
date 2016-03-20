//
//  ViewController.swift
//  Nitrogen
//
//  Created by David Chavez on 16/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var emulator: EmulatorCore!
    var audioCore: OEGameAudio!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startEmulation(sender: AnyObject) {
        let vc = EmulatorViewController()
        presentViewController(vc, animated: true, completion: nil)
    }
}
