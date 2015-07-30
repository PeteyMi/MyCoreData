//
//  ViewController.m
//  MyCoreData
//
//  Created by Petey Mi on 12/18/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import "ViewController.h"
#import "MySelfData.h"

@interface ViewController ()<UITableViewDataSource, NSFetchedResultsControllerDelegate>
{
    MySelfDataCoreDataStorage*  _coreDataStorage;
    NSInteger   count;
}
@property(nonatomic, readonly) NSFetchedResultsController* fetchedController;

@end

@implementation ViewController
@synthesize fetchedController = _fetchedController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _coreDataStorage = [[MySelfDataCoreDataStorage alloc] initWithDatabaseFilename:@"MyData" storeOptions:nil];
    _coreDataStorage.autoRemovePreviousDatabaseFile = YES;
    self.fetchedController.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSFetchedResultsController*)fetchedController
{
    if (_fetchedController != nil) {
        return _fetchedController;
    }
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([DataCoreDataSotrageObject class])];
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [request setSortDescriptors:@[sort]];
    
    _fetchedController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
managedObjectContext:_coreDataStorage.mainThreadManagedObjectContext
                                                               sectionNameKeyPath:nil cacheName:nil];
    [_fetchedController performFetch:nil];
    return _fetchedController;
}

-(IBAction)bt1:(id)sender
{
    DataCoreDataSotrageObject* object = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DataCoreDataSotrageObject class]) inManagedObjectContext:self.fetchedController.managedObjectContext];
    object.name = [NSString stringWithFormat:@"name%ld",(long)count];
    count++;
//    object.isShow = YES;
    
    [self.fetchedController.managedObjectContext save:nil];
}
-(IBAction)bt2:(id)sender
{
    [_coreDataStorage insertData];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchedController.fetchedObjects.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* str = @"aaa";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:str];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:str];
    }
    
    DataCoreDataSotrageObject* obj = [self.fetchedController.fetchedObjects objectAtIndex:indexPath.row];
    cell.textLabel.text = obj.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",obj.isShow == YES ? @"YES" : @"NO"];
    return cell;
}
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView endUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self config:indexPath];
            break;
        default:
            break;
    }
}
-(void)config:(NSIndexPath*)indexPath
{
    DataCoreDataSotrageObject* obj = [self.fetchedController.fetchedObjects objectAtIndex:indexPath.row];
    UITableViewCell* cell = [_tableView cellForRowAtIndexPath:indexPath];
    
    cell.textLabel.text = obj.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",obj.isShow == YES ? @"YES" : @"NO"];
}

@end
