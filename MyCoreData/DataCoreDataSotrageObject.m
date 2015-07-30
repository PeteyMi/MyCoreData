//
//  DataCoreDataSotrageObject.m
//  MyCoreData
//
//  Created by Petey Mi on 12/20/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import "DataCoreDataSotrageObject.h"


@implementation DataCoreDataSotrageObject
{
    BOOL _show;
}
@dynamic name;
@dynamic isShow;

-(void)awakeFromFetch
{
    [super awakeFromFetch];
}
-(void)awakeFromInsert
{
    [super awakeFromInsert];
}
-(void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
}

-(void)setIsShow:(BOOL)isShow
{
    [self willAccessValueForKey:@"isShow"];
//    [self setPrimitiveValue:@(isShow) forKey:@"isShow"];
    _show = isShow;
    [self didAccessValueForKey:@"isShow"];
}
-(BOOL)isShow
{
    BOOL value;
    [self willAccessValueForKey:@"isShow"];
//    value = [[self primitiveValueForKey:@"isShow"] boolValue];
     value = _show;
    [self didAccessValueForKey:@"isShow"];
    return value;
}
@end
