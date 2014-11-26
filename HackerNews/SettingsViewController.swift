//
//  SettingsViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/24/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

enum SettingsSectionType:Int {
    case Score = 0, Comments, User
}

class SettingsViewController : HNSettingsViewController, SectionHeaderDelegate {
    let headerIdentifier = "headerReuseIdentifier"
    let sectionHeaderHeight:CGFloat = 48.0
    var sectionStateDictionary = [Int:Bool]()
    var rowHeightDictionary = [NSNumber:CGFloat]()
    
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = AppDelegate.hackerBeige()
        
        let headerNib = UINib(nibName: "SectionHeader", bundle: nil)
        tableView.registerNib(headerNib, forHeaderFooterViewReuseIdentifier: headerIdentifier)
        weak var this = self;
        NSNotificationCenter.defaultCenter()
            .rac_addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil)
            .takeUntil(rac_willDeallocSignal()).subscribeNext({ (x) -> Void in
                this?.rowHeightDictionary = [NSNumber:CGFloat]()
                this?.tableView.reloadData()
            })
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
        case SettingsSectionType.Score.rawValue:
            labelText = "Minimum Score: \(user.minimumScore)"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Stepper,
                text: labelText, value: Double(user.minimumScore))
        case SettingsSectionType.Comments.rawValue:
            labelText =  "Minimum Comments: \(user.minimumComments)"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Stepper,
                text: labelText, value: Double(user.minimumComments))
        case SettingsSectionType.User.rawValue:
            labelText =  "User Hidden Stories"
            let hiddenStories = HNStoryManager.sharedInstance().userHiddenStories() as NSArray
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Simple,
                text: labelText, value: Double(hiddenStories.count));
        default:
            assert(false, "There is a problem with the number of sections expected.")
        }
        
        if let state = sectionStateDictionary[sectionNumber] {
            headerView.setState(state)
        } else {
            sectionStateDictionary[sectionNumber] = false
            headerView.setState(false)
        }
        headerView.delegate = self;
    }
    
    //MARK:- TableView Row Delegate Methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  sectionStateDictionary[section] == true {
            switch section {
            case 2:
                let hiddenStories = HNStoryManager.sharedInstance().userHiddenStories() as NSArray
                return hiddenStories.count
            default: return 0
            }
        }
        return 0
    }
    
    override func tableView(tableView: UITableView,
        heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            let number = self .itemNumberForIndexPath(indexPath)
            let story = HNStoryManager.sharedInstance().modelForItemNumber(number) as HNStory
            var rowHeight:CGFloat? = rowHeightDictionary[number]
            if rowHeight == nil {
                rowHeight = UITableViewCell.getCellHeightForStory(story, view: view)
            }
            return rowHeight!;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCellWithIdentifier("") as UITableViewCell?
            if  (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "")
            }
            updateCell(cell!, indexPath: indexPath, shimmer: false)
            return cell!
    }
    
    func updateCell(cell:UITableViewCell, indexPath:NSIndexPath, shimmer:Bool) {
        let number = itemNumberForIndexPath(indexPath)
        let story = HNStoryManager.sharedInstance().modelForItemNumber(number)
        cell.prepareForHeadline(story.document.properties, path: indexPath)
        let placeholder = HNStoryManager.sharedInstance().getPlaceholderAndFaviconForItemNumber(number) { (favicon) -> Void in
            if (favicon != nil) {
                let indexPath = self.indexPathForItemNumber(number, section:indexPath.section)
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)
                cell?.setFavicon(favicon)
            }
        }
        cell.setFavicon(placeholder)
        if shimmer {
            cell.shimmerFor(1.0)
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = AppDelegate.hackerBeige()
    }
    
    //MARK:- SectionView Delegate Method
    
    func sectionStateDidChange(section: SectionHeaderView, open: Bool) {
        sectionStateDictionary[section.tag] = open
        if open {
            let indexPathsToInsert = NSMutableArray()
            for index in 0..<userHiddenStories().count {
                indexPathsToInsert.addObject(NSIndexPath(forRow: index, inSection: section.tag))
            }
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: UITableViewRowAnimation.Top)
            self.tableView.endUpdates()
        } else {
            let indexPathsToDelete = NSMutableArray()
            for index in 0..<userHiddenStories().count {
                indexPathsToDelete.addObject(NSIndexPath(forRow: index, inSection: section.tag))
            }
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: UITableViewRowAnimation.Top)
            self.tableView.endUpdates()
        }
        
        println("We are getting Open and CLOSE Notifications.")
    }
    
    func sectionValueDidChange(section: SectionHeaderView, value: Double) {
        println("We are getting notifications of changing values.")
        
    }
    
    //MARK:- UITableViewCell Editing
    
    override func tableView(tableView: UITableView, commitEditingStyle
        editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView,
        canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
            return indexPath.section == SettingsSectionType.User.rawValue
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var rowActions = [AnyObject]()
        weak var this = self
        let unhide = UITableViewRowAction(style: UITableViewRowActionStyle.Normal,
            title: "Unhide", handler: { (rowAction, indexPath) -> Void in
                Flurry.logEvent("Unhide")
                if let number:NSNumber = this?.itemNumberForIndexPath(indexPath) {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    self.tableView.beginUpdates()
                    HNStoryManager.sharedInstance().unhideStory(number)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.tableView.endUpdates()
                    let rows = this?.tableView.indexPathsForVisibleRows()!
                    for path:NSIndexPath! in rows as [NSIndexPath] {
                        if let cell = this?.tableView.cellForRowAtIndexPath(path) {
                            this?.updateCell(cell, indexPath: path, shimmer: false)
                        }
                    }
                }
        })
        unhide.backgroundColor = WSMColorPalette.colorGradient(WSMColorGradient.GradientGreen,
            forIndex: 0, ofCount: 0, reversed: false)
        rowActions.append(unhide)
        return rowActions
    }
    
    //MARK:- Helpers
    
    func itemNumberForIndexPath(path:NSIndexPath) -> NSNumber {
        var itemNumber:NSNumber
        switch path.section {
        case SettingsSectionType.Score.rawValue:
            itemNumber = 0
        case SettingsSectionType.Comments.rawValue:
            itemNumber = 0
        case SettingsSectionType.User.rawValue:
            itemNumber = self.userHiddenStories().objectAtIndex(path.row) as NSNumber
        default:
            itemNumber = 0
        }
        return itemNumber;
    }
    
    func indexPathForItemNumber(itemNumber:NSNumber, section:Int) -> NSIndexPath {
        var path:NSIndexPath
        switch section {
        case SettingsSectionType.Score.rawValue:
            path = NSIndexPath(forRow: 0, inSection: section)
        case SettingsSectionType.Comments.rawValue:
            path = NSIndexPath(forRow: 0, inSection: section)
        case SettingsSectionType.User.rawValue:
            path = NSIndexPath(forRow: self.userHiddenStories().indexOfObject(itemNumber),
                inSection: section)
        default:
            path = NSIndexPath(forRow: 0, inSection: section)
        }
        return path;
    }
    
    func userHiddenStories() -> NSArray {
        return HNStoryManager.sharedInstance().userHiddenStories() as NSArray
    }
    
    
    //MARK:- Other
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}