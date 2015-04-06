//
//  ScanData.m
//  WifiScanner
//
//  Created by Sreekanth Rupavatharam on 11/6/13.
//  Copyright (c) 2013 Sreekanth Rupavatharam. All rights reserved.
//

#import "ScanData.h"

@implementation ScanData

@synthesize macArray;
@synthesize sigArray;
@synthesize ssidArray;
@synthesize tsArray;
@synthesize vendorArray;

- (id)init
{
    self = [super init];
    if (self) {
        macArray = [[NSMutableArray alloc] initWithCapacity:DISPLAY_SIZE ];
        sigArray = [[NSMutableArray alloc] initWithCapacity:DISPLAY_SIZE];
        ssidArray = [[NSMutableArray alloc] initWithCapacity:DISPLAY_SIZE];
        tsArray = [[NSMutableArray alloc] initWithCapacity:DISPLAY_SIZE];
        vendorArray = [[NSMutableArray alloc] initWithCapacity:DISPLAY_SIZE];
        
        for (int j=0; j < DISPLAY_SIZE; j++) {
            [macArray addObject:@" "];
            [sigArray addObject:@" "];
            [ssidArray addObject:@" "];
            [tsArray addObject:@" "];
            [vendorArray addObject:@" "];
        }
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"Dealloc of object");
    
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    //NSLog(@"Count: %lu\n", [macArray count]);
   return [macArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
//    NSLog(@"Row Index: %lu\n", rowIndex);
    NSString *colName = [aTableColumn identifier];
   // NSLog(@"colname %@", colName);
    
    if([colName isEqualToString:@"Signal"])
        return [sigArray objectAtIndex:rowIndex];
    
    if([colName isEqualToString:@"Mac"])
        return [macArray objectAtIndex:rowIndex];

    if([colName isEqualToString:@"SSID"])
        return [ssidArray objectAtIndex:rowIndex];

    if([colName isEqualToString:@"Timestamp"])
        return [tsArray objectAtIndex:rowIndex];
    if([colName isEqualToString:@"Vendor"])
        return [vendorArray objectAtIndex:rowIndex];

    return NULL;

}

@end
