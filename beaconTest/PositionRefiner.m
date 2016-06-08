//
//  PositionRefiner.m
//  beaconTest
//
//  Created by Liu, Chang on 6/8/16.
//  Copyright © 2016 Minrva Project. All rights reserved.
//

#import "PositionRefiner.h"

@implementation PositionRefiner
-(id) init{
    self = [super init];
    _started = false;
    return self;
}

- (userCoord)refinePosition: (userCoord)coord{
    if (!_started) {
        _prevTime = [self getCurTime];
        _prevCoords = coord;
        _started = true;
        return coord;
    }
    
    long curTime = [self getCurTime];
    long elapsedTime = curTime - _prevTime;
    if (elapsedTime == 0) elapsedTime++; // Just to prevent crashes from dividing by zero
    NSLog(@"elapsedTime is %ld", elapsedTime);
    
    double x = coord.x - _prevCoords.x;
    double y = coord.y - _prevCoords.y;
    double distanceTraveled = fabs(x) + fabs(y); // Use Manhattan distance for now
    NSLog(@"Distance is %f, x is %f,  y is %f", distanceTraveled, x, y);

    // Now check if user could have actually traveled that distance in that time
    // Average walking speed according to Wikipedia is 1.4 m/s or 0.14 cm/ms
    // So we will use 2.0 as our cutoff for now
    double purportedSpeed = distanceTraveled / elapsedTime;
    NSLog(@"speed %f", purportedSpeed);
    NSLog(@"prevCoords: %f, %f", _prevCoords.x, _prevCoords.y);
    userCoord newCoords;
    if (purportedSpeed <= 0.003) {
        // It is possible the user walked here fast enough, so the coords are valid
        newCoords = coord;
    } else {
        // It is unlikely the user walked here fast enough, so only move them a little bit.
        // Move the user slightly in the direction they were calculated to be in, just in case
        // they really are moving to that position.
        newCoords.x = _prevCoords.x + (x * 0.20);
        newCoords.y = _prevCoords.y + (y * 0.20);
    }
    
    _prevTime = curTime;
    _prevCoords = newCoords;
    NSLog(@"newCoords: %f, %f", newCoords.x, newCoords.y);
    return newCoords;
}

-(long) getCurTime{
    struct timeval time;
    gettimeofday(&time, NULL);
    long millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);
    return millis;
}

@end
