//
//  BeaconInfo.m
//  Beacon_Test
//
//  Created by Liu, Chang on 5/25/16.
//  Copyright © 2016 Liu, Chang. All rights reserved.
//

#import "BeaconInfo.h"

@implementation BeaconInfo
+(void) resetNSUserDefaults{
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
}

+(NSInteger)getLocalVersion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger localVersion = [defaults integerForKey:@"beaconVersion"];
    if(localVersion != 0){
        return localVersion;
    }
    return -1;
}

+(void)setLocalVersion:(NSInteger)newVersion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:newVersion forKey:@"beaconVersion"];
    [defaults synchronize];
}

+(NSInteger)getOnlineVersion
{
    NSError *error = nil, *parseError = nil;
    NSString *beaconVersionURL= [[[NSString alloc] init ] stringByAppendingString:beaconVersionAPI];
    //    NSLog(@"beaconVersionURL:%@",beaconVersionURL);
    NSData * beaconVersionDATA = [NSData dataWithContentsOfURL:[NSURL URLWithString:beaconVersionURL]];
    if (error!=nil) {
        NSLog(@"%s: get beaconVersionDATA error: %@", __FUNCTION__, error);
        return -1;
    }
    NSDictionary *beaconVersionDict = [NSJSONSerialization JSONObjectWithData:beaconVersionDATA options:0 error:&parseError];
    if (!beaconVersionDict) {
        NSLog(@"%s: JSONObjectWithData error: %@; data = %@", __FUNCTION__, parseError, [[NSString alloc] initWithData:beaconVersionDATA encoding:NSUTF8StringEncoding]);
        return -1;
    }
    //    NSLog(@"beaconVersionDict: %@",beaconVersionDict);
    NSString * beaconVersionString = beaconVersionDict[@("id")];
    NSInteger beaconVersion = [beaconVersionString integerValue];
    //    NSLog(@"beaconVersion: %ld",(long)beaconVersion);
    return beaconVersion;
}

+(NSArray*)getLocalInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray* localInfo = [defaults objectForKey:@"beaconInfo"];
    return localInfo;
}

+(void)setLocalInfo:(NSArray*)newInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: newInfo forKey:@"beaconInfo"];
    [defaults synchronize];
}

+(NSArray* )getOnlineInfo
{
    NSError *error = nil, *parseError = nil;
    NSString *beaconInfoURL= [[[NSString alloc] init ] stringByAppendingString:beaconInfoAPI];
    //    NSLog(@"beaconInfoURL:%@",beaconInfoURL);
    NSData * beaconInfoDATA = [NSData dataWithContentsOfURL:[NSURL URLWithString:beaconInfoURL]];
    if (error!=nil) {
        NSLog(@"%s: get beaconInfoDATA error: %@", __FUNCTION__, error);
        return nil;
    }
    NSDictionary *beaconInfoDict = [NSJSONSerialization JSONObjectWithData:beaconInfoDATA options:0 error:&parseError];
    if (!beaconInfoDict) {
        NSLog(@"%s: JSONObjectWithData error: %@; data = %@", __FUNCTION__, parseError, [[NSString alloc] initWithData:beaconInfoDATA encoding:NSUTF8StringEncoding]);
        return nil;
    }
    NSArray *beaconInfoArray = beaconInfoDict.copy;
    //    NSLog(@"beaconInfoArray: %@",copiedArray);
    //    NSLog(@"beaconInfoArray0: %@",copiedArray[0]);
    //    NSLog(@"beaconInfoDict: %@",beaconInfoDict[0]);
    return beaconInfoArray;
}

+(NSArray* )getBeaconInfo
{
    NSInteger localVersion = [self getLocalVersion];
    NSLog(@"localVersion: %ld",(long)localVersion);
    NSInteger onlineVersion = [self getOnlineVersion];
    NSLog(@"onlineVersion: %ld",(long)onlineVersion);
    NSArray* beaconInfo = nil;
    if(onlineVersion!= -1 && (localVersion == -1 || localVersion != onlineVersion)){
        NSLog(@"Get beaconInfo online");
        beaconInfo = [self getOnlineInfo];
        if(beaconInfo != nil){
            [self setLocalVersion:onlineVersion];
            [self setLocalInfo:beaconInfo];
        }
        else{
            NSLog(@"CANNOT Get beaconInfo online");
        }
    }
    if(beaconInfo == nil){
        NSLog(@"Get beaconInfo from local");
        beaconInfo = [self getLocalInfo];
    }
    //    NSLog(@"beaconInfo: %@",beaconInfo);
    NSLog(@"Count of beacons: %lu", (unsigned long)[beaconInfo count]);
    NSLog(@"First elem in beaconInfo: %@",beaconInfo[0]);
    //    NSString* description_0 = beaconInfo[0][@("description")];
    //    NSInteger major_0 = [beaconInfo[0][@("major")] integerValue];
    //    NSInteger minor_0 = [beaconInfo[0][@("minor")] integerValue];
    //    NSString* uuid_0 = beaconInfo[0][@("uuid")];
    //    NSInteger x_0 = [beaconInfo[0][@("x")] integerValue];
    //    NSInteger y_0 = [beaconInfo[0][@("y")] integerValue];
    //    NSInteger z_0 = [beaconInfo[0][@("z")] integerValue];
    //    NSLog(@"'description' for first elem in beaconInfo: %@",description_0);
    //    NSLog(@"'major' for first elem in beaconInfo: %ld",(long)major_0);
    //    NSLog(@"'minor' for first elem in beaconInfo: %ld",(long)minor_0);
    //    NSLog(@"'uuid' for first elem in beaconInfo: %@",uuid_0);
    //    NSLog(@"'x' for first elem in beaconInfo: %ld",(long)x_0);
    //    NSLog(@"'y' for first elem in beaconInfo: %ld",(long)y_0);
    //    NSLog(@"'z' for first elem in beaconInfo: %ld",(long)z_0);
    return beaconInfo;
}

+(BeaconDict* ) createBeaconDict{
    NSArray* beaconInfo = [self getBeaconInfo];
    BeaconDict* retval = [[BeaconDict alloc]init];
    for (id curr in beaconInfo) {
        NSInteger x = [curr[@("x")] integerValue];
        NSInteger y = [curr[@("y")] integerValue];
        NSInteger major = [curr[@("major")] integerValue];
        NSInteger minor = [curr[@("minor")] integerValue];
        [retval addBeacon:major joinMinor:minor joinX:x joinY:y];
    }
    NSLog(@"%@", [retval innerDict]);
    return retval;
}
@end
