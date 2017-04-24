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
@property (nonatomic, strong) CMMotionActivityManager* activityManager;
@property (nonatomic, strong) NSDictionary* sampleDict;
@property (nonatomic, strong) NSNumber* sprinklerX;
@property (nonatomic, strong) NSNumber* sprinklerY;
@property (weak, nonatomic) IBOutlet UIStepper *stepperX;
@property (weak, nonatomic) IBOutlet UIStepper *stepperY;
@property (weak, nonatomic) IBOutlet UITextField *XTextField;
@property (weak, nonatomic) IBOutlet UITextField *YTextfield;
@property (weak, nonatomic) IBOutlet UILabel *recordedLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@end

@implementation ViewController
{
    UIImageView *lib;
    UIImageView *userLocation;
}

- (IBAction)sprinklerXChanged:(id)sender {
    UITextField * textField = (UITextField *)sender;
    NSString* text = [textField text];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    _sprinklerX = [f numberFromString:text];
    if(_sprinklerX == nil){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Sprinkler X!"
                                                message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else{
        [_stepperX setValue:[_sprinklerX doubleValue]];
    }
}

- (IBAction)sprinklerYChanged:(id)sender {
    UITextField * textField = (UITextField *)sender;
    NSString* text = [textField text];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    _sprinklerY = [f numberFromString:text];
    if(_sprinklerY == nil){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Sprinkler Y!"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else{
        [_stepperY setValue:[_sprinklerY doubleValue]];
    }
}

- (IBAction)stepperXPressed:(id)sender {
    UIStepper* stepper = (UIStepper*) sender;
    NSInteger value = [stepper value];
    _sprinklerX = [NSNumber numberWithInteger:value];
    _XTextField.text = [NSString stringWithFormat:@"%ld", (long)[_sprinklerX integerValue]];
}

- (IBAction)stepperYPressed:(id)sender {
    UIStepper* stepper = (UIStepper*) sender;
    NSInteger value = [stepper value];
    _sprinklerY = [NSNumber numberWithInteger:value];
    _YTextfield.text = [NSString stringWithFormat:@"%ld", (long)[_sprinklerY integerValue]];
}

- (void)viewDidLoad {
    _sampleDict = nil;
    _sprinklerX = [NSNumber numberWithInteger:1];
    _sprinklerY = [NSNumber numberWithInteger:1];
    [_stepperX setValue:1];
    [_stepperY setValue:1];

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
    self.beaconManager.avoidUnknownStateBeacons = TRUE;
    self.beaconManager.preventUnknownUpdateCount = 3;
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

-(void)post:(NSData*)json{
    NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@"http://beacon-res.herokuapp.com/api/samples"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setValue:@"iOS" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:json];

    NSURLSession *session = [NSURLSession sharedSession];
    [_connectionLabel setText:@"Connecting..."];
    [[session dataTaskWithRequest:request
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                // handle response
                NSLog(@"Response received.");

                if(error){
                    NSLog(@"%@", error);
                }


                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                NSLog(@"%@", [NSString stringWithFormat:@"HTTP %ld", (long)[httpResponse statusCode]]);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self connectionLabel] setText:[NSString stringWithFormat:@"HTTP %ld", (long)[httpResponse statusCode]]];
                });
            }] resume];
}

-(void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
//    NSLog(@"beacons.count: %lu", (unsigned long)beacons.count);
//    NSSortDescriptor *accuracyDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accuracy" ascending:YES];
//    NSArray *sortDescriptors = @[accuracyDescriptor];
//    NSArray *sortedBeacons = [beacons sortedArrayUsingDescriptors:sortDescriptors];
    if (beacons.count > 0) {
        [self updateTableData:beacons];
        if(_sampleDict != nil){
            NSMutableArray* samples = (NSMutableArray*)_sampleDict[@"samples"];
            NSInteger length = [samples count];
            if(length < 100){
                [self recordSample:beacons samplesArray:samples];
                length = [samples count];
            }
            [_recordedLabel setText:[NSString stringWithFormat:@"%ld/100", (long)length]];
            if(length == 100){
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_sampleDict
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:&error];
                
                if (!jsonData) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"JSON Serialization error"
                                                                    message:error
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                } else {
                    [self post:jsonData];
                }
                _sampleDict = nil;
            }
        }
        
    }
}

-(void)recordSample:(NSArray*) beacons
       samplesArray:(NSMutableArray*) samples{
    NSMutableArray* sample =[[NSMutableArray alloc] init];
    for(int i =0; i < [beacons count]; ++i){
        ESTBeacon* currBeacon = beacons[i];
        CLLocationAccuracy accuracy = [currBeacon accuracy];
        CLProximity proximity = [currBeacon accuracy];
        NSInteger rssi  = [currBeacon rssi];
        
        NSDictionary* beacon = @{
                                 @"major" : [currBeacon major],
                                 @"minor" : [currBeacon minor],
                                 @"proximity": [NSNumber numberWithInteger:proximity] ,
                                 @"distance": [NSNumber numberWithDouble:accuracy] ,
                                 @"rssi": [NSNumber numberWithInteger:rssi]
                                 };
        [sample addObject:beacon];
    }
    [samples addObject:sample];
}

-(NSMutableArray *) getPoint:(NSInteger)x joinY:(NSInteger)y{
    NSMutableArray *retval = [[NSMutableArray alloc] initWithCapacity:0];
    [retval addObject:[NSNumber numberWithFloat:((625.12 * y - 312.56) / 100)]];
    [retval addObject:[NSNumber numberWithFloat:((4674.28 - 623.24 * x)/100)]];
    return retval;
}

- (IBAction)recordButtonPressed:(id)sender {
    _sampleDict = @{
                    @"sprinkler_x": _sprinklerX,
                    @"sprinkler_y": _sprinklerY,
                    @"samples": [[NSMutableArray alloc]init]
                    };
}

- (IBAction)resetButtonPressed:(id)sender {
    _sampleDict = nil;
    [_recordedLabel setText:@"0/100"];
    [_connectionLabel setText:@"Unknown"];
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

- (void)updateLabels:(CMPedometerData *)pedometerData {
    NSLog(@"%@", pedometerData);
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    formatter.maximumFractionDigits = 2;
    
    // step counting
    if ([CMPedometer isStepCountingAvailable]) {
        self.steps.text = [NSString stringWithFormat:@"#Steps %@", [formatter stringFromNumber:pedometerData.numberOfSteps]];
    } else {
        self.steps.text = @"#Steps N/A";
    }
    
    // distance
    if ([CMPedometer isDistanceAvailable]) {
        self.distance.text = [NSString stringWithFormat:@"Distance %@ m", [formatter stringFromNumber:pedometerData.distance]];
    } else {
        self.distance.text = @"Distance N/A";
    }
    
    // pace
    if ([CMPedometer isPaceAvailable] && pedometerData.currentPace) {
        self.pace.text = [NSString stringWithFormat:@"Pace %@ s/m", [formatter stringFromNumber:pedometerData.currentPace]];
        _refiner.avgSpeed = (1 / [pedometerData.currentPace floatValue] / 1000);
    } else {
        self.pace.text = @"Pace N/A";
    }
    
    // cadence
    if ([CMPedometer isCadenceAvailable] && pedometerData.currentCadence) {
        self.cadence.text = [NSString stringWithFormat:@"Cadence %@ steps/sec", [formatter stringFromNumber: pedometerData.currentCadence]];
    } else {
        self.cadence.text = @"Cadence N/A";
    }
    
}

- (void)updateActivityLabels:(CMMotionActivity *)activity {

}

@end
