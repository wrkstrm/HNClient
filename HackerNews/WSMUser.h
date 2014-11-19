//
//  WSMUser.h
//  Mesh
//
//  Created by Cristian Monterroza on 7/26/14.
//  Copyright (c) 2014 daheins. All rights reserved.
//

#import "CBLModel+WSMUtilities.h"

@interface WSMUser : CBLModel

#define localUsersDB @"local_users"

/**
 This will return nil until a user is set with setDefaultUser. 
 If you have the properties you want, call createDefaultUserWithProperties.
 */

+ (instancetype)defaultUser;

/**
 This will set a user as the default user. 
 This is not the perfered way of creating a new default user.
 */

+ (void)setDefaultUser:(WSMUser *)user;

/**
 
 */

+ (instancetype)createDefaultUserWithProperties:(NSDictionary *)properties;

+ (instancetype)userWithProperties:(NSDictionary *)properties;

+ (instancetype)existingUserWithID:(NSString *)userID;

- (void)addParams:(NSDictionary *)params;

- (NSString *)localDatabaseName;

@end
