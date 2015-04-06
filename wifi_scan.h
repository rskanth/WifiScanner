//
//  wifi_scan.h
//  WifiScanner
//
//  Created by Sreekanth Rupavatharam on 11/1/13.
//  Copyright (c) 2013 Sreekanth Rupavatharam. All rights reserved.
//

#ifndef WifiScanner_wifi_scan_h
#define WifiScanner_wifi_scan_h

int start_scan(char *interface, void *id);

int setup_scan(char *interface, char *err);

void stop_scan();

#endif
