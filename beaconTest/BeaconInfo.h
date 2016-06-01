//
//  BeaconInfo.h
//  Beacon_Test
//
//  Created by Liu, Chang on 5/25/16.
//  Copyright © 2016 Liu, Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeaconDict.h"
#define beaconVersionAPI @"http://minrva-dev.library.illinois.edu:8080/estimote/rest/v1.0/version"
#define beaconInfoAPI @"http://minrva-dev.library.illinois.edu:8080/estimote/rest/v1.0/beacons"

@interface BeaconInfo : NSObject
+(void) resetNSUserDefaults;

+(NSInteger)getLocalVersion;

+(void)setLocalVersion:(NSInteger)newVersion;

+(NSInteger)getOnlineVersion;

+(NSArray*)getLocalInfo;

+(void)setLocalInfo:(NSArray*)newInfo;

+(NSArray* )getOnlineInfo;

+(NSArray* )getBeaconInfo;

+(BeaconDict* ) createBeaconDict;
@end
