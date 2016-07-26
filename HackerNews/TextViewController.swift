//
//  TextViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/9/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class TextViewController: UIViewController {
    @IBOutlet var textView:UITextView!
    var story:HNStory?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = hackerBeige()
        textView.backgroundColor = hackerBeige()
        let text = story?.text
        let htmlString = "<style> body {font-family:\"Helvetica Neue Thin\", Helvetica, Arial, \"Lucida Grande\", sans-serif; font-weight: 300; font-size:14 } </style> <body> \(text!) </body>"
        let optionsDictionary = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
        textView.attributedText = try? NSAttributedString(data: htmlString.dataUsingEncoding(NSUnicodeStringEncoding, allowLossyConversion:true)!, options: optionsDictionary, documentAttributes: nil)
    }
    
    func hackerBeige() -> UIColor  {
        return SKColorMakeRGB(245.0, 245.0, 238.0)
    }
}
