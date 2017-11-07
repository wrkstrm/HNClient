//
//  SettingsViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/24/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

enum SettingsSectionType:Int {
    case score = 0, comments, user
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
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: headerIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        parent?.title = "Filtered Stories"

    }
    
    override func viewDidAppear(_ animated: Bool) {
        weak var this = self;
        HNStoryManager.shared.rac_values(forKeyPath: "commentFilteredStories", observer:self)
            .take(until: self.rac_signal(for: #selector(UIViewController.viewDidDisappear(_:))))
            .throttle(1)
            .subscribeNext { (t) -> Void in
                this?.tableView.reloadData()
                return
                }


        NotificationCenter.default
            .rac_addObserver(forName: NSNotification.Name.UIContentSizeCategoryDidChange.rawValue, object: nil)
            .take(until: self.rac_signal(for: #selector(UIViewController.viewDidDisappear(_:))))
            .subscribeNext({ (x) -> Void in
                this?.rowHeightDictionary = [NSNumber:CGFloat]()
                this?.tableView.reloadData()
            })
    }
    //MARK:- View Lifecycle Helpers
    
    func updateChangedCells(_ cells:NSArray, section:Int) {
        for path in cells as! [IndexPath] {
            let num = itemNumberForIndexPath(path)
            let item = HNStoryManager.shared.model(forItemNumber: num) as! HNItem
            updateCell(num, item: item, section:section)
        }
    }
    
    func respondToItemUpdates() {
        weak var this = self
        HNStoryManager.shared.itemUpdates.filter { (tuple) -> Bool in
            return !self.currentSortedTopStories().contains((tuple as! NSArray).firstObject!)
            }.subscribeNext { (tupleObject) -> Void in
                if let tuple = tupleObject as? NSArray {
                    let number = tuple.firstObject as! NSNumber
                    let item = tuple.lastObject as! HNItem
                    for index in 0..<self.tableView.numberOfSections {
                        if (this?.cellArrayForSection(index).contains(number) == true) {
                            this?.updateCell(number, item: item, section: index)
                        }
                    }
                }
        }
    }
    
    //MARK:- TableView Section Delegate Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3;
    }
    
    override func tableView(_ tableView: UITableView,
        heightForHeaderInSection section: Int) -> CGFloat {
            return sectionHeaderHeight;
    }
    
    override func tableView(_ tableView: UITableView,
        viewForHeaderInSection section: Int) -> UIView? {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerIdentifier) as! SectionHeaderView
            configureSectionHeader(header, sectionNumber: section)
            return header
    }
    
    func configureSectionHeader(_ headerView:SectionHeaderView, sectionNumber:Int) {
        let  user = HNStoryManager.shared.currentUser
        var labelText:String
        switch sectionNumber {
        case SettingsSectionType.score.rawValue:
            labelText = "Scores less than \(Int((user.minimumScore)))"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.stepper,
                text: labelText, value: Double(user.minimumScore))
        case SettingsSectionType.comments.rawValue:
            labelText =  "Comments less than \(Int((user.minimumComments)))"
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.stepper,
                text: labelText, value: Double(user.minimumComments))
        case SettingsSectionType.user.rawValue:
            labelText =  "User Hidden Stories"
            let hiddenStories = HNStoryManager.shared.userHiddenStories()
            headerView.prepareForSection(sectionNumber, type: SectionHeaderType.simple,
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  sectionStateDictionary[section] == true {
            return cellArrayForSection(section).count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView,
        heightForRowAt indexPath: IndexPath) -> CGFloat {
            let number = self.itemNumberForIndexPath(indexPath)
            let story = HNStoryManager.shared.model(forItemNumber: number) as! HNItem
            var rowHeight:CGFloat? = rowHeightDictionary[number]
            if rowHeight == nil {
                rowHeight = UITableViewCell.getHeightForStory(story, view: view)
            }
            return rowHeight!;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt
        indexPath: IndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCell(withIdentifier: "") as UITableViewCell?
            if  (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "")
            }
            updateCell(cell!, indexPath: indexPath, shimmer: false)
            return cell!
    }
    
    override func tableView(_ tableView: UITableView, willDisplay
        cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            cell.backgroundColor = AppDelegate.hackerBeige()
    }
    
    //MARK:- Update Cell Methods
    
    func updateCell(_ number:NSNumber,item:HNItem, section:Int) {
        let newRowHeight = UITableViewCell.getHeightForStory(item, view: self.view)
        let oldRowHeight:CGFloat? = self.rowHeightDictionary[number];
        let indexPath = indexPathForItemNumber(number, section: section)
        let cell = self.tableView.cellForRow(at: indexPath)
        if  cell == nil && oldRowHeight == nil {
            rowHeightDictionary[number] = newRowHeight;
        } else if (cell != nil) && (newRowHeight == oldRowHeight) {
            updateCell(cell!, indexPath: indexPath, shimmer: true)
        } else if (newRowHeight != oldRowHeight) {
            rowHeightDictionary[number] = newRowHeight;
            self.tableView.reloadRows(at: [indexPathForItemNumber(number, section: section)],
                with: UITableViewRowAnimation.none)
        }
    }
    
    func updateCell(_ cell:UITableViewCell, indexPath:IndexPath, shimmer:Bool) {
        let number = itemNumberForIndexPath(indexPath)
        let story = HNStoryManager.shared.model(forItemNumber: number)
        cell.prepare(forHeadline: story.document.properties, path: indexPath)
        let placeholder = HNStoryManager.shared
            .getPlaceholderAndFavicon(forItemNumber: number) { (favicon) -> Void in
                if (favicon != nil) {
                    let indexPath = self.indexPathForItemNumber(number, section:(indexPath as NSIndexPath).section)
                    let cell = self.tableView.cellForRow(at: indexPath)
                    cell?.setFavicon(favicon)
                }
        }
        cell.setFavicon(placeholder)
        if shimmer {
            cell.shimmer(for: 1.0)
        }
    }
    
    //MARK:- SectionView Delegate Method
    
    func sectionStateDidChange(_ section: SectionHeaderView, open: Bool) {
        sectionStateDictionary[section.tag] = open
        if open {
            var indexPathsToInsert = Array<IndexPath>()
            for index in 0..<cellArrayForSection(section.tag).count {
                indexPathsToInsert.append(IndexPath(row: index, section: section.tag))
            }
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: indexPathsToInsert, with: .top)
            self.tableView.endUpdates()
        } else {
            var indexPathsToDelete = [IndexPath]()
            for index in 0..<cellArrayForSection(section.tag).count {
                indexPathsToDelete.append(IndexPath(row: index, section: section.tag))
            }
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: indexPathsToDelete,
                with: UITableViewRowAnimation.top)
            self.tableView.endUpdates()
        }
    }
    
    func sectionValueDidChange(_ section: SectionHeaderView, value: Double) {
        switch section.tag {
        case SettingsSectionType.score.rawValue:
            HNStoryManager.shared[HNFilterKeyScore] = NSNumber(value: value as Double)
            
        case SettingsSectionType.comments.rawValue:
            HNStoryManager.shared[HNFilterKeyComments] = NSNumber(value: value as Double)
        default:
            assert(false, "We should not have a switch higher thatn Score or Comments....")
        }
        let indexSet = IndexSet(integer: section.tag)
        tableView.reloadSections(indexSet, with: UITableViewRowAnimation.none)
    }
    
    //MARK:- UITableViewCell Editing
    
    override func tableView(_ tableView: UITableView, commit
        editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView,
        canEditRowAt indexPath: IndexPath) -> Bool {
            return (indexPath as NSIndexPath).section == SettingsSectionType.user.rawValue
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
            var rowActions = [UITableViewRowAction]()
            weak var this = self
            let unhide = UITableViewRowAction(style: UITableViewRowActionStyle.normal,
                title: "Unhide", handler: { (rowAction, indexPath) -> Void in
                    FIRAnalytics.logEvent(withName: "Unhide", parameters:nil)
                    if let number:NSNumber = this?.itemNumberForIndexPath(indexPath) {
                        this?.tableView.deselectRow(at: indexPath, animated: true)
                        this?.tableView.beginUpdates()
                        HNStoryManager.shared.unhideStory(number)
                        this?.tableView.deleteRows(at: [indexPath],
                            with: UITableViewRowAnimation.automatic)
                        this?.tableView.endUpdates()
                        let rows = this?.tableView.indexPathsForVisibleRows
                        for path:IndexPath! in rows! {
                            if let cell = this?.tableView.cellForRow(at: path) {
                                this?.updateCell(cell, indexPath: path, shimmer: false)
                            }
                        }
                    }
            })
            unhide.backgroundColor = AppDelegate.hackerOrange()
            rowActions.append(unhide)
            return rowActions
    }
    
    override func tableView(_ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath) {
            let itemNumber = itemNumberForIndexPath(indexPath)
            let story = HNStoryManager.shared.model(forItemNumber: itemNumber) as! HNItem
            if  story.type as NSString == "story" {
                if !(story.url as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewController(withIdentifier: "WebViewController")
                        as! WebViewController
                    controller.story = story
                    parent?.navigationController?
                        .pushViewController(controller, animated: true)
                } else if !(story.text as NSString == "") {
                    performSegue(withIdentifier: "textViewSegue", sender: story)
                }
            } else if  story.type as NSString == "job" {
                if !(story.text as NSString == "") {
                    performSegue(withIdentifier: "textViewSegue", sender: story)
                } else if !(story.url as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewController(withIdentifier: "WebViewController")
                        as! WebViewController
                    controller.story = story
                    parent?.navigationController?
                        .pushViewController(controller, animated: true)
                }
            }
            tableView .deselectRow(at: indexPath, animated: true);
    }
    
    //MARK:- Helpers
    
    func itemNumberForIndexPath(_ path:IndexPath) -> NSNumber {
        return cellArrayForSection((path as NSIndexPath).section).object(at: (path as NSIndexPath).row) as! NSNumber;
    }
    
    func indexPathForItemNumber(_ itemNumber:NSNumber, section:Int) -> IndexPath {
        return IndexPath(row: cellArrayForSection(section).index(of: itemNumber),
            section: section);
    }
    
    func cellArrayForSection(_ section:Int)-> NSArray {
        switch section {
        case SettingsSectionType.score.rawValue:
            return scoreFilteredStories()
        case SettingsSectionType.comments.rawValue:
            return commmentFilteredStories()
        case SettingsSectionType.user.rawValue:
            return userHiddenStories()
        default:
            assert(false, "something is horribly wrong. Why are you asking for an unknown filter?")
            return NSArray()
        }
    }
    
    func userHiddenStories() -> NSArray {
        return HNStoryManager.shared.userHiddenStories() as NSArray
    }
    
    func scoreFilteredStories() -> NSArray {
        return HNStoryManager.shared.scoreFilteredStories as NSArray
    }
    
    func commmentFilteredStories() -> NSArray {
        return HNStoryManager.shared.commentFilteredStories as NSArray
    }
    
    func currentSortedTopStories() -> NSArray {
        return HNStoryManager.shared.currentTopStories as NSArray;
    }
    
    //MARK:- Other
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
