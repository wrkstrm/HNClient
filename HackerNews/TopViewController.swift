//
//  TopViewController.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/9/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation

class TopViewController: HNTopViewController {
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        self.tableView.backgroundColor = self.hackerBeige()
        super.viewDidLoad()
    }
    
    // MARK: - TableView Delegate Methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentSortedTopStories.count
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            cell.backgroundColor = self.hackerBeige()
    }
    
    // MARK: - Rotation
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection,
        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            coordinator.animateAlongsideTransition({ ( context) -> Void in
                self.rowHeightDictionary = nil
                self.tableView.reloadData()
                }, completion: { (context) -> Void in })
    }
    
    // MARK: - Transition
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "textViewSegue" {
            let controller = segue.destinationViewController as TextViewController
            controller.document = sender as CBLDocument!;
        }
    }
    
    // MARK: - Helper Methods
    
    func hackerBeige() -> UIColor  {
        return SKColorMakeRGB(245.0, 245.0, 238.0)
    }
    
    func hackerOrange() -> UIColor {
        return SKColorMakeRGB(255.0, 102.0, 0.0)
    }
    
    // MARK: - Memory Management
    
    override func didReceiveMemoryWarning() {
        Flurry.logEvent("MemoryWarning")
    }
}
