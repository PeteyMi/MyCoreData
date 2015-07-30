//
//  MySelfData.m
//  MyCoreData
//
//  Created by Petey Mi on 12/20/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import "MySelfData.h"
#import "DataCoreDataSotrageObject.h"
#import "MyCoreDataStorageProtected.h"

@implementation MySelfDataCoreDataStorage

-(void)insertData
{
    dispatch_block_t block = ^{
        DataCoreDataSotrageObject* obj = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DataCoreDataSotrageObject class]) inManagedObjectContext:self.managedObjectContext];
        obj.name = @"aaaaaaa";
        obj.isShow = YES;
        [self.managedObjectContext save:nil];
    };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_async(_storageQueue, block);
    }
}

@end
