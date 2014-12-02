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

class SettingsViewController : UITableViewController, SectionHeaderDelegate {
    //MARK:- Constants and Properties
    let headerIdentifier = "headerReuseIdentifier"
    let scoreSection:Int = 0
    let commentSection:Int = 1
    let sectionHeaderHeight:CGFloat = 48.0
    
    var sectionStateDictionary:[Int:Bool] = [0:false, 1:false, 2:false]
    var rowHeightDictionary = [NSNumber:CGFloat]()
    
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = AppDelegate.hackerBeige()
        
        let headerNib = UINib(nibName: "SectionHeader", bundle: nil)
        tableView.registerNib(headerNib, forHeaderFooterViewReuseIdentifier: headerIdentifier)
        
        weak var this = self;
        HNStoryManager.sharedInstance().rac_valuesForKeyPath("scoreFilteredStories", observer: self)
            .takeUntil(self.rac_willDeallocSignal())
            .combinePreviousWithStart(NSArray(), reduce: { (oldArray, newArray) -> AnyObject! in
                return RACTuple(objectsFromArray:[oldArray, newArray])
            }).subscribeNext { (t) -> Void in
                if this?.sectionStateDictionary[this!.scoreSection] == true {
                    this?.tableView.reloadSections(NSIndexSet(index: this!.scoreSection),
                        withRowAnimation: UITableViewRowAnimation.Automatic)
                }
        }
        
        HNStoryManager.sharedInstance().rac_valuesForKeyPath("commentFilteredStories", observer:self)
            .takeUntil(self.rac_willDeallocSignal())
            .combinePreviousWithStart(NSArray(), reduce: { (oldArray, newArray) -> AnyObject! in
                return RACTuple(objectsFromArray:[oldArray, newArray])
            }).subscribeNext { (t) -> Void in
                if this?.sectionStateDictionary[this!.commentSection] == true {
                    this?.tableView.reloadSections(NSIndexSet(index: this!.commentSection),
                        withRowAnimation: UITableViewRowAnimation.Automatic)
                }
        }
        
        NSNotificationCenter.defaultCenter()
            .rac_addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil)
            .takeUntil(rac_willDeallocSignal()).subscribeNext({ (x) -> Void in
                this?.rowHeightDictionary = [NSNumber:CGFloat]()
                this?.tableView.reloadData()
            })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        parentViewController?.title = "Filtered Stories"
    }
    
    //MARK:- View Lifecycle Helpers
    
    func updateChangedCells(cells:NSArray, section:Int) {
        for path in cells as [NSIndexPath] {
            let num = itemNumberForIndexPath(path)
            let item = HNStoryManager.sharedInstance().modelForItemNumber(num) as HNItem
            updateCell(num, item: item, section:section)
        }
    }
    
    func respondToItemUpdates() {
        weak var this = self
        HNStoryManager.sharedInstance().itemUpdates.filter { (tuple) -> Bool in
            return !self.currentSortedTopStories().containsObject((tuple as RACTuple!).first)
            }.subscribeNext { (tupleObject) -> Void in
                if let tuple = tupleObject as RACTuple! {
                    let number = tuple.first as NSNumber
                    let item = tuple.second as HNItem
                    for index in 0..<self.tableView.numberOfSections() {
                        if (this?.cellArrayForSection(index).containsObject(number) == true) {
                            this?.updateCell(number, item: item, section: index)
                        }
                    }
                }
        }
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
            labelText = "Scores less than \(Int(user.minimumScore))"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.Stepper,
                text: labelText, value: Double(user.minimumScore))
        case SettingsSectionType.Comments.rawValue:
            labelText =  "Comments less than \(Int(user.minimumComments))"
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
        }
        headerView.delegate = self;
    }
    
    //MARK:- TableView Row Delegate Methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  sectionStateDictionary[section] == true {
            return cellArrayForSection(section).count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView,
        heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            let number = self.itemNumberForIndexPath(indexPath)
            let story = HNStoryManager.sharedInstance().modelForItemNumber(number) as HNItem
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
    
    override func tableView(tableView: UITableView, willDisplayCell
        cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
            cell.backgroundColor = AppDelegate.hackerBeige()
    }
    
    //MARK:- Update Cell Methods
    
    func updateCell(number:NSNumber,item:HNItem, section:Int) {
        let newRowHeight = UITableViewCell.getCellHeightForStory(item, view: self.view)
        let oldRowHeight:CGFloat? = self.rowHeightDictionary[number];
        let indexPath = indexPathForItemNumber(number, section: section)
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        if  cell == nil && oldRowHeight == nil {
            rowHeightDictionary[number] = newRowHeight;
        } else if (cell != nil) && (newRowHeight == oldRowHeight) {
            updateCell(cell!, indexPath: indexPath, shimmer: true)
        } else if (newRowHeight != oldRowHeight) {
            rowHeightDictionary[number] = newRowHeight;
            self.tableView.reloadRowsAtIndexPaths([indexPathForItemNumber(number, section: section)],
                withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    func updateCell(cell:UITableViewCell, indexPath:NSIndexPath, shimmer:Bool) {
        let number = itemNumberForIndexPath(indexPath)
        let story = HNStoryManager.sharedInstance().modelForItemNumber(number)
        cell.prepareForHeadline(story.document.properties, path: indexPath)
        let placeholder = HNStoryManager.sharedInstance()
            .getPlaceholderAndFaviconForItemNumber(number) { (favicon) -> Void in
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
    
    //MARK:- SectionView Delegate Method
    
    func sectionStateDidChange(section: SectionHeaderView, open: Bool) {
        sectionStateDictionary[section.tag] = open
        if open {
            let indexPathsToInsert = NSMutableArray()
            for index in 0..<cellArrayForSection(section.tag).count {
                indexPathsToInsert.addObject(NSIndexPath(forRow: index, inSection: section.tag))
            }
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(indexPathsToInsert,
                withRowAnimation: UITableViewRowAnimation.Top)
            self.tableView.endUpdates()
        } else {
            let indexPathsToDelete = NSMutableArray()
            for index in 0..<cellArrayForSection(section.tag).count {
                indexPathsToDelete.addObject(NSIndexPath(forRow: index, inSection: section.tag))
            }
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths(indexPathsToDelete,
                withRowAnimation: UITableViewRowAnimation.Top)
            self.tableView.endUpdates()
        }
    }
    
    func sectionValueDidChange(section: SectionHeaderView, value: Double) {
        switch section.tag {
        case SettingsSectionType.Score.rawValue:
            HNStoryManager.sharedInstance()[HNFilterKeyScore] = NSNumber(double:value)
            
        case SettingsSectionType.Comments.rawValue:
            HNStoryManager.sharedInstance()[HNFilterKeyComments] = NSNumber(double:value)
        default:
            assert(false, "We should not have a switch higher thatn Score or Comments....")
        }
        let indexSet = NSIndexSet(index: section.tag)
        tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
    }
    
    //MARK:- UITableViewCell Editing
    
    override func tableView(tableView: UITableView, commitEditingStyle
        editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView,
        canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
            return indexPath.section == SettingsSectionType.User.rawValue
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath
        indexPath: NSIndexPath) -> [AnyObject]? {
            var rowActions = [AnyObject]()
            weak var this = self
            let unhide = UITableViewRowAction(style: UITableViewRowActionStyle.Normal,
                title: "Unhide", handler: { (rowAction, indexPath) -> Void in
                    Flurry.logEvent("Unhide")
                    if let number:NSNumber = this?.itemNumberForIndexPath(indexPath) {
                        this?.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                        this?.tableView.beginUpdates()
                        HNStoryManager.sharedInstance().unhideStory(number)
                        this?.tableView.deleteRowsAtIndexPaths([indexPath],
                            withRowAnimation: UITableViewRowAnimation.Automatic)
                        this?.tableView.endUpdates()
                        let rows = this?.tableView.indexPathsForVisibleRows()!
                        for path:NSIndexPath! in rows as [NSIndexPath] {
                            if let cell = this?.tableView.cellForRowAtIndexPath(path) {
                                this?.updateCell(cell, indexPath: path, shimmer: false)
                            }
                        }
                    }
            })
            unhide.backgroundColor = AppDelegate.hackerOrange()
            rowActions.append(unhide)
            return rowActions
    }
    
    override func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let itemNumber = itemNumberForIndexPath(indexPath)
            let story = HNStoryManager.sharedInstance().modelForItemNumber(itemNumber) as HNItem
            if  story.type as NSString == "story" {
                if !(story.url as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewControllerWithIdentifier("WebViewController")
                        as WebViewController
                    controller.story = story
                    parentViewController?.navigationController?
                        .pushViewController(controller, animated: true)
                } else if !(story.text as NSString == "") {
                    performSegueWithIdentifier("textViewSegue", sender: story)
                }
            } else if  story.type as NSString == "job" {
                if !(story.text as NSString == "") {
                    performSegueWithIdentifier("textViewSegue", sender: story)
                } else if !(story.url as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewControllerWithIdentifier("WebViewController")
                        as WebViewController
                    controller.story = story
                    parentViewController?.navigationController?
                        .pushViewController(controller, animated: true)
                }
            }
            tableView .deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    //MARK:- Helpers
    
    func itemNumberForIndexPath(path:NSIndexPath) -> NSNumber {
        return cellArrayForSection(path.section).objectAtIndex(path.row) as NSNumber;
    }
    
    func indexPathForItemNumber(itemNumber:NSNumber, section:Int) -> NSIndexPath {
        return NSIndexPath(forRow: cellArrayForSection(section).indexOfObject(itemNumber),
            inSection: section);
    }
    
    func cellArrayForSection(section:Int)-> NSArray {
        switch section {
        case SettingsSectionType.Score.rawValue:
            return scoreFilteredStories()
        case SettingsSectionType.Comments.rawValue:
            return commmentFilteredStories()
        case SettingsSectionType.User.rawValue:
            return userHiddenStories()
        default:
            assert(false, "something is horribly wrong. Why are you asking for an unknown filter?")
            return NSArray()
        }
    }
    
    func userHiddenStories() -> NSArray {
        return HNStoryManager.sharedInstance().userHiddenStories() as NSArray
    }
    
    func scoreFilteredStories() -> NSArray {
        return HNStoryManager.sharedInstance().scoreFilteredStories as NSArray
    }
    
    func commmentFilteredStories() -> NSArray {
        return HNStoryManager.sharedInstance().commentFilteredStories as NSArray
    }
    
    func currentSortedTopStories() -> NSArray {
        return HNStoryManager.sharedInstance().currentTopStories;
    }
    
    //MARK:- Other
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}