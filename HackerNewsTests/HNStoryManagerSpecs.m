//
//  HackerNewsTests.m
//  HackerNewsTests
//
//  Created by xes on 10/15/14.
//  Copyright (c) 2014 wrkstrm. All rights reserved.
//

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>
#import "HNStoryManager.h"

QuickSpecBegin(HNStoryManagerSpecs)
describe(@"HNStoryManager", ^{
    it(@"boots nicely", ^{
        expect(HNStoryManager.new).toNot(beNil());
    });
    
    describe(@"Initializes", ^{
        __block HNStoryManager *manager;
        beforeEach(^{
            manager = HNStoryManager.new;
        });
        
        it(@"CurrentUser", ^{
            expect(manager.currentUser).toNot(beNil());
        });
        
        it(@"UserDatabase", ^{
            HNUser *user = manager.currentUser;
            expect(user.localDatabase).toNot(beNil());
        });
        
        it(@"TopStoriesDocument", ^{
            CBLDatabase *db = manager.currentUser.localDatabase;
            expect(@([db documentCount])).toNot(equal(@0));
        });
        
        it(@"Current Top Stories:", ^{
            expect(manager.currentTopStories).toNot(beNil());
        });
    });
});

QuickSpecEnd
