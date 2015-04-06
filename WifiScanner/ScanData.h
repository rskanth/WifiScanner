//
//  ScanData.h
//  WifiScanner
//
//  Created by Sreekanth Rupavatharam on 11/6/13.
//  Copyright (c) 2013 Sreekanth Rupavatharam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScanData : NSObject <NSTableViewDataSource> {
    NSMutableArray *macArray;
    NSMutableArray *sigArray;
    NSMutableArray *ssidArray;
    NSMutableArray *tsArray;
    NSMutableArray *vendorArray;
}
@property (strong) NSMutableArray * macArray;
@property (strong) NSMutableArray * sigArray;
@property (strong) NSMutableArray * ssidArray;
@property (strong) NSMutableArray *tsArray;
@property (strong) NSMutableArray * vendorArray;

#define DISPLAY_SIZE 9
@end
