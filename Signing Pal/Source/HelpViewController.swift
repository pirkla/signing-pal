//
//  HelpViewController.swift
//  Signing Pal
//
//  Created by Andrew Pirkl on 6/4/20.
//  Copyright © 2020 Pirklator. All rights reserved.
//

import Cocoa
class HelpViewController: NSViewController {
    @IBAction func SysPrefButton(_ sender: Any) {
        let myUrl = URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane")
        NSWorkspace.shared.open(myUrl)
    }
    
}
