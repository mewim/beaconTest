//
//  ViewController.m
//  iBeaconsYoutube
//
//  Created by Michael Kane on 10/2/14.
//  Copyright (c) 2014 Michael Kane. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <EstimoteSDK/EstimoteSDK.h>
#import <EstimoteSDK/ESTBeaconManager.h>
#import "BeaconInfo.h"
#import "BeaconDict.h"
#import "Trilateration.m"
#import "PositionRefiner.h"

@interface ViewController () <ESTBeaconManagerDelegate>
@property (nonatomic, strong) ESTBeacon *beacon;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) BeaconDict* beconDict;
@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) PositionRefiner *refiner;
@property (nonatomic, strong) CMPedometer *pedometer;
@end

@implementation ViewController
{
    UIImageView *lib;
    UIImageView *userLocation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register segment control
    [self.segments addTarget:self action:@selector(changeSegment:)
                    forControlEvents:UIControlEventValueChanged];
    
    // Adding UGL Map
    lib = [[UIImageView alloc] initWithFrame:CGRectMake(0, 164, 320, 320)];
    lib.image=[UIImage imageNamed:@"ugl_map.png"];
    [self.mapView addSubview:lib];
    
    // Adding User Location Pin
    userLocation = [[UIImageView alloc] initWithFrame:CGRectMake(150, 300, 20, 20)];
    userLocation.image=[UIImage imageNamed:@"user_image.png"];
    
    // Do not start the clock here, start when we get the first coord
    _refiner = nil;
    
    

    //Create your UUID
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407f30-f5f8-466e-aff9-25556b57fe6d"];
    
    //set up the beacon manager
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    //set up the beacon region
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
        identifier:@"RegionIdenifier"];
    
    //start the ranging
    [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
    
    //MUST have for IOS8
    [self.beaconManager requestAlwaysAuthorization];
    
    _beconDict = [BeaconInfo createBeaconDict];
    _tableData = [NSMutableArray array];


    NSLog(@"%@", _beconDict);
    
    // Ask permission for CoreMotion
    if([CMMotionActivityManager isActivityAvailable] && [CMPedometer isDistanceAvailable]){
        NSLog(@"CoreMotion is enabled.");
        _pedometer = [[CMPedometer alloc] init];
    }
    else{
       NSLog(@"CoreMotion is disabled or not supported.");
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [_tableData objectAtIndex:indexPath.row];
    return cell;
}

// checks permission status
-(void)beaconManager:(ESTBeaconManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"Status:%d", status);
}


-(void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"beacons.count: %lu", (unsigned long)beacons.count);
//    NSSortDescriptor *accuracyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accuracy" ascending:YES];
//    NSArray *sortDescriptors = @[accuracyDescriptor];
//    NSArray *sortedBeacons = [beacons sortedArrayUsingDescriptors:sortDescriptors];
    if (beacons.count > 0) {
        [self updateTableData:beacons];
    }
}

-(NSMutableArray *) getPoint:(NSInteger)x joinY:(NSInteger)y{
    NSMutableArray *retval = [[NSMutableArray alloc] initWithCapacity:0];
    [retval addObject:[NSNumber numberWithFloat:((625.12 * y - 312.56) / 100)]];
    [retval addObject:[NSNumber numberWithFloat:((4674.28 - 623.24 * x)/100)]];
    return retval;
}

-(void)updateTableData:(NSArray *)beacons
{
    [_tableData removeAllObjects];
    NSMutableArray * sortedBeacons = [NSMutableArray array];
    for(int i = 0; i < [beacons count]; ++i){
        ESTBeacon* currBeacon = beacons[i];
        NSInteger major = [[currBeacon major] integerValue];
        NSInteger minor = [[currBeacon minor] integerValue];
        CLLocationAccuracy accuracy = [currBeacon accuracy];
        coord currCoord = [_beconDict getCoord:major joinMinor:minor];
        if(accuracy < 0 || currCoord.x < 0 || currCoord.y < 0){
            continue;
        }
        [sortedBeacons addObject:currBeacon];
        NSString * currString =  [NSString stringWithFormat:@"x: %ld, y: %ld, distance: %f", (long)currCoord.x, (long)currCoord.y, accuracy];
        [_tableData addObject:currString];
    }
    
    NSString *disp_text, *refined_text;
    userCoord currCoord;
    currCoord.x = -1.0f;
    currCoord.y = -1.0f;

    
    if([sortedBeacons count] == 1){ // Only one beacon, just use its location
        // Just use the beacon as user location
        NSMutableArray *userCoordArr = [self getPoint:currCoord.x joinY:currCoord.y];
        currCoord.x = [userCoordArr[0] floatValue];
        currCoord.y = [userCoordArr[1] floatValue];
    }
    else if([sortedBeacons count] == 2){ // Two beacons
        ESTBeacon* firstBeacon = sortedBeacons[0], *secondBeacon = sortedBeacons[1];
        coord firstCoord = [_beconDict getCoord:[[firstBeacon major] integerValue] joinMinor:[[firstBeacon minor] integerValue]];
        coord secondCoord = [_beconDict getCoord:[[secondBeacon major] integerValue] joinMinor:[[secondBeacon minor] integerValue]];
        NSMutableArray *firstCoordArr = [self getPoint:firstCoord.x joinY:firstCoord.y];
        NSMutableArray *secondCoordArr = [self getPoint:secondCoord.x joinY:secondCoord.y];
        
        // Reference: http://math.stackexchange.com/questions/256100/how-can-i-find-the-points-at-which-two-circles-intersect
        double x1 = [firstCoordArr[0] floatValue];
        double y1 = [firstCoordArr[1] floatValue];
        double x2 = [secondCoordArr[0] floatValue];
        double y2 = [secondCoordArr[1] floatValue];
        double r1 = [firstBeacon accuracy];
        double r2 = [secondBeacon accuracy];
        double d = sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
        double l = (pow(r1, 2) - pow(r2, 2) + pow(d, 2)) / (2 * d);
//        double h = sqrt(pow(r1, 2) + pow(l, 2));

        currCoord.x = (l / d) * (x2 - x1) + x1;
        currCoord.y = (l / d) * (y2 - y1) + y1;

    }
    else if([sortedBeacons count] >= 3){ // Three beacons or more
        ESTBeacon* firstBeacon = sortedBeacons[0], *secondBeacon = sortedBeacons[1], *thirdBeacon = sortedBeacons[2];
        coord firstCoord = [_beconDict getCoord:[[firstBeacon major] integerValue] joinMinor:[[firstBeacon minor] integerValue]];
        coord secondCoord = [_beconDict getCoord:[[secondBeacon major] integerValue] joinMinor:[[secondBeacon minor] integerValue]];
        coord thirdCoord = [_beconDict getCoord:[[thirdBeacon major] integerValue] joinMinor:[[thirdBeacon minor] integerValue]];
        for(int i = 3; (((firstCoord.x == secondCoord.x) && (secondCoord.x == thirdCoord.x)) || ((firstCoord.y == secondCoord.y) && (secondCoord.y == thirdCoord.y))) && (i < [sortedBeacons count]); ++i){
            thirdBeacon = sortedBeacons[i];
            thirdCoord = [_beconDict getCoord:[[thirdBeacon major] integerValue] joinMinor:[[thirdBeacon minor] integerValue]];
        }
        if(((firstCoord.x == secondCoord.x) && (secondCoord.x == thirdCoord.x)) || ((firstCoord.y == secondCoord.y) && (secondCoord.y == thirdCoord.y))){ // We only have three beacons in a line, use two closest
            NSMutableArray *firstCoordArr = [self getPoint:firstCoord.x joinY:firstCoord.y];
            NSMutableArray *secondCoordArr = [self getPoint:secondCoord.x joinY:secondCoord.y];
            
            // Reference: http://math.stackexchange.com/questions/256100/how-can-i-find-the-points-at-which-two-circles-intersect
            double x1 = [firstCoordArr[0] floatValue];
            double y1 = [firstCoordArr[1] floatValue];
            double x2 = [secondCoordArr[0] floatValue];
            double y2 = [secondCoordArr[1] floatValue];
            double r1 = [firstBeacon accuracy];
            double r2 = [secondBeacon accuracy];
            double d = sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
            double l = (pow(r1, 2) - pow(r2, 2) + pow(d, 2)) / (2 * d);
            //        double h = sqrt(pow(r1, 2) + pow(l, 2));
            
            currCoord.x = (l / d) * (x2 - x1) + x1;
            currCoord.y = (l / d) * (y2 - y1) + y1;
        }
        else{ // We can do Trilateration
            NSMutableArray *P1 = [self getPoint:firstCoord.x joinY:firstCoord.y];
            NSMutableArray *P2 = [self getPoint:secondCoord.x joinY:secondCoord.y];
            NSMutableArray *P3 = [self getPoint:thirdCoord.x joinY:thirdCoord.y];
            float DistA = [firstBeacon accuracy];
            float DistB = [secondBeacon accuracy];
            float DistC = [thirdBeacon accuracy];
            currCoord = trilateration(P1, P2, P3, DistA, DistB, DistC);
        }

    }
    if (!isnan(currCoord.x) && !isnan(currCoord.y) && currCoord.x > 0 && currCoord.y > 0 && [sortedBeacons count] > 0){
        if(_refiner == nil){
            _refiner = [[PositionRefiner alloc] init];
        }
        userCoord refinedCoord = [_refiner refinePosition:currCoord];
        disp_text = [NSString stringWithFormat:@"Raw:\nx: %.2f, y: %.2f", currCoord.x, currCoord.y];
        refined_text= [NSString stringWithFormat:@"Refined:\nx: %.2f, y: %.2f", refinedCoord.x, refinedCoord.y];
        
        userCoord ORIGIN = {0.0, 0.0};
        userCoord canvasDims = {320, 320};
        userCoord MAP_DIMS = {56.244f, 55.9f};
        userCoord translated = {-1.0f, -1.0f};
        
        translated.x = (float) (refinedCoord.x + ORIGIN.x) * canvasDims.x / MAP_DIMS.x - 10.0;
        translated.x = (translated.x < 0)? 0: translated.x;
        translated.y = (float) (refinedCoord.y + ORIGIN.y) * canvasDims.y / MAP_DIMS.y + 154.0;
        CGRect newLocation = CGRectMake(translated.x, translated.y, 20, 20);
        userLocation.frame = newLocation;
        [self.mapView addSubview:userLocation];
    }
    else{
        disp_text= [NSString stringWithFormat:@"Raw:\n unavailable"];
        refined_text= [NSString stringWithFormat:@"Refined:\n unavailable"];

        //[userLocation removeFromSuperview];
    }
    [self.lable setText:disp_text];
    [self.refined setText:refined_text];

    [self.tableView reloadData] ;
    
    
}

-(void)changeSegment:(id)sender {
    switch(_segments.selectedSegmentIndex){
        case 0:
            self.beaconsView.hidden = TRUE;
            self.motionView.hidden = TRUE;
            self.mapView.hidden = FALSE;
            break;
        case 1:
            self.beaconsView.hidden = FALSE;
            self.motionView.hidden = TRUE;
            self.mapView.hidden = TRUE;
            break;
        case 2:
            self.beaconsView.hidden = TRUE;
            self.motionView.hidden = FALSE;
            self.mapView.hidden = TRUE;
            break;
        default:
            break;
    }
}
@end
