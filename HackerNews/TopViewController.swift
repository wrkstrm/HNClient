//
//  TopViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/9/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class TopViewController: HNTopViewController {
    @IBOutlet var topStoriesBarItem: UITabBarItem!
    
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        tableView.backgroundColor = self.hackerBeige()
        weak var this = self
        NSNotificationCenter.defaultCenter()
            .rac_addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil)
            .takeUntil(rac_willDeallocSignal()).subscribeNext({ (x) -> Void in
                this?.rowHeightDictionary = nil
                this?.tableView.reloadData()
            })
        HNStoryManager.sharedInstance()
            .rac_valuesForKeyPath("currentTopStories", observer: self)
            .takeUntil(rac_willDeallocSignal())
            .subscribeNext { (stories) -> Void in
                if let s = stories as NSArray! {
                    this?.topStoriesBarItem.badgeValue = "\(s.count)"
                }
        }
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        formatTitleView()
        parentViewController?.navigationController?.hidesBarsOnSwipe = false
        parentViewController?.navigationController?.hidesBarsOnTap = false
        weak var this = self
        HNStoryManager.sharedInstance().rac_valuesForKeyPath("currentTopStories", observer: self)
            .takeUntil(self.rac_willDeallocSignal())
            .combinePreviousWithStart(NSArray(), reduce: { (oldArray, newArray) -> AnyObject! in
                return RACTuple(objectsFromArray: [oldArray, newArray])
            }).subscribeNext { (t) -> Void in
                if let tuple = t as RACTuple! {
                    self.updateTableView(tuple.first as NSArray, current: tuple.second as NSArray)
                }
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        parentViewController?.navigationItem.titleView = nil;
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Lifecycle Helpers
    
    func formatTitleView() {
        let segmentedControl = UISegmentedControl(items:["Points", "Rank", "Comments"])
        switch HNStoryManager.sharedInstance().sortStyle {
        case HNSortStyle.Comments: segmentedControl.selectedSegmentIndex = 2
        case HNSortStyle.Points: segmentedControl.selectedSegmentIndex = 0
        default: segmentedControl.selectedSegmentIndex = 1
        }
        segmentedControl.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        segmentedControl.frame = CGRectMake(0, 0, 200, 30)
        segmentedControl.addTarget(self, action: "sortCategory:",
            forControlEvents: UIControlEvents.ValueChanged)
        parentViewController?.navigationItem.titleView = segmentedControl
    }
    
    func sortCategory(segmentedControl:UISegmentedControl) {
        let previousSorted = currentSortedTopStories
        switch (segmentedControl.selectedSegmentIndex) {
        case 0: HNStoryManager.sharedInstance().sortStyle = HNSortStyle.Points
        case 1: HNStoryManager.sharedInstance().sortStyle = HNSortStyle.Rank
        case 2: HNStoryManager.sharedInstance().sortStyle = HNSortStyle.Comments
        default: assert(false, "Incorrect Sorting State")
        }
    }
    
    //MARK:- TableView Delegate Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    let CELL_IDENTIFIER = "storyCell"
    
    //    override func tableView(tableView: UITableView,
    //        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    //            var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell?
    //            if (cell == nil) {
    //                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle,
    //                    reuseIdentifier: CELL_IDENTIFIER)
    //            }
    //            let itemNumber = itemNumberForIndexPath(indexPath)
    //            let signal = HNStoryManager.sharedInstance().latestStateForItemNumber(itemNumber)
    //            weak var this = self;
    //            signal.takeUntil(cell?.rac_prepareForReuseSignal).subscribeNext { (tuple) -> Void in
    //                if let t = tuple as RACTuple! {
    //                    let document = t.first as CBLDocument!
    //                    let image = HNStoryManager.sharedInstance().faviconForKey(t.second as NSString!)
    //                    let path = this?.indexPathForItemNumber(itemNumber)
    //                    cell?.prepareForHeadline(document.properties, image: image, path: path)
    //                }
    //            }
    //            return cell!
    //    }
    
    override func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let itemNumber = itemNumberForIndexPath(indexPath)
            let document = HNStoryManager.sharedInstance().documentForItemNumber(itemNumber)
            if  document["type"] as NSString == "story" {
                if !(document["url"] as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewControllerWithIdentifier("WebViewController")
                        as WebViewController
                    controller.document = document
                    parentViewController?.navigationController?
                        .pushViewController(controller, animated: true)
                } else if !(document["text"] as NSString == "") {
                    performSegueWithIdentifier("textViewSegue", sender: document)
                }
            } else if  document["type"] as NSString == "job" {
                if !(document["text"] as NSString == "") {
                    performSegueWithIdentifier("textViewSegue", sender: document)
                } else if !(document["url"] as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewControllerWithIdentifier("WebViewController")
                        as WebViewController
                    controller.document = document
                    parentViewController?.navigationController?
                        .pushViewController(controller, animated: true)
                }
            }
            tableView .deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            cell.backgroundColor = hackerBeige()
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle
        editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    //MARK:- Rotation
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection,
        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            weak var this = self
            coordinator.animateAlongsideTransition({ ( context) -> Void in
                this?.rowHeightDictionary = nil
                this?.tableView.reloadData()
                }, completion: { (context) -> Void in })
    }
    
    //MARK:- Transition
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "textViewSegue" {
            let controller = segue.destinationViewController as TextViewController
            controller.document = sender as CBLDocument!;
        }
    }
    
    //MARK:- Helper Methods
    
    func hackerBeige() -> UIColor  {
        return SKColorMakeRGB(245.0, 245.0, 238.0)
    }
    
    func hackerOrange() -> UIColor {
        return SKColorMakeRGB(255.0, 102.0, 0.0)
    }
    
    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        Flurry.logEvent("MemoryWarning")
    }
}
