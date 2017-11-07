//
//  SectionHeaderView.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/25/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

enum SectionHeaderType {
    case simple, stepper
}

protocol SectionHeaderDelegate {
    func sectionStateDidChange(_ section:SectionHeaderView, open:Bool)
    func sectionValueDidChange(_ section:SectionHeaderView, value:Double)
}

class SectionHeaderView : UITableViewHeaderFooterView {
    @IBOutlet var disclosureButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    var delegate:SectionHeaderDelegate?
    var tap:UITapGestureRecognizer?
    
    override func awakeFromNib() {
        stepper.addTarget(self, action:#selector(SectionHeaderView.stepperValueDidChange(_:)),
            for: UIControlEvents.touchUpInside)
        stepper.maximumValue = DBL_MAX
        tap = UITapGestureRecognizer(target: self, action:#selector(SectionHeaderView.toggleOpen(_:)))
        addGestureRecognizer(tap!)
        tap?.isEnabled = true;
    }
    
    func prepareForSection(_ sectionNumber:Int!, type:SectionHeaderType,
        text:String, value:Double?) {
            tag = sectionNumber
            //Label
            titleLabel.text = text
            stepper.tag = sectionNumber
            switch type {
            case .simple:
                stepper.isHidden = true
            case .stepper:
                stepper.isHidden = false
                stepper.value = value!
            }
    }
    
    func setState(_ open:Bool) {
        self.disclosureButton.isSelected = open;
        let newTransform = CGAffineTransform(rotationAngle: open ? 0 : CGFloat(-M_PI_2))
        self.disclosureButton.imageView?.transform = newTransform;
    }
    
    func stepperValueDidChange(_ sender: UIStepper) {
        if let sectionDelegate = delegate {
            sectionDelegate.sectionValueDidChange(self, value: sender.value)
        }
    }
    
    func toggleOpen(_ sender:AnyObject!) {
        UIView.animate(withDuration: 0.3, animations: {
            self.setState(!self.disclosureButton.isSelected)
        }) 
        if let sectionDelegate = delegate {
            sectionDelegate.sectionStateDidChange(self, open: disclosureButton.isSelected)
        }
    }
}
