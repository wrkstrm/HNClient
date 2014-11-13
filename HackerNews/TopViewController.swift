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
        let delegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.topStoriesAPI = delegate.hackerAPI.childByAppendingPath("topstories")
        self.itemsAPI = delegate.hackerAPI.childByAppendingPath("item")
        weak var this = self
        NSNotificationCenter.defaultCenter()
            .rac_addObserverForName(UIContentSizeCategoryDidChangeNotification, object: nil)
            .takeUntil(rac_willDeallocSignal()).subscribeNext({ (x) -> Void in
                this?.rowHeightDictionary = nil
                this?.tableView.reloadData()
            })
        rac_valuesForKeyPath("currentSortedTopStories", observer: self)
            .takeUntil(rac_willDeallocSignal())
            .subscribeNext { (stories) -> Void in
                if let s = stories as NSMutableArray! {
                    this?.topStoriesBarItem.badgeValue = "\(s.count)"
                }
        }
        removeOldObservations()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        formatTitleView()
        parentViewController?.navigationController?.hidesBarsOnSwipe = false
        parentViewController?.navigationController?.hidesBarsOnTap = false
        weak var this = self
        self.topStoriesAPI.observeEventType(FEventType.Value, withBlock: { (snapshot) -> Void in
            var previousSorted = this?.currentSortedTopStories
            if let stories = snapshot.value as NSArray! {
                this?.topStoriesDocument.mergeUserProperties(["stories":stories], error: nil)
                this?.currentSortedTopStories = this?.arrayWithCurrentSortFilter()
                this?.updateTableView(previousSorted, current: this?.currentSortedTopStories)
                this?.topStoriesSubject.sendNext(this?.currentSortedTopStories)
            }
        })
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        for path in tableView.indexPathsForVisibleRows() as [NSIndexPath] {
            observeAndGetDocumentForItem(itemNumberForIndexPath(path))
        }
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        parentViewController?.navigationItem.titleView = nil;
        self.topStoriesAPI.removeAllObservers()
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Lifecycle Helpers
    
    func formatTitleView() {
        let segmentedControl = UISegmentedControl(items:["Points", "Rank", "Comments"])
        switch sortStyle {
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
        case 0: sortStyle = HNSortStyle.Points
        case 1: sortStyle = HNSortStyle.Rank
        case 2: sortStyle = HNSortStyle.Comments
        default: assert(false, "Incorrect Sorting State")
        }
        currentSortedTopStories = nil
        updateTableView(previousSorted, current: currentSortedTopStories)
    }
    
    //MARK:- TableView Delegate Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    let CELL_IDENTIFIER = "storyCell"
    
    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell?
            if (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle,
                    reuseIdentifier: CELL_IDENTIFIER)
            }
            
            let itemNumber = itemNumberForIndexPath(indexPath)
            let properties = observeAndGetDocumentForItem(itemNumber).properties
            let faviconURL = cacheFaviconForItem(itemNumber, url:properties["url"] as NSString?)
            cell?.prepareForHeadline(properties,
                iconData:faviconCache[faviconURL] as NSData?, path: indexPath)
            return cell!
    }
    
    override func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let itemNumber = itemNumberForIndexPath(indexPath)
            let document = newsDatabase.documentWithID(itemNumber.stringValue)
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
            }
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
