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

        emulator = EmulatorCore()
        let documentsDirectoryURL: NSURL! =  try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let batterySavesDirectoryPath: NSURL! = documentsDirectoryURL.URLByAppendingPathComponent("Battery States")
        let ndsFile: NSURL! = documentsDirectoryURL.URLByAppendingPathComponent("zelda.nds")

        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(batterySavesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch {}

        audioCore = OEGameAudio(core: emulator)
        audioCore.volume = 1.0
        audioCore.outputDeviceID = 0
        audioCore.startAudio()
        emulator.loadROM(ndsFile.path)
        emulator.startEmulation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

