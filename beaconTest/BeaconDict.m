//
//  BeaconDict.m
//  Beacon_Test
//
//  Created by Liu, Chang on 5/20/16.
//  Copyright © 2016 Liu, Chang. All rights reserved.
//

#import "BeaconDict.h"

@implementation BeaconDict
@synthesize dict = _dict;

-(id) init{
    self = [super init];
    _dict =[[NSMutableDictionary alloc] init];
    
    return self;
}

-(void) addBeacon:(NSInteger)major
        joinMinor:(NSInteger)minor
        joinX:(NSInteger) x
        joinY:(NSInteger) y
    {
        NSMutableDictionary *minorDict;
        minorDict = [_dict objectForKey:[NSString stringWithFormat:@"%ld",(long)major]];
        if(minorDict != nil){
//            NSLog(@"minorDict exists in BeaconDict");
        }
        
        else{
//            NSLog(@"minorDict does not exists in BeaconDict");
            minorDict = [[NSMutableDictionary alloc] init];
            [_dict setValue: minorDict forKey:[NSString stringWithFormat:@"%ld",(long)major]];

        }
        coord toInsert;
        toInsert.x = x;
        toInsert.y = y;
//        NSValue *toInsertEncode =  [[NSValue alloc] initWithBytes: &toInsert objCType: @encode(coord)];
        NSData *toInsertEncode = [NSData dataWithBytes:&toInsert length:sizeof(coord)];

        [minorDict setObject:toInsertEncode forKey:[NSString stringWithFormat:@"%ld",(long)minor]];
        NSData *retval =[minorDict objectForKey:[NSString stringWithFormat:@"%ld",(long)major]];
        coord new;
        [retval getBytes:&new];
//        NSLog(@"%@", _dict);
//        NSLog(@"%@", minorDict);


}

-(coord) getCoord:(NSInteger)major
           joinMinor:(NSInteger)minor{
//    NSLog(@"%@", _dict);
    coord retvalDecode;
    retvalDecode.x = -1;
    retvalDecode.y = -1;
    NSMutableDictionary *minorDict = [_dict objectForKey:[NSString stringWithFormat:@"%ld",(long)major]];
//    NSLog(@"%@", minorDict);
    if(minorDict){
        NSData* retval =[minorDict objectForKey:[NSString stringWithFormat:@"%ld",(long)minor]];
        if(retval){
            [retval getBytes:&retvalDecode];
        }
    }
    return retvalDecode;
}

-(NSMutableDictionary*) innerDict{
    return _dict;
}
@end
