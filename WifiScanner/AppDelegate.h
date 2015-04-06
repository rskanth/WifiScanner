//
//  AppDelegate.h
//  WifiScanner
//
//  Created by Sreekanth Rupavatharam on 11/1/13.
//  Copyright (c) 2013 Sreekanth Rupavatharam. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScanData.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {

}

@property (strong) IBOutlet NSComboBox *Interfaceselect;
@property (strong) IBOutlet NSButton *StartButton;
-(void) capture_callback: (NSString*) mac1 apmac:(NSString*) mac2
                  signal:(NSString*)sig vendor:(NSString*)vendor type:(int)type;

@property (strong) IBOutlet NSWindow *AboutWindow;

@property (strong) IBOutlet NSTextField *PacketCount;


@property (strong) IBOutlet NSClipView *OutputClip;
@property (strong) IBOutlet NSTextFieldCell *TextVendor;
@property (strong) IBOutlet NSView *About;

@property (strong) IBOutlet NSTableView *OutputTable;

@property (strong) IBOutlet NSTextFieldCell *TextSignal;
@property (strong) IBOutlet NSTextFieldCell *TextMac;
@property (strong) IBOutlet NSTextFieldCell *TextSSID;
@property (strong) IBOutlet NSTextFieldCell *TextLastSeen;


@property (strong) IBOutlet NSTableColumn *TableMac;


@end
