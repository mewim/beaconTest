//
//  PositionRefiner.h
//  beaconTest
//
//  Created by Liu, Chang on 6/8/16.
//  Copyright © 2016 Minrva Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Trilateration.m"
#include <sys/time.h>
#include <stdlib.h>
#define WALKING_SPEED_THRESHOLD 0.003
#define MOTION_UNKNOWN -1
#define MOTION_STATIONARY 0
#define MOTION_WALKING 1
#define MOTION_RUNNING 2
#define MOTION_CYCLING 3
#define MOTION_AUTO 4


@interface PositionRefiner : NSObject


@property(nonatomic, readwrite) Boolean started;
@property(nonatomic, readwrite) int motionStatus;
@property(nonatomic, readwrite) long prevTime;
@property(nonatomic, readwrite) long prevSteps;
@property(nonatomic, readwrite) float avgSpeed;
@property(nonatomic, readwrite) userCoord prevCoords;

- (id) init;

- (userCoord)refinePosition: (userCoord)coord;

- (long) getCurTime;

@end
