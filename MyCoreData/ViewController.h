//
//  ViewController.h
//  MyCoreData
//
//  Created by Petey Mi on 12/18/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyCoreDataStorage.h"
#import "DataCoreDataSotrageObject.h"

@interface ViewController : UIViewController
{
    __weak IBOutlet UITableView*    _tableView;
}
-(IBAction)bt1:(id)sender;
-(IBAction)bt2:(id)sender;

@end

