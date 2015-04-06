//
//  AppDelegate.m
//  WifiScanner
//
//  Created by Sreekanth Rupavatharam on 11/1/13.
//  Copyright (c) 2013 Sreekanth Rupavatharam. All rights reserved.
//

#import "AppDelegate.h"
#import "ScanData.h"
#include "wifi_scan.h"

@implementation AppDelegate

ScanData *myObject;
int packet_type = 1;

- (IBAction)InterfaceSelect:(NSComboBox *)sender {
    NSLog(@"Select the interface %@", self.Interfaceselect.objectValueOfSelectedItem);
    
}


- (void) scannerthread: (NSString*) interface {
    int ret;

    NSAlert* msgBox = [[NSAlert alloc] init];
    ret = start_scan((char *)[interface UTF8String], (void*)CFBridgingRetain(self));
    if(ret != 0) {
        [msgBox setMessageText: @"Start scan failed"];
        [msgBox addButtonWithTitle: @"OK"];
        /*
        [msgBox addButtonWithTitle: @"Yes"];
        [msgBox addButtonWithTitle: @"No"];
        [msgBox addButtonWithTitle: @"Cancel"];
         */
        [msgBox runModal];

    }

    
}




-(void) capture_callback: (NSString*) mac1 apmac:(NSString*) mac2
                  signal: (NSString*)sig vendor: (NSString*)vendor type:(int) type
{
    static int index = 0;
    NSDate *date = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"HH:mm:ss"];
    static int count;
    NSString *theDate = [fmt stringFromDate:date];
    
    
//    NSString *timestamp = [NSString stringWithFormat:@"%", ti];
    
  

    //NSLog(@"Call back %@ %@ sig: %@", mac1, mac2, sig);
    //NSLog(@"Count %lu", (unsigned long)[myObject.macArray count]);
    
/*
    float rand_max = RAND_MAX;
    float red = rand()   / rand_max;
    float green = rand() / rand_max;
    float blue = rand()  / rand_max;
    
    NSColor *color = [NSColor colorWithCalibratedRed:0.8f green:0.3f blue:0.7f alpha:1.0f];
 */
   // [self.TextSignal setDrawsBackground:true];
    
    if((type & packet_type) == 0) return;
    count++;
    NSString *str_count = [NSString stringWithFormat:@"Packets: %d", count];

    [self.PacketCount setStringValue:str_count];
    //Populate the data
    [myObject.macArray replaceObjectAtIndex:index withObject:mac1];
    
    [myObject.ssidArray replaceObjectAtIndex:index withObject:mac2];
    
    [myObject.sigArray replaceObjectAtIndex:index withObject:sig];
    
    [myObject.tsArray replaceObjectAtIndex:index withObject:theDate];
    [myObject.vendorArray replaceObjectAtIndex:index withObject:vendor];
    
    index++;
    
    if(index >= DISPLAY_SIZE) index = 0;
    
    // Refresh table
    [self.OutputTable reloadData];

   
}

- (IBAction)PacketType:(NSPopUpButtonCell *)sender {

    NSLog(@"Pop up button %@", [sender titleOfSelectedItem]);
    if([[sender titleOfSelectedItem] isEqualToString:@"Clients"])
        packet_type = 1;
    else if([[sender titleOfSelectedItem] isEqualToString:@"Access points"])
        packet_type = 2;
    else if([[sender titleOfSelectedItem] isEqualToString:@"Both"])
        packet_type = 3;
   
    //[sender selectItemAtIndex:0];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    /* If we want to exit the app on close */

    return YES;
}
- (IBAction)about_action:(NSButtonCell *)sender {

    NSApplication *app = [NSApplication sharedApplication];
    [app activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
    [sender setBackgroundColor:[NSColor redColor]];
}

- (IBAction)ActionStart:(NSButton *)sender {
    static int scan_state = 0;
    static int count = 0;
    
    NSString *interface = [self.Interfaceselect objectValueOfSelectedItem];
    
    if(scan_state == 1) {
        
        stop_scan();
        self.StartButton.Title = @"Start Scanning";
        NSLog(@"Stopped the scanning on %@", interface);
        scan_state = 0;
            [self.OutputTable setBackgroundColor: [ NSColor windowBackgroundColor]];
        [self.TextSignal setTextColor:[NSColor blackColor]];
        [self.TextMac setTextColor:[NSColor blackColor]];
        [self.TextSSID setTextColor:[NSColor blackColor]];
        [self.TextLastSeen setTextColor:[NSColor blackColor]];
        [self.TextVendor setTextColor:[NSColor blackColor]];
        [self.Interfaceselect setEnabled:TRUE];
        return;
    }
    
    if (interface == NULL) {
        NSLog(@"Unable to scan on NULL interface");
        return;
    }
    char errstring[100]; /* XXX */
    if(setup_scan((char *)[interface UTF8String], errstring)) {
        NSAlert* msgBox = [[NSAlert alloc] init];

        NSString *message = [NSString stringWithFormat: @"Unable to setup scan for %@: %s.", interface, errstring];
        [msgBox setMessageText: message];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
        scan_state = 0;
        return;
    }

    [[self.StartButton cell] setBackgroundColor:[NSColor greenColor]];
    NSLog(@"Started the scanning on %@", interface);
    [self.OutputTable setBackgroundColor: [ NSColor blackColor]];
    [self.TextSignal setTextColor:[NSColor greenColor]];
    [self.TextMac setTextColor:[NSColor blueColor]];
    [self.TextSSID setTextColor:[NSColor redColor]];
    [self.TextLastSeen setTextColor:[NSColor yellowColor]];
    [self.TextVendor setTextColor:[NSColor orangeColor]];
    
    self.StartButton.Title = @"Stop Scanning";
    scan_state = 1;
    count++;
    /* Create a new thread to spawn off scan */
    NSThread* evtThread = [ [NSThread alloc] initWithTarget:self
                                                   selector:@selector( scannerthread: )
                                                     object: interface ];
        [self.Interfaceselect setEnabled:FALSE];
    [ evtThread start ];
    //[self.OutputTable setBackgroundColor: [ NSColor blackColor]];
    //[self.OutputTable insertText:interface];
    
    
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    /* Ideally, this should read interface list and populate elements in the dropbox  like thus */
   // get_list_of_interfaces();
    [self.Interfaceselect addItemWithObjectValue: @"en0"];
    [self.Interfaceselect addItemWithObjectValue: @"en1"];
    [self.Interfaceselect addItemWithObjectValue: @"en2"];
    [self.Interfaceselect addItemWithObjectValue: @"en3"];
    
    /* set the index to point to 1 */
    [self.Interfaceselect selectItemAtIndex:1];
    [self.OutputTable setBackgroundColor: [ NSColor windowBackgroundColor]];
   // [self.OutputTable setDataSource:];
//    ScanData * zDataObject  = [[ScanData alloc] initWithParams:@"mac1" Ssid:@"mac2" Signal: @"sig"];
    myObject = [[ ScanData alloc] init];

    [self.OutputTable setDataSource: myObject];
    
    [self.OutputTable reloadData];

}

@end
