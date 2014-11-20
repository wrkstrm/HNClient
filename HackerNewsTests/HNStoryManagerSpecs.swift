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

class HNStoryManagerSpecs: QuickSpec {
    override func spec() {
        describe("Initialization.") {
            it ("Boots.") {
                let manager = HNStoryManager()
                expect(true).to(beTrue())
            }
        }
    }
}
