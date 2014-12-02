
//
//  LogoViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 12/1/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class LogoViewController: UIViewController {
    @IBOutlet var subtitle: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        parentViewController?.title = "A Hacker News Client"
        subtitle.text = ""
    }
}