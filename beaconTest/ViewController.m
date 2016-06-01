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
#import <EstimoteSDK/EstimoteSDK.h>
#import <EstimoteSDK/ESTBeaconManager.h>
#import "BeaconInfo.h"
#import "BeaconDict.h"
#import "Trilateration.m"

@interface ViewController () <ESTBeaconManagerDelegate>
@property (nonatomic, strong) ESTBeacon *beacon;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) BeaconDict* beconDict;
@property (nonatomic, strong) NSMutableArray *tableData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
//    NSLog(@"beacons.count: %lu", (unsigned long)beacons.count);
    NSSortDescriptor *accuracyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accuracy" ascending:YES];
    NSArray *sortDescriptors = @[accuracyDescriptor];
    NSArray *sortedBeacons = [beacons sortedArrayUsingDescriptors:sortDescriptors];
    if (sortedBeacons.count > 0) {
        [self updateTableData:sortedBeacons];
    }
}

-(NSMutableArray *) getPoint:(NSInteger)x joinY:(NSInteger)y{
    NSMutableArray *retval = [[NSMutableArray alloc] initWithCapacity:0];
    [retval addObject:[NSNumber numberWithFloat:((625.12 * y - 312.56) / 100)]];
    [retval addObject:[NSNumber numberWithFloat:((4674.28 - 623.24 * x)/100)]];
    return retval;
}

-(void)updateTableData:(NSArray *)sortedBeacons
{
    [_tableData removeAllObjects];
    for(int i = 0; i < [sortedBeacons count]; ++i){
        ESTBeacon* currBeacon = sortedBeacons[i];
        NSInteger major = [[currBeacon major] integerValue];
        NSInteger minor = [[currBeacon minor] integerValue];
        CLLocationAccuracy accuracy = [currBeacon accuracy];
        coord currCoord = [_beconDict getCoord:major joinMinor:minor];
        if(accuracy < 0 || currCoord.x < 0 || currCoord.y < 0){
            continue;
        }
        NSString * currString =  [NSString stringWithFormat:@"x: %ld, y: %ld, distance: %f", (long)currCoord.x, (long)currCoord.y, accuracy];
        [_tableData addObject:currString];
    }
    
//        NSMutableArray *P1 = [[NSMutableArray alloc] initWithCapacity:0];
//        [P1 addObject:[NSNumber numberWithDouble:3]];
//        [P1 addObject:[NSNumber numberWithDouble:0]];
//    
//    
//        NSMutableArray *P2 = [[NSMutableArray alloc] initWithCapacity:0];
//        [P2 addObject:[NSNumber numberWithDouble:9]];
//        [P2 addObject:[NSNumber numberWithDouble:0]];
//    
//        NSMutableArray *P3 = [[NSMutableArray alloc] initWithCapacity:0];
//        [P3 addObject:[NSNumber numberWithDouble:4]];
//        [P3 addObject:[NSNumber numberWithDouble:8]];
//    
//        //this is the distance between all the points and the unknown point
//        float DistA = 6.4031;
//        float DistB = 4.1231;
//        float DistC = 5.6568;
    NSString *disp_text;
    if([sortedBeacons count] >= 3){
        ESTBeacon* firstBeacon = sortedBeacons[0], *secondBeacon = sortedBeacons[1], *thirdBeacon = sortedBeacons[2];
        coord firstCoord = [_beconDict getCoord:[[firstBeacon major] integerValue] joinMinor:[[firstBeacon minor] integerValue]];
        coord secondCoord = [_beconDict getCoord:[[secondBeacon major] integerValue] joinMinor:[[secondBeacon minor] integerValue]];
        coord thirdCoord = [_beconDict getCoord:[[thirdBeacon major] integerValue] joinMinor:[[thirdBeacon minor] integerValue]];
        NSMutableArray *P1 = [self getPoint:firstCoord.x joinY:firstCoord.y];
        NSMutableArray *P2 = [self getPoint:secondCoord.x joinY:secondCoord.y];
        NSMutableArray *P3 = [self getPoint:thirdCoord.x joinY:thirdCoord.y];
        float DistA = [firstBeacon accuracy];
        float DistB = [secondBeacon accuracy];
        float DistC = [thirdBeacon accuracy];
        userCoord coord = trilateration(P1, P2, P3, DistA, DistB, DistC);
        disp_text = [NSString stringWithFormat:@"User's Location:\nx: %f, y: %f", coord.x, coord.y];
    }
    else{
        disp_text= [NSString stringWithFormat:@"User's Location:\n unavailable"];
    }
    [self.lable setText:disp_text];
    [self.tableView reloadData] ;
}

@end
