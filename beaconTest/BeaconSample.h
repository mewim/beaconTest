//
//  BeaconSample.h
//  beaconTest
//
//  Created by Liu, Chang on 6/8/16.
//  Copyright © 2016 Minrva Project. All rights reserved.
//

#import <Foundation/Foundation.h>
/*
 * Use struct inside double dictionary, just like BeaconDict
 * Considering: times seen and average distance of every beacon
 * Also need to remove beacons from other regions
 * Need to decide: dict structure (major, minor) -> (x, y, timesSeen, averageDistance) or (x, y) -> (timesSeen, averageDistance)
 *                 If we use the first structure, we may get rid of the BeaconDict, but a lot of code may need to be rewritten
 * Need to decide: sample interval (if sample interval is large, response is slow)
 * Maybe better to do this in C++
 * TODO: refactor: move all struct definition and functions, e.g. getCurTime to a single class named "util"
 * If this approach is better, we don't need refiner any more.
 * 
 * Notes by Chang on Jun 8
 */

#define SAMPLE_INTERVAL 10 // In ms

// Sample stuct
typedef struct {
    int x; // ?
    int y; // ?
    size_t timesSeen;
    float averageDistance;
}Sample;

@interface BeaconSample : NSObject

// Double dictionary
@property(copy, nonatomic, readwrite) NSMutableDictionary* dict;

// Refer to PositionRefiner
@property(nonatomic, readwrite) long prevTime;

-(id) init;

-(void) addSample :(NSInteger)x
                 Y:(NSInteger)y;

// Need to decide other functions here, should we do trilateration here or return some points and distances?

-(NSMutableDictionary*) innerDict;


@end
