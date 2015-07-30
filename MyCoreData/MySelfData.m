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
//        DataCoreDataSotrageObject* obj = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DataCoreDataSotrageObject class]) inManagedObjectContext:self.managedObjectContext];
//        obj.name = @"aaaaaaa";
//        obj.isShow = YES;
//        [self.managedObjectContext save:nil];
        NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([DataCoreDataSotrageObject class])];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name = %@",@"name1"];
        [request setPredicate:predicate];
        
        NSArray* array = [self.managedObjectContext executeFetchRequest:request error:nil];
        if (array.count > 0) {
            for (DataCoreDataSotrageObject* item in array) {
                item.test = @"bbbbbbb";
                item.isShow = 2;
                [self save];
            }
        }
     };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_async(_storageQueue, block);
    }
}

@end
