//
//  DataCoreDataSotrageObject.m
//  MyCoreData
//
//  Created by Petey Mi on 12/20/14.
//  Copyright (c) 2014 Petey Mi. All rights reserved.
//

#import "DataCoreDataSotrageObject.h"

@interface DataCoreDataSotrageObject ()
@property(nonatomic, assign) int primitiveIsShow;

@end

@implementation DataCoreDataSotrageObject
{
    int _show;
    NSString* aaaaa;
}

@dynamic name;
@dynamic isShow;
@dynamic test;
@dynamic primitiveIsShow;

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
-(void)setPrimitiveIsShow:(int)primitiveIsShow
{
    _show = primitiveIsShow;
}
-(int)primitiveIsShow
{
    return _show;
}
-(void)setIsShow:(int)isShow
{
//    [self willAccessValueForKey:@"isShow"];
//    [self setPrimitiveValue:@(isShow) forKey:@"isShow"];
    [self willChangeValueForKey:@"isShow"];
//    _show = isShow;
//    [self setPrimitiveValue:@(isShow) forKey:@"isShow"];
    [self setPrimitiveIsShow:isShow];
    [self didChangeValueForKey:@"isShow"];
//    [self didAccessValueForKey:@"isShow"];

}
-(int)isShow
{
    BOOL value;
    [self willAccessValueForKey:@"isShow"];
    value = [self primitiveIsShow];
//    id cc = [self primitiveValueForKey:@"isShow"];
//    value = [dd boolValue];
//     value = _show;
    [self didAccessValueForKey:@"isShow"];
    return value;
}

-(void)setTest:(NSString *)atest{
    [self willChangeValueForKey:@"test"];
    aaaaa = atest;
    [self didChangeValueForKey:@"test"];
}
-(NSString*)test{
    NSString* value;
    [self willAccessValueForKey:@"test"];
    value = aaaaa;
    [self didAccessValueForKey:@"test"];
    return value;
}
@end
