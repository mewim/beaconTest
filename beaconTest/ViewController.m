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
#include "BeaconDict.h"

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
    [self.tableView reloadData] ;
}

@end
