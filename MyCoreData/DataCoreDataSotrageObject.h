//
//  DataCoreDataSotrageObject.h
//  MyCoreData
//
//  Created by Petey Mi on 12/20/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DataCoreDataSotrageObject : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, assign) int isShow;


@property(nonatomic, retain) NSString* test;

@end
