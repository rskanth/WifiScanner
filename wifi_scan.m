//
//  wifi_scan.c
//  WifiScanner
//
//  Created by Sreekanth Rupavatharam on 11/1/13.
//  Copyright (c) 2013 Sreekanth Rupavatharam. All rights reserved.
//
#import "AppDelegate.h"
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include "pcap/pcap.h"
#define __packed __attribute__((__packed__))
#include "ieee80211.h"
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int  u32;
#include "ieee80211_radiotap.h"
#include "mac_vendor.h"

static int set_monitor_mode(pcap_t *p);
static void process_packet(u_char *arg, const struct pcap_pkthdr* pkthdr, const u_char * packet);
void setup_timer(int interval);
void house_keep_timer(int val);

int interval = 10;
void flush_mac_cache();

void
house_keep_timer(int val)
{
    struct itimerval timeout;
    int static count;
    
    timeout.it_interval.tv_sec = 0;
    timeout.it_interval.tv_usec = 0;
    
    timeout.it_value.tv_sec = interval;
    timeout.it_value.tv_usec = 0;
    setitimer(ITIMER_REAL, &timeout, 0);
    signal(SIGALRM, house_keep_timer);
    printf("timer: %d\n", count++);
    flush_mac_cache();
    
}

void
setup_timer(int interval)
{
    struct itimerval timeout;
    
    timeout.it_interval.tv_sec = 0;
    timeout.it_interval.tv_usec = 0;
    
    timeout.it_value.tv_sec = interval;
    timeout.it_value.tv_usec = 0;
    
    setitimer(ITIMER_REAL, &timeout, 0);
    signal(SIGALRM, house_keep_timer);
}
pcap_t *p;

int setup_scan(char *interface, char *err)
{
    int ret = 0;
    char errbuf[PCAP_ERRBUF_SIZE];
    
    printf("Start scanning on interface %s\n", interface);
    if(p == NULL)
        p = pcap_create(interface, errbuf);
    ret = set_monitor_mode(p);
    if(ret) {
        //printf("Set monitor mode failed %d\n", ret);
        sprintf(err, "%s", pcap_geterr(p));
        pcap_close(p);
        p = NULL;
        //pcap_perror(p, "Error string");
        return ret;
    }

    return ret;

}

int
start_scan(char *interface, void* self)
{
    if(p == NULL)
        return -1;
//        ret = setup_scan(interface);
//    if(ret) return ret;
    setup_timer(interval);
    if(pcap_loop(p, -1, process_packet, self) == -1) {
        fprintf(stderr, "ERROR: %s\n", pcap_geterr(p));
        return -1;
    }
    return 0;
}

#define le32toh(x) (x)
int get_rth_param(struct ieee80211_radiotap_header *rth, int param, void *out)
{
    int i, present;
    unsigned char *body;
    
    if(param < IEEE80211_RADIOTAP_TSFT ||
       param > IEEE80211_RADIOTAP_DATA_RETRIES)
        return EINVAL;
    if(out == NULL) return EINVAL;
    body = (unsigned char *)(rth+1);
    present = le32toh(rth->it_present);
    if(!(present  & (1 << param)))
        return ENOENT;
    for(i = 0; i < param;i++) {
        if(!(present & (1 << i)))
            continue;
        body += ieee80211_radiotap_sizes[i];
    }
    bcopy(body, out, ieee80211_radiotap_sizes[i]);
    return 0;
}

char *get_vendor(unsigned char * mac)
{
    char str[9];
    sprintf(str, "%02x-%02x-%02x", mac[0], mac[1], mac[2]);

    int i;
    int max = sizeof(mac_db) / sizeof(struct mac_info);
    
    /* need to put the table in a hash or tree */
    for(i = max-1;i > 0;i--) {
        if(!strcmp(mac_db[i].mac_prefix, str))
            break;
    }
    if(i > 0) {
//        printf("Index: %d %s\n", i, mac_db[i].vendor);
        return mac_db[i].vendor;
    }
    return "Unknown";
}

int get_signal_strength(struct ieee80211_radiotap_header *rth)
{
    char sig = 0;
    char noise = 0;
    int ret;
    
    ret = get_rth_param(rth, IEEE80211_RADIOTAP_DBM_ANTSIGNAL,
                        (void *)&sig);

    if(ret) {
        //              printf("get signal strength failed: %s\n", strerror(ret));
    }
    
    
    ret = get_rth_param(rth, IEEE80211_RADIOTAP_DBM_ANTNOISE,
                        (void *)&noise);
    if(ret) {
        //              printf("get signal strength failed: %s\n", strerror(ret));
    }
//    return (sig-noise);
    if(noise != 0)
        return sig * 100 /noise;
    else
    return sig;
}

#define MAX_SSID_LEN 32
char g_ssid[MAX_SSID_LEN+1];

#define IEEE80211_TSTAMP_LEN    8
#define IEEE80211_INTVL_LEN     2
#define IEEE80211_CAP_LEN       2

#define FIXED_HEADER_LEN (IEEE80211_TSTAMP_LEN + IEEE80211_INTVL_LEN +  \
IEEE80211_CAP_LEN)

char *get_ssid(struct ieee80211_frame *wh, int total, int offset)
{
    char *tags = ((char*)(wh+1)) + offset;
    unsigned int count = sizeof(*wh) + offset;
    unsigned int len = tags[1];
    
    if(len > total)
        printf("len: %d\n", len);
    if(count > total) {
        printf("total: %d\n", total);
        return NULL;
    }
/*
    while (tags[0] != 0 && count < total ) {
        len = tags[1];
        if(len < 0 && len > total) {
            printf("len: %d\n", len);
            return NULL;
        }
        tags += len + 2;
        count += len + 2;
    }
 */
    bzero(g_ssid, MAX_SSID_LEN);
    if(tags[0] == 0 && (len > 0 && len < MAX_SSID_LEN) ) {
        strncpy(g_ssid, (tags+2), len);
        g_ssid[len] = '\0';
      //  printf("SSID: %s (%d)\n", g_ssid, len);
        return g_ssid;
    }
    else {
        return NULL;
    }
    
    
}

#define MAX_CACHE_SIZE 100
unsigned char *mac_cache[MAX_CACHE_SIZE][6];
int cache_index = 0;

void
flush_mac_cache()
{
    printf("Flushing the cache\n");
    bzero(mac_cache, 100 * 6);/* XXX */
    cache_index = 0;
}

int
find_mac_in_cache(unsigned char *mac, int size)
{
    int i;
    for(i=0;i<cache_index;i++) {
        if(!bcmp(mac, mac_cache[i], 6)) {
      //      printf("found mac %02x:%02x:%02x:%02x:%02x:%02x in cache\n", mac[0], mac[1], mac[2],
        //           mac[3], mac[4], mac[5]);

            return 1;
        }
    }
    return 0;
}

int
add_mac_in_cache(unsigned char *mac, int size)
{
    if(cache_index == MAX_CACHE_SIZE-1) {
        printf("cache full\n");
        flush_mac_cache();
    }
    //printf("adding to cache: %02x:%02x:%02x:%02x:%02x:%02x\n", mac[0], mac[1], mac[2],
          //                          mac[3], mac[4], mac[5]);
    bcopy(mac, mac_cache[cache_index], 6);
    cache_index++;
    return 0;
}

static
int ok_to_display(int subtype, unsigned char *mac, id param)
{
    int found;
    
    found = find_mac_in_cache(mac, 6);
    if(found) return 0; // Display the mac only once every few seconds
    
    add_mac_in_cache(mac, 6);
    return 1;
}

#define print_mac(x) printf("%02x:%02x:%02x:%02x:%02x:%02x\n",(x)[0],(x)[1], \
(x)[2], (x)[3],(x)[4],(x)[5])

static void
process_packet(u_char *arg, const struct pcap_pkthdr* pkthdr,
               const u_char * packet)
{
    int static count = 0;
    int type, subtype;
    struct ieee80211_frame *wh;
    struct ieee80211_radiotap_header *rth;
    id param = (__bridge id)((void*)arg);
    char buf[100];
    int signal;

    rth = (struct ieee80211_radiotap_header*) packet;
    wh = (struct ieee80211_frame*)(packet + rth->it_len);
    
    
    
    type =  wh->i_fc[0] & IEEE80211_FC0_TYPE_MASK;

    if(type != IEEE80211_FC0_TYPE_MGT) return;
    
    subtype = wh->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK;

    if(subtype != IEEE80211_FC0_SUBTYPE_BEACON && subtype != IEEE80211_FC0_SUBTYPE_PROBE_REQ)
        return;
            
    count++;
            
    if(!ok_to_display(subtype, wh->i_addr2, param)) {
        return;
    }
            
    sprintf(buf, "%02x:%02x:%02x:%02x:%02x:%02x",
            wh->i_addr2[0], wh->i_addr2[1],
            wh->i_addr2[2], wh->i_addr2[3],
            wh->i_addr2[4], wh->i_addr2[5]);
            
    NSString *srcmac = [NSString stringWithUTF8String: buf];
        
    int offset = (subtype == IEEE80211_FC0_SUBTYPE_PROBE_REQ)? 0: FIXED_HEADER_LEN;
    char *ssid = get_ssid(wh, pkthdr->len, offset);
            
    NSString *ApMac;
            
    if(ssid != NULL) {
        ApMac = [[NSString alloc ] initWithUTF8String:ssid];
        if(ApMac == nil) {
            printf("SSID is NULL\n");
            return;
        }
    }
    else {
        sprintf(buf, "%02x:%02x:%02x:%02x:%02x:%02x",
            wh->i_addr3[0], wh->i_addr3[1],
            wh->i_addr3[2], wh->i_addr3[3],
            wh->i_addr3[4], wh->i_addr3[5]);
        ApMac = [[NSString alloc ] initWithUTF8String: buf];
    }

    if ([ srcmac isEqualToString:ApMac ] || [ ApMac isEqualToString:@"ff:ff:ff:ff:ff:ff" ])
        ApMac = @"---";

    
    signal = get_signal_strength(rth);
            
    sprintf(buf, "%d", signal);
            
    NSString *sig = [NSString stringWithUTF8String: buf];
            
    char *vendor_string = get_vendor(wh->i_addr2);
    NSString *vendor;

    if(vendor_string != NULL)
        vendor =[[NSString alloc] initWithUTF8String:vendor_string];
    else
        vendor = @"Unknown";
            
    [param capture_callback:srcmac apmac:ApMac signal:sig vendor: vendor type: subtype == IEEE80211_FC0_SUBTYPE_PROBE_REQ ? 1:2];
}

void
stop_scan()
{
    struct itimerval timeout;
    printf("Stopping the scan\n");
    pcap_breakloop(p);
    
    pcap_close(p);
    
    /* Stop the timer */
    timeout.it_interval.tv_sec = 0;
    timeout.it_interval.tv_usec = 0;
    
    timeout.it_value.tv_sec = 0;
    timeout.it_value.tv_usec = 0;

    setitimer(ITIMER_REAL, &timeout, 0);

    p = NULL;
    
    return;
}


static int set_monitor_mode(pcap_t *p)
{
    int ret;
    
    /* Set the monitor mode */

/*
    ret = pcap_can_set_rfmon(p);
    if(ret != 1) {
        printf("Monitor mode cannot be set: %s \n", pcap_geterr(p));
        return 1;
        
    }
*/
    ret = pcap_set_rfmon(p, 1);
    if(ret != 0) {
        //printf("Unable to set monitor mode: %s\n", pcap_geterr(p));
        return errno;
    }

    pcap_set_snaplen(p, 2048);
    pcap_set_promisc(p, 0);
    pcap_set_timeout(p, 512);
    
    ret = pcap_activate(p);
    if(ret != 0) {
        printf("pcap_activate failed: %d\n", ret);
        return ret;
    }
    return 0;
}