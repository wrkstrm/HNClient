//
//  SectionHeaderView.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/25/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

enum SectionHeaderType {
    case Simple, Stepper
}

protocol SectionHeaderDelegate {
    func sectionStateDidChange(section:SectionHeaderView, open:Bool)
    func sectionValueDidChange(section:SectionHeaderView, value:Double)
}

class SectionHeaderView : UITableViewHeaderFooterView {
    @IBOutlet var disclosureButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    var delegate:SectionHeaderDelegate?
    var tap:UITapGestureRecognizer?
    
    override func awakeFromNib() {
        stepper.addTarget(self, action:#selector(SectionHeaderView.stepperValueDidChange(_:)),
            forControlEvents: UIControlEvents.TouchUpInside)
        stepper.maximumValue = DBL_MAX
        tap = UITapGestureRecognizer(target: self, action:#selector(SectionHeaderView.toggleOpen(_:)))
        addGestureRecognizer(tap!)
        tap?.enabled = true;
    }
    
    func prepareForSection(sectionNumber:Int!, type:SectionHeaderType,
        text:String, value:Double?) {
            tag = sectionNumber
            //Label
            titleLabel.text = text
            stepper.tag = sectionNumber
            switch type {
            case .Simple:
                stepper.hidden = true
            case .Stepper:
                stepper.hidden = false
                stepper.value = value!
            }
    }
    
    func setState(open:Bool) {
        self.disclosureButton.selected = open;
        let newTransform = CGAffineTransformMakeRotation(open ? 0 : CGFloat(-M_PI_2))
        self.disclosureButton.imageView?.transform = newTransform;
    }
    
    func stepperValueDidChange(sender: UIStepper) {
        if let sectionDelegate = delegate {
            sectionDelegate.sectionValueDidChange(self, value: sender.value)
        }
    }
    
    func toggleOpen(sender:AnyObject!) {
        UIView.animateWithDuration(0.3) {
            self.setState(!self.disclosureButton.selected)
        }
        if let sectionDelegate = delegate {
            sectionDelegate.sectionStateDidChange(self, open: disclosureButton.selected)
        }
    }
}
