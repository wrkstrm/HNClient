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
 Create a brand new Default User with the property dictionary requested. 
 This is useful after a POST request to create a new user and need to save user data. 
 If you need to set the specific documentID for the user, pass in a "_id" value. 
 Otherwise, a random UUID will be created for the user.
 */

+ (instancetype)createDefaultUserWithProperties:(NSDictionary *)properties;

+ (instancetype)userWithProperties:(NSDictionary *)properties;

+ (instancetype)existingUserWithID:(NSString *)userID;

- (void)addParams:(NSDictionary *)params;

/**
 This method gives you the database that belongs to the user. 
 This is a different place than where the user documents are created.
 */

- (CBLDatabase *)userDatabase;

- (NSString *)userDatabaseName;

@end
