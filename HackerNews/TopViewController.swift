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
        NotificationCenter.default
            .rac_addObserver(forName: NSNotification.Name.UIContentSizeCategoryDidChange.rawValue, object: nil)
            .take(until: rac_willDeallocSignal()).subscribeNext({ (x) -> Void in
                this?.rowHeightDictionary = nil
                this?.tableView.reloadData()
            })
        HNStoryManager.shared.rac_values(forKeyPath: "currentTopStories", observer: self)
            .take(until: rac_willDeallocSignal())
            .subscribeNext { (stories) -> Void in
                if let s = stories as! NSArray! {
                    this?.topStoriesBarItem.badgeValue = "\(s.count)"
                }
        }
        //
//        HNStoryManager.shared.rac_valuesForKeyPath("currentTopStories", observer: self)
//        .takeUntil(self.rac_willDeallocSignal())
//
//        .combinePreviousWithStart(NSArray()) { (oldA, newA) -> AnyObject! in
//            return NSArray(array: [oldA, newA])
//        }


        HNStoryManager.shared.rac_values(forKeyPath: "currentTopStories", observer: self)
            .take(until: self.rac_willDeallocSignal())
            .combinePrevious(withStart: NSArray(), reduce: { (oldArray, newArray) -> AnyObject! in
                return NSArray(array:[oldArray ?? [], newArray ?? []])
            }).subscribeNext { (t) -> Void in
                if let tuple = t as! NSArray! {
                    let first = tuple.firstObject as! NSArray
                    let second = tuple.lastObject as! NSArray
                    let changedCells = UITableViewController.tableView(self.tableView,
                        updateSection: this!.NEWS_SECTION, previous: first as [AnyObject], current: second as [AnyObject]) as NSArray
                    var reload = false;
                    for path in changedCells as! [IndexPath] {
                        let number = this?.itemNumber(for: path)
                        let item = HNStoryManager.shared.model(forItemNumber: number!) as! HNItem
                        if let _ = this?.updateCell(withTuple: NSArray(array:[number!, item]) as [AnyObject]) {
                            reload = true;
                        }
                    }
                    if  reload {
                        this?.tableView.reloadSections(IndexSet(integer: this!.NEWS_SECTION),
                            with: UITableViewRowAnimation.none)
                    }
                }
        }
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        formatTitleView()
        parent?.navigationController?.hidesBarsOnSwipe = false
        parent?.navigationController?.hidesBarsOnTap = false
        respondToItemUpdates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        parent?.navigationItem.titleView = nil;
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Lifecycle Helpers
    
    func formatTitleView() {
        parent?.title = "Top Stories"
        if !(parent?.navigationItem.titleView is UISegmentedControl) {
            if let segControl = titleView {
                parent?.navigationItem.titleView = segControl
            } else {
                titleView = UISegmentedControl(items:["Points", "Rank", "Comments"])
                switch HNStoryManager.shared.sortStyle {
                case HNSortStyle.comments: titleView!.selectedSegmentIndex = 2
                case HNSortStyle.points: titleView!.selectedSegmentIndex = 0
                default: titleView!.selectedSegmentIndex = 1
                }
                titleView!.autoresizingMask = [.flexibleWidth , .flexibleHeight]
                titleView!.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30)
                titleView!.addTarget(self, action: #selector(self.sortCategory(_:)),
                    for: UIControlEvents.valueChanged)
                parent?.navigationItem.titleView = titleView!
                titleView!.sizeToFit()
            }
        }
    }
    
    func sortCategory(_ segmentedControl:UISegmentedControl) {
        _ = currentSortedTopStories
        switch (segmentedControl.selectedSegmentIndex) {
        case 0: HNStoryManager.shared.sortStyle = HNSortStyle.points
        case 1: HNStoryManager.shared.sortStyle = HNSortStyle.rank
        case 2: HNStoryManager.shared.sortStyle = HNSortStyle.comments
        default: assert(false, "Incorrect Sorting State")
        }
    }
    
    //MARK:- TableView Delegate Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HNStoryManager.shared.currentTopStories.count
    }
    
    override func tableView(_ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER) as UITableViewCell? {
            update(cell, at: indexPath, shimmer: false)
            return cell
        } else {
            let cell = UITableViewCell(style: UITableViewCellStyle.subtitle,
                                   reuseIdentifier: CELL_IDENTIFIER)
            update(cell, at: indexPath, shimmer: false)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath) {
            let itemNumber = self.itemNumber(for: indexPath)
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath) {
            cell.backgroundColor = AppDelegate.hackerBeige()
    }
    
    override func tableView(_ tableView: UITableView, commit
        editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    //MARK:- Rotation
    
    override func willTransition(to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator) {
            weak var this = self
            coordinator.animate(alongsideTransition: { ( context) -> Void in
                this?.rowHeightDictionary = nil
                this?.tableView.reloadData()
                }, completion: { (context) -> Void in })
    }
    
    //MARK:- Transition
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "textViewSegue" {
            let controller = segue.destination as! TextViewController
            controller.story = sender as? HNStory;
        }
    }

    //MARK:- Memory Management
    
    override func didReceiveMemoryWarning() {
        FIRAnalytics.logEvent(withName: "MemoryWarning", parameters: nil)
        super.didReceiveMemoryWarning()
    }
}
