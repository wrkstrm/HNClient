
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
    @IBOutlet weak var newImage: UIImageView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        parent?.title = "A Hacker News Client"
        subtitle.text = ""
    }
}
