//
//  ViewController.h
//  ARDrone
//
//  Created by Chris Eidhof on 29.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *labelConnectionStatusDrone;
@property (weak, nonatomic) IBOutlet UILabel *labelConnectionStatusClient;
@property (weak, nonatomic) IBOutlet UILabel *labelStatusDrone;
@property (weak, nonatomic) IBOutlet UILabel *labelInternalStatusDrone;
@property (weak, nonatomic) IBOutlet UILabel *labelDirectionDifferenceToTarget;
@property (weak, nonatomic) IBOutlet UILabel *labelDistanceToTarget;
@property (weak, nonatomic) IBOutlet UILabel *labelRotationSpeed;
@property (weak, nonatomic) IBOutlet UILabel *labelFowardSpeed;
@property (weak, nonatomic) IBOutlet UILabel *labelNamesClients;
@property (weak, nonatomic) IBOutlet UILabel *labelBatteryLevel;



@end
