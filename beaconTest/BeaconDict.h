//
//  BeaconDict.h
//  Beacon_Test
//
//  Created by Liu, Chang on 5/20/16.
//  Copyright © 2016 Liu, Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef struct coord{
    NSInteger x;
    NSInteger y;
}coord;

@interface BeaconDict : NSObject

@property(copy, nonatomic, readwrite) NSMutableDictionary* dict;

-(id) init;

-(void) addBeacon:(NSInteger)major
        joinMinor:(NSInteger)minor
        joinX:(NSInteger) x
        joinY:(NSInteger) y;

-(coord) getCoord:(NSInteger)major
                 joinMinor:(NSInteger)minor;

-(NSMutableDictionary*) innerDict;
@end
