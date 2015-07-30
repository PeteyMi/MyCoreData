//
//  MyCoreDataStorage.m
//  MyCoreData
//
//  Created by Petey Mi on 12/18/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import <objc/runtime.h>
#import <libkern/OSAtomic.h>

#import "MyCoreDataStorage.h"

@implementation MyCoreDataStorage

static NSMutableSet*    _gDatabaseFileNames;

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _gDatabaseFileNames = [[NSMutableSet alloc] init];
    });
}

+(BOOL)registerDatabaseFileName:(NSString*)dbFileName
{
    BOOL result = NO;
    @synchronized(_gDatabaseFileNames) {
        if (![_gDatabaseFileNames containsObject:dbFileName]) {
            [_gDatabaseFileNames addObject:dbFileName];
            result =  YES;
        }
    }
    return result;
}
+(void)unregisterDatabaseFileName:(NSString*)dbFileName
{
    @synchronized(_gDatabaseFileNames) {
        [_gDatabaseFileNames removeObject:dbFileName];
    }
}

#pragma mark Override Me
-(NSString*)managedObjectModelName
{
    //  Override me, if needed, to provide customized behavior.
    //
    //  This method is queried to get the name of the ManagedObjectModel within the app bundle.
    //  It should return the name of the appropriate file (*.xdatamodel / *.mom / *.momd) sans file extension.
    //
    //  The default implementation returns the name of the subclass, stripping any suffix of "CoreDataStorage".
    //  Note that a file extension should NOT be included.
    
    NSString*   className = NSStringFromClass([self class]);
    NSString*   suffix = @"CoreDataStorage";
    
    if ([className hasSuffix:suffix] && className.length > suffix.length) {
        return [className substringToIndex:(className.length - suffix.length)];
    } else {
        return className;
    }
}

-(NSBundle*)managedObjectModelBundle
{
    return [NSBundle bundleForClass:[self class]];
}

-(NSString*)defaultDatabaseFileName
{
    //  Override me, if needed, to provide customized behavior.
    //
    //  This method is queried if the initWithDatabaseFileName:storeOptons: method is invoked with a nil parameter for databaseFileName.
    //
    //  You are encouraged to use the sqlite file extension.
    return [NSString stringWithFormat:@"%@.sqlite",[self managedObjectModelName]];
}

-(NSDictionary*)defaultStoreOptions
{
    //  Overried me, if needed, to provide customized behavior.
    //
    //  This method is queried if the initWithDatabaseFileName:storeOption: method is invoked with a nil parameter for defaultStoreOptions.

    NSDictionary* defaultStoreOptions = nil;
    if (_databaseFileName) {
        defaultStoreOptions = @{ NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                 NSInferMappingModelAutomaticallyOption: @(YES) };
    }
    return defaultStoreOptions;
}

-(void)willCreatePersistentStoreWithPath:(NSString*)storePath options:(NSDictionary*)theStoreOptions
{
}

-(BOOL)addPersistentStoreWithPath:(NSString*)storePath options:(NSDictionary*)theStoreOptions error:(NSError**)errorPtr
{
    //  Override me, if needed, to completely customize the persistent store.
    //
    //  Adds the persistent store path to teh persistent store coordinator.
    //  Returns ture if the persistent store is created.
    //
    //  If this instance was create via iniWithDatabaseFilename, then the storePath parameter will be non-nil.
    
    NSPersistentStore*  persistentStore;
    if (storePath) {
        //  SQLite persisten store
        NSURL*  storeUrl = [NSURL fileURLWithPath:storePath];
        persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                    configuration:nil
                                                                              URL:storeUrl
                                                                          options:_storeOptions
                                                                            error:errorPtr];
    }
    return persistentStore != nil;
}

-(void)didNotAddPersistentStoreWithPath:(NSString*)storePath options:(NSDictionary*)theStoreOptions error:(NSError*)error
{
    
}

-(void)didCreateManagedObjectContext
{
    //  Overrid me to provide customized behavior.
    //  For example, you may want to perform cleanup of any non-persistent data before you start using the database.
    //  This method is invoked on the storageQueue.
}
-(void)willSaveManagedObjectContext
{
    //  Override me if you need to do anything special just before changes are saved to disk.
    //  This method is invoked on the storageQueue.
}
-(void)didSaveManagedObjectContext
{
    //  Override me if you want to do anything special after chanage have been saved to disk.
    //  This method is invoked on the storageQueue.
}
-(void)mainThreadManagedObjectContextDidMergeChanges
{
    //  Override me if you want to do anything special when changes get propogated to the main thread.
    //  This method is invoked on the main thread.
}

#pragma mark Setup
@synthesize databaseFileName = _databaseFileName;
@synthesize storeOptions = _storeOptions;

-(void)commonInit
{
    _saveThreshold = 500;
    
    _storageQueue = dispatch_queue_create(class_getName([self class]), NULL);
    _storageQueueTag = &_storageQueueTag;
    dispatch_queue_set_specific(_storageQueue, _storageQueueTag, _storageQueueTag, NULL);
    
    _willSaveManagedObjectContextBlocks = [[NSMutableArray alloc] init];
    _didSaveManagedObjectContextBlocks = [[NSMutableArray alloc] init];
}

-(id)init
{
    return [self initWithDatabaseFilename:nil storeOptions:nil];
}
-(id)initWithDatabaseFilename:(NSString *)databaseFileName storeOptions:(NSDictionary *)storeOptions
{
    if (self = [super init]) {
        if (databaseFileName) {
            _databaseFileName = [databaseFileName copy];
        } else {
            _databaseFileName = [[self defaultDatabaseFileName] copy];
        }
    }
    
    if (storeOptions) {
        _storeOptions = storeOptions;
    } else {
        _storeOptions = [self defaultStoreOptions];
    }
    
    if (![[self class] registerDatabaseFileName:_databaseFileName]) {
        return nil;
    }
    [self commonInit];
    return self;
}

-(NSUInteger)saveThreshold
{
    if (dispatch_get_specific(_storageQueueTag)) {
        return _saveThreshold;
    } else {
        __block NSUInteger result;
        dispatch_sync(_storageQueue, ^{
            result = _saveThreshold;
        });
        return result;
    }
}
-(void)setSaveThreshold:(NSUInteger)saveThreshold
{
    dispatch_block_t block = ^{
        _saveThreshold = saveThreshold;
    };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_async(_storageQueue, block);
    }
}

#pragma mark Core Data Setup
-(NSString*)persistentStoreDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* basePath = paths.count > 0 ?[paths objectAtIndex:0] : NSTemporaryDirectory();
    
    // Attempt to find a name for this application
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (appName == nil) {
        appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    if (appName == nil) {
        appName = @"myCoreData";
    }
    
    NSString* result = [basePath stringByAppendingPathComponent:appName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:result]) {
        [fileManager createDirectoryAtPath:result withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return result;
}

-(NSManagedObjectModel*)managedObjectModel
{
    //  This is a public method.
    //  It may be invoked on any thread/queue.
    __block NSManagedObjectModel*   result = nil;
    
    dispatch_block_t block = ^{ @autoreleasepool{
        if (_managedObjectContext) {
            result = _managedObjectModel;
            return ;
        }
        
        NSString* momName = [self managedObjectModelName];
        
        NSString* momPath = [[self managedObjectModelBundle] pathForResource:momName ofType:@"mom"];
        if (momPath == nil) {
            momPath = [[self managedObjectModelBundle] pathForResource:momName ofType:@"momd"];
        }
        
        if (momPath) {
            NSURL* momUrl = [NSURL fileURLWithPath:momPath];
            _managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:momUrl] copy];
        }
        
        if ([NSAttributeDescription instancesRespondToSelector:@selector(setAllowsExternalBinaryDataStorage:)]) {
            if (_autoAllowExternalBinaryDataStorage) {
                NSArray* entiies = [_managedObjectModel entities];
                for (NSEntityDescription* entity in entiies) {
                    NSDictionary* attributesByName = [entity attributesByName];
                    [attributesByName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        if ([obj attributeType] == NSBinaryDataAttributeType) {
                            [obj setAllowsExternalBinaryDataStorage:YES];
                        }
                    }];
                }
            }
        }
        result = _managedObjectModel;
    } };
    
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
    return result;
}

-(NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    //  This is a public method.
    //  It may be invoked on any thread/queue.
    __block NSPersistentStoreCoordinator*   result = nil;
    
    dispatch_block_t    block = ^{ @autoreleasepool{
        if (_persistentStoreCoordinator) {
            result = _persistentStoreCoordinator;
            return;
        }
        
        NSManagedObjectModel* mom = [self managedObjectModel];
        if (mom == nil) {
            return;
        }
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        if (_databaseFileName) {
            NSString* docsPath = [self persistentStoreDirectory];
            NSString* storePath = [docsPath stringByAppendingPathComponent:_databaseFileName];
            if (storePath) {
                if (_autoRemovePreviousDatabaseFile) {
                    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
                        [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
                    }
                }
                [self willCreatePersistentStoreWithPath:storePath options:_storeOptions];
                
                NSError* error = nil;
                BOOL didAddPersistentStore = [self addPersistentStoreWithPath:storePath options:_storeOptions error:&error];
                
                if (_autoRecreateDatabaseFile && !didAddPersistentStore) {
                    [[NSFileManager defaultManager] removeItemAtPath:storePath error:NULL];
                    didAddPersistentStore = [self addPersistentStoreWithPath:storePath options:_storeOptions error:&error];
                }
                
                if (!didAddPersistentStore) {
                    [self didNotAddPersistentStoreWithPath:storePath options:_storeOptions error:error];
                }
            }
        }
        result = _persistentStoreCoordinator;
    }};
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
    return result;
}

-(NSManagedObjectContext*)managedObjectContext
{
    //  This is private method.
    //
    //  NSManagedObjectContext is NOT thread-safe.
    //  Therefore it is VERY VERY BAD to use our private managedObjectContext outside our private storageQueue
    //
    //  When you want a managedObjectContext of you own (again, excluding subclasses),
    //  you can use the mainThreadManagedObjectContext, or you should create you own using the public persistentStoreCoordinator.
    
    NSAssert(dispatch_get_specific(_storageQueueTag), @"Invoked on incorrect queue");
    
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        if ([NSManagedObjectContext instancesRespondToSelector:@selector(initWithConcurrencyType:)]) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        } else {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
        }
        _managedObjectContext.persistentStoreCoordinator = coordinator;
        _managedObjectContext.undoManager = nil;
        
        [self didCreateManagedObjectContext];
    }
    return _managedObjectContext;
}
-(NSManagedObjectContext*)mainThreadManagedObjectContext
{
    NSAssert([NSThread mainThread], @"Context reserved for main thread only");
    
    if (_mainThreadManagedObjectContext) {
        return _mainThreadManagedObjectContext;
    }
    NSPersistentStoreCoordinator*   coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        if ([NSManagedObjectContext instancesRespondToSelector:@selector(initWithConcurrencyType:)]) {
            _mainThreadManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        } else {
            _mainThreadManagedObjectContext = [[NSManagedObjectContext alloc] init];
        }
        _mainThreadManagedObjectContext.persistentStoreCoordinator = coordinator;
        _mainThreadManagedObjectContext.undoManager = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return _mainThreadManagedObjectContext;
}
-(void)managedObjectContextDidSave:(NSNotification*)notification
{
    NSManagedObjectContext* sender = (NSManagedObjectContext*)notification.object;
    
    if ((sender != _mainThreadManagedObjectContext) && (sender.persistentStoreCoordinator == _mainThreadManagedObjectContext.persistentStoreCoordinator)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSManagedObject* object in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
                [[_mainThreadManagedObjectContext objectWithID:[object objectID]] willAccessValueForKey:nil];
            }
            
            [_mainThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
            [self mainThreadManagedObjectContextDidMergeChanges];
        });
    }
}

-(BOOL)autoRemovePreviousDatabaseFile
{
    __block BOOL result = NO;
    dispatch_block_t block = ^{ @autoreleasepool {
        result = _autoRemovePreviousDatabaseFile;
    } };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
    return result;
}
-(void)setAutoRemovePreviousDatabaseFile:(BOOL)autoRemovePreviousDatabaseFile
{
    dispatch_block_t block = ^{
        _autoRemovePreviousDatabaseFile = autoRemovePreviousDatabaseFile;
    };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
}

-(BOOL)autoRecreateDatabaseFile
{
    __block BOOL result = NO;
    dispatch_block_t block = ^{ @autoreleasepool {
        result = _autoRecreateDatabaseFile;
    } };
    if (dispatch_get_specific(_storageQueueTag)) {
        block ();
    } else {
        dispatch_sync(_storageQueue, block);
    };
    return result;
}

-(void)setAutoRecreateDatabaseFile:(BOOL)autoRecreateDatabaseFile
{
    dispatch_block_t block = ^{
        _autoRecreateDatabaseFile = autoRecreateDatabaseFile;
    };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
}

-(BOOL)autoAllowExternalBinaryDataStorage
{
    __block BOOL result = NO;
    
    dispatch_block_t block = ^{ @autoreleasepool {
        result = _autoAllowExternalBinaryDataStorage;
    } };
    
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
    return result;
}
-(void)setAutoAllowExternalBinaryDataStorage:(BOOL)autoAllowExternalBinaryDataStorage
{
    dispatch_block_t block = ^{
        _autoAllowExternalBinaryDataStorage = autoAllowExternalBinaryDataStorage;
    };
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
}

#pragma mark Utilites
-(NSUInteger)numberOfUnsavedChanges
{
    NSManagedObjectContext* mom = [self managedObjectContext];
    
    NSUInteger unsavedCount = 0;
    unsavedCount += [[mom updatedObjects] count];
    unsavedCount += [[mom insertedObjects] count];
    unsavedCount += [[mom deletedObjects] count];
    return unsavedCount;
}

-(void)save
{
    for (void(^block)(void) in _willSaveManagedObjectContextBlocks) {
        block();
    }
    
    [_willSaveManagedObjectContextBlocks removeAllObjects];
    
    NSError* error = nil;
    if ([[self managedObjectContext] save:&error]) {
        _saveCount++;
        for (void(^block)(void) in _didSaveManagedObjectContextBlocks) {
            block();
        }
        [_didSaveManagedObjectContextBlocks removeAllObjects];
    } else {
        [[self managedObjectContext] rollback];
        [_didSaveManagedObjectContextBlocks removeAllObjects];
    }
}

-(void)maybeSave:(int32_t)currentPendingRequests
{
    NSAssert(dispatch_get_specific(_storageQueueTag), @"Invoked on incorrect queue");
    
    if ([self managedObjectContext].hasChanges) {
        if (currentPendingRequests == 0) {
            [self save];
        } else {
            NSUInteger unsavedCount = [self numberOfUnsavedChanges];
            if (unsavedCount >= _saveThreshold) {
                [self save];
            }
        }
    }
}
-(void)maybeSave
{
    [self maybeSave:OSAtomicAdd32(0, &_pendingRequest)];
}

-(void)executeBlock:(dispatch_block_t)block
{
    NSAssert(!dispatch_get_specific(_storageQueueTag), @"Invoked on incorrect queue");
    
    OSAtomicIncrement32(&_pendingRequest);
    dispatch_sync(_storageQueue, ^{ @autoreleasepool {
        block();
        
        dispatch_async(_storageQueue, ^{ @autoreleasepool {
            [self maybeSave:OSAtomicDecrement32(&_pendingRequest)];
        }});
    } });
}

-(void)scheduleBlock:(dispatch_block_t)block
{
    NSAssert(!dispatch_get_specific(_storageQueueTag), @"Invoked on incorrect queue");
    
    OSAtomicIncrement32(&_pendingRequest);
    dispatch_async(_storageQueue, ^{ @autoreleasepool {
        block();
        [self maybeSave:OSAtomicDecrement32(&_pendingRequest)];
    }});
}
-(void) addWillSaveManagedObjectContextBlock:(void (^)(void))willSaveBlock
{
    dispatch_block_t block = ^ {
        [_willSaveManagedObjectContextBlocks addObject:[willSaveBlock copy]];
    };
    
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
}
-(void)addDidSaveManagedObjectContextBlock:(void (^)(void))didSaveBlock
{
    dispatch_block_t block = ^{
        [_didSaveManagedObjectContextBlocks addObject:[didSaveBlock copy]];
    };
    
    if (dispatch_get_specific(_storageQueueTag)) {
        block();
    } else {
        dispatch_sync(_storageQueue, block);
    }
}

#pragma mark Memory Management
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_databaseFileName) {
        [[self class] unregisterDatabaseFileName:_databaseFileName];
    }
}















@end
