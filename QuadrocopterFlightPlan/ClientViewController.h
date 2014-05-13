//
//  ClientViewController.h
//  QuadrocopterFlightPlan
//
//  Created by Cezar Cocu on 5/10/14.
//  Copyright (c) 2014 Cezar Cocu, Ahmed Shaikh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapKit/Mapkit.h"
@import MultipeerConnectivity;

@interface ClientViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *droneMap;

@end
