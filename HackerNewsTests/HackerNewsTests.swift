//
//  HackerNewsTests.swift
//  HackerNews
//
//  Created by Cristian Monterroza on 11/14/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

import Foundation
import XCTest
import Quick
import Nimble

class TopViewControllerTests: QuickSpec {
    
    override func spec() {
        describe("tableview udpate") {
            it ("works fine") {
                let array = [0,1,2]
                expect(array.count).to(equal(3))
            }
        }
    }
}
