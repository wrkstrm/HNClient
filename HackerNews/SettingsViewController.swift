//
//  SettingsViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/24/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class SettingsViewController : HNSettingsViewController, SectionHeaderDelegate {
    let headerIdentifier = "headerReuseIdentifier"
    let sectionHeaderHeight:CGFloat = 48.0
    let hiddenSection = 2
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = AppDelegate.hackerBeige()
        
        let headerNib = UINib(nibName: "SectionHeader", bundle: nil)
        tableView.registerNib(headerNib, forHeaderFooterViewReuseIdentifier: headerIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        parentViewController?.title = "Current Story Filters"
    }
    
    //MARK:- TableView Section Delegate Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3;
    }
    
    override func tableView(tableView: UITableView,
        heightForHeaderInSection section: Int) -> CGFloat {
            return sectionHeaderHeight;
    }
    
    override func tableView(tableView: UITableView,
        viewForHeaderInSection section: Int) -> UIView? {
            var header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(headerIdentifier)
                as SectionHeaderView
            configureSectionHeader(header, sectionNumber: section)
            return header
    }
    
    func configureSectionHeader(headerView:SectionHeaderView, sectionNumber:Int) {
        let  user = HNStoryManager.sharedInstance().currentUser
        var labelText:String
        switch sectionNumber {
        case 0:
            labelText = "Minimum Score: \(user.minimumScore)"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Stepper,
                text: labelText, value: Double(user.minimumScore))
        case 1:
            labelText =  "Minimum Comments: \(user.minimumComments)"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Stepper,
                text: labelText, value: Double(user.minimumComments))
        case 2:
            labelText =  "User Hidden Stories"
            let hiddenStories = HNStoryManager.sharedInstance().userHiddenStories() as NSArray
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Simple,
                text: labelText, value: Double(hiddenStories.count));
        default:
            assert(false, "There is a problem with the number of sections expected.")
        }
        headerView.delegate = self;
    }
    
    //MARK:- TableView Row Delegate Methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCellWithIdentifier("") as UITableViewCell?
            if  (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "")
            }
            return cell!
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath
        indexPath: NSIndexPath) -> Bool {
            return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle
        editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    //MARK:- SectionView Delegate Method
    
    func sectionStateDidChange(section: SectionHeaderView, open: Bool) {
        println("We are getting Open and CLOSE Notifications.")
    }
    
    func sectionValueDidChange(section: SectionHeaderView, value: Double) {
        println("We are getting notifications of changing values.")
    }
    
    //MARK:- Other
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}