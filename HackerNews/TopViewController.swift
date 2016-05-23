//
//  TopViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/9/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class TopViewController: HNTopViewController {
    //MARK:- Constants & Properties
    let NEWS_SECTION = 0
    let CELL_IDENTIFIER = "storyCell"
    @IBOutlet var topStoriesBarItem: UITabBarItem!
    var titleView:UISegmentedControl?
    
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        tableView.backgroundColor = AppDelegate.hackerBeige()
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
                if let s = stories as! NSArray! {
                    this?.topStoriesBarItem.badgeValue = "\(s.count)"
                }
        }
        
        HNStoryManager.sharedInstance().rac_valuesForKeyPath("currentTopStories", observer: self)
            .takeUntil(self.rac_willDeallocSignal())
            .combinePreviousWithStart(NSArray(), reduce: { (oldArray, newArray) -> AnyObject! in
                return RACTuple(objectsFromArray:[oldArray, newArray])
            }).subscribeNext { (t) -> Void in
                if let tuple = t as! RACTuple! {
                    tuple.first as! NSArray
                    let first = tuple.first as! NSArray
                    let second = tuple.second as! NSArray
                    let changedCells = UITableViewController.tableView(self.tableView,
                        updateSection: this!.NEWS_SECTION, previous: first as [AnyObject], current: second as [AnyObject]) as NSArray
                    var reload = false;
                    for path in changedCells as! [NSIndexPath] {
                        let number = this?.itemNumberForIndexPath(path)
                        let item = HNStoryManager.sharedInstance().modelForItemNumber(number) as! HNItem
                        if let _ = this?.updateCellWithTuple(RACTuple(objectsFromArray:[number!, item])) {
                            reload = true;
                        }
                    }
                    if  reload {
                        this?.tableView.reloadSections(NSIndexSet(index: this!.NEWS_SECTION),
                            withRowAnimation: UITableViewRowAnimation.None)
                    }
                }
        }
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        formatTitleView()
        parentViewController?.navigationController?.hidesBarsOnSwipe = false
        parentViewController?.navigationController?.hidesBarsOnTap = false
        respondToItemUpdates()
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
        parentViewController?.title = "Top Stories"
        if !(parentViewController?.navigationItem.titleView is UISegmentedControl) {
            if let segControl = titleView {
                parentViewController?.navigationItem.titleView = segControl
            } else {
                titleView = UISegmentedControl(items:["Points", "Rank", "Comments"])
                switch HNStoryManager.sharedInstance().sortStyle {
                case HNSortStyle.Comments: titleView!.selectedSegmentIndex = 2
                case HNSortStyle.Points: titleView!.selectedSegmentIndex = 0
                default: titleView!.selectedSegmentIndex = 1
                }
                titleView!.autoresizingMask = [.FlexibleWidth , .FlexibleHeight]
                titleView!.frame = CGRectMake(0, 0, self.view.frame.width, 30)
                titleView!.addTarget(self, action: #selector(self.sortCategory(_:)),
                    forControlEvents: UIControlEvents.ValueChanged)
                parentViewController?.navigationItem.titleView = titleView!
                titleView!.sizeToFit()
            }
        }
    }
    
    func sortCategory(segmentedControl:UISegmentedControl) {
        _ = currentSortedTopStories
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HNStoryManager.sharedInstance().currentTopStories.count
    }
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell?
            if (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle,
                    reuseIdentifier: CELL_IDENTIFIER)
            }
            updateCell(cell, atIndexPath: indexPath, shimmer: false)
            return cell!
    }
    
    override func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let itemNumber = itemNumberForIndexPath(indexPath)
            let story = HNStoryManager.sharedInstance().modelForItemNumber(itemNumber) as! HNItem
            if  story.type as NSString == "story" {
                if !(story.url as NSString == "")  {
                    let controller = storyboard?
                        .instantiateViewControllerWithIdentifier("WebViewController")
                        as! WebViewController
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
                        as! WebViewController
                    controller.story = story
                    parentViewController?.navigationController?
                        .pushViewController(controller, animated: true)
                }
            }
            tableView .deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            cell.backgroundColor = AppDelegate.hackerBeige()
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
            let controller = segue.destinationViewController as! TextViewController
            controller.story = sender as? HNStory;
        }
    }

    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        Flurry.logEvent("MemoryWarning")
        super.didReceiveMemoryWarning()
    }
}
