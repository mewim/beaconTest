//
//  ViewController.h
//  iBeaconsYoutube
//
//  Created by Michael Kane on 10/2/14.
//  Copyright (c) 2014 Michael Kane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel* lable;
@property (strong, nonatomic) IBOutlet UILabel* refined;
@property (strong, nonatomic) IBOutlet UIView *motionView;
@property (strong, nonatomic) IBOutlet UIView *beaconsView;
@property (strong, nonatomic) IBOutlet UIView *mapView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segments;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *pace;
@property (weak, nonatomic) IBOutlet UILabel *cadence;
@property (weak, nonatomic) IBOutlet UILabel *steps;
- (IBAction)startButton:(id)sender;
- (IBAction)stopButton:(id)sender;

@end

