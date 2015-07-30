//
//  MyCoreDataStorageProtected.h
//  MyCoreData
//
//  Created by Petey Mi on 12/18/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import "MyCoreDataStorage.h"

@interface MyCoreDataStorage (Protected)

/**
 *  If your subclass needs to do anything for init, it can do so easily by overriding this method.
 *  All public init methods will invoke this method at the end of their implementation.
 *  
 *  Important: If overriden you must invoke [super commonInit] at some point.
 **/
-(void)commonInit;

/**
 *  Override me, if needed, to provide customized behavior.
 *
 *  This method is queried to get the name of the ManagedObjectModel within a bundle.
 *  It should return the name of appropriate file (*.xdatamodel / *.mom / *.mod) sans file extension.
 *
 *  The default implementation returns the name of the subclass, strinpping any suffix of "CoreDataStorage".
 *
 *  Note that a file extension should NOT be included.
 **/
-(NSString*)managedObjectModelName;

/**
 *  Override me, if needed, to provide customized behavior.
 *
 *  This method is queried to get the bundle containing the ManagedObjectModel.
 **/
-(NSBundle*)managedObjectBundle;

/**
 *  Override me, if needed, to provide customized behavior.
 *
 *  This method is queried if the initWithDatabaseFileName:storeOptions: method is invoked with a nil
 *  parameter for databaseFileName.
 *
 *  [NSString stringWithFormat:@"%@.sqlite",[self managedObjectModelName]];
 *
 *  You are encouraged to use the sqlite file extension.
 **/
-(NSString*)defaultDatabaseFileName;

/**
 *  Override me, if needed, to provide customized behavior.
 *
 *  This method is queried if the initWithDatabaseFileName:storeOptions method is invoked with a nil
 *  parameter for storeOptions
 *  The default implementation returns the following:
 *  
 *  @{ NSMigratePersistentStoresAutomaticallyOption: @(YES),
 *     NSInferMappingModelAutomaticallyOption: @(YES) };
 **/
-(NSDictionary*)defaultStoreOptions;

/**
 *  Override me, if needed, to provide customized behavior.
 *  If you are using a database file with pure non-persistent data (e.g. for memory optimization purposes on iOS),
 *  you may want to delete the database file if it already exists on disk.
 *
 *  If this instance was created via initWithDatabaseFilename, then the storePath parameter will be non-nil.
 *
 *  The default implementation does nothing.
 **/
-(void)willCreatePersistentStoreWithPath:(NSString*)storePath options:(NSDictionary*)storeOptions;

/**
 *  Override me, if needed, to completely the persistent store.
 *
 *  Adds the persistent store path to the persistent store coordinator.
 *
 *  If this instance was created via initWithDatabaseFileName, then the storePath parameter will be non-nil.
 **/
-(BOOL)addPersistentStoreWithPath:(NSString*)storePath options:(NSDictionary*)storeOptions error:(NSError**)erropPtr;

/**
 *  Override me, if needed, to provide customized behavior.
 *
 *  For example, if you are using the database for non-persistent data and the model changes, you may want
 *  to delete the database file if it already exists on disk and a core data migration is not worthwhile.
 *
 *  If this instance was created via initWithDatabaseFilename, then the storePath parameter will be non-nil.
 **/
-(void)didNotAddPersistentStoreWithPath:(NSString*)storePath options:(NSDictionary*)storeOptions error:(NSError*)error;

/**
 *  Override me, if needed, to provide customized behavior.
 *
 *  For example, you may want to perform cleanup of any non-persistent data before you start using the database.
 *  The default implementation does nothing.
 **/
-(void)didCreateManagedObjectContext;

/**
 *  Override me if you need to do anything special just before changes are saved to disk.
 *
 *  This method will be invoked on the storageQueue.
 *  The default implementation does nothing.
 **/
-(void)willSaveManagedObjectContext;

/**
 *  Override me if you need to do anything special after changes have been saved to disk.
 *
 *  This method will be invoked on the storageQueue.
 *  The default implementation does nothing.
 **/
-(void)didSaveManagedObjectContext;

/**
 *  This method will be invoked on the main thread,
 *  after the mainThreadManagedObjectContext has merged changes from another context.
 *
 *  This method may be useful if you have code dependent upon when changes the datastore hit the user interface.
 *  For example, you want to play a sound when a message is received.
 *  You could play the sound right away, from the background queue, but the timing may be slightly off because
 *  the user interface won't update til the changes have been saved to disk.
 *  and then propogated to the managedObjectContext of the main thread.
 *  Alternatively you could set a flag, and then hook into this method
 *  to play the sound at the exact moment the propogation hits the main thread.
 *
 *  The default implementation does nothing.
 **/
-(void)mainThreadManagedObjectContextDidMergeChanges;

#pragma mark Core Data
/**
 *  The standard persistentStoreDirectory method.
 **/
-(NSString*)persistentStoreDirectory;

/**
 *  Provides access to the managedObjectContext.
 *
 *  Keep in mind that NSManagedObjectContext is NOT thread-safe.
 *  So you can ONLY access this property from within the context of the storageQueue.
 *
 *  Important:
 *  The primary purpose of this class is to optimize disk IO by buffering save operations to the managedObjectContext.
 *  It does this using the methods outlined in the 'Performance Optimizations' section below.
 *  If you manually save the managedObjectContext you are destroying these optimizations.
 *  See the documentation for executeBlock & scheduleBlock below for proper usage surrounding the optimizatios.
 **/
@property(readonly) NSManagedObjectContext* managedObjectContext;

/**
 *  Queries the managedObjectContext to determine the number of unsaved managedObjects.
 **/
-(NSUInteger)numberOfUnsavedChanges;


/**
 *  You will not often need to manually call this method.
 *  It is called automatically, at appropriate and optimized times, via the executeBlock and scheduleBlock methods.
 *  The one exception to this is when you are inserting/deleting/updating a large number of objects in a loop.
 *  It is recommended that you invoke save from within the loop.
 *  E.g.:
 *  NSUinteger unsavedCount = [self numberOfUnsavedChanges];
 *  for (NSManagedObject *obj in fetchResults )
 *  {
 *      [[self managedObjectContext] deleteObject:obj];
 *
 *      if (++unsavedCount >= saveThreshold)
 *      {
 *          [self save];
 *          unsavedCount = 0;
 *      }
 *  }
 *
 *  See also the documentation for excuteBlock and scheduleBlock below.
 **/
-(void)save;    // Read the comments above!

/**
 *  You will rarely need to manually call this method.
 *  It is called automatically, at appropriate and optimized times, via the executeBlock and scheduleBlock methods.
 *  
 *  This method makes informed decisions as to whether it should save the managedObjectContext changes to disk.
 *  Since this disk IO is a slow process, it is better to buffer writes during high demand.
 *  This method takes into account the number of pending requests waiting on the storage instance, as wll as the number of unsaved changes (which reside in NSManagedObjectContext's internal memory).
 *  Please see the documentation for executeBlock and schedulBlock below.
 **/
-(void)maybeSavev;  //Read the comments above!

/**
 *  This method synchronously invokes the given block (dispatch_sync) on the storageQueue.
 *
 *  Prior to dispatching the block it increments (atomically) the number of pending requests.
 *  After the block has been executed, it decrements (atomicay) the number of pending requests,
 *  and then invokes the maybeSave method which implements the logic behind the optimized disk IO.
 *
 *  If you use the executeBlock and scheduleBlock methods for all your database operations,
 *  you will automatically inherit optimized disk IO for free.
 *
 *  If you manually invoke [manageObjectContext save:] you are destroying the optimizations provided by this class.
 *  
 *  The architecture of this class purposefully puts the CoreDataStorage instance on a separate dispatch_queue
 **/
-(void)executeBlock:(dispatch_block_t)block;

/**
 *  This method asynchronously invokes the given block (dispatch_async) on the storageQueue.
 *
 *  It works very similarly to the executeBlock method.
 *  See the executeBlock method above for a full discussion.
 **/
-(void)scheduleBlock:(dispatch_block_t)block;

/**
 *  Sometimes you want to call a method before calling save on a Managed Object Context e.g. willSaveObject:
 *
 *  addWillSaveManagedObjectContextBlock allows you to add a block of code to be called before saving a Managed Object Context,
 *  without the overhead of having to call save at that moment.
 **/
-(void)allWillSaveManagedObjectContextBlock:(void(^)(void))willSaveBlock;

/**
 *  Sometimes you want to call a method after calling save on a Managed Object Context e.g. didSaveObject:
 *
 *  addDidSaveManagedObjectContextBlock allows you to add a block of code to be after saving a Managed Object Context, 
 *  without the overhead of having to call save at that moment.
 **/
-(void)addDidSaveManagedObjectContextBlock:(void(^)(void))didSaveBlock;
@end