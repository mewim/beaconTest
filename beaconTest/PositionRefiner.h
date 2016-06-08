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

@interface PositionRefiner : NSObject


@property(nonatomic, readwrite) Boolean started;
@property(nonatomic, readwrite) long prevTime;
@property(nonatomic, readwrite) userCoord prevCoords;

-(id) init;

- (userCoord)refinePosition: (userCoord)coord;

-(long) getCurTime;

@end
