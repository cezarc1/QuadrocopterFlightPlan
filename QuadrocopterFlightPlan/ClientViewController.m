//
//  ClientViewController.m
//  QuadrocopterFlightPlan
//
//  Created by Cezar Cocu on 5/10/14.
//  Copyright (c) 2014 Cezar Cocu, Ahmed Shaikh. All rights reserved.
//

#import "ClientViewController.h"
#import "LocalClient.h"
#import <AudioToolbox/AudioServices.h>
@import CoreLocation;
@import MultipeerConnectivity;

@interface ClientViewController () <LocalClientDelegate>

@property (assign, nonatomic) CLLocationCoordinate2D destinationCoordinate;
@property (strong, nonatomic) LocalClient *localClient;
@property (strong, nonatomic) MKPointAnnotation *lastDroppedPin;
@property (weak, nonatomic) MKPointAnnotation *lastDronePosition;
@property (weak, nonatomic) IBOutlet UILabel *droneStatusConnectionLabel;

@end

@implementation ClientViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.droneMap.delegate = self;
    self.droneMap.showsUserLocation = YES;
    self.droneMap.userTrackingMode = MKUserTrackingModeFollow;
    self.localClient = [[LocalClient alloc] initWithController:self];
    self.localClient.delegate = self;
    
    [self.localClient lookForPeers];
    [self setupPressForPin];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.droneMap.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.001;
    mapRegion.span.longitudeDelta = 0.001;
    [self.droneMap setRegion:mapRegion];
}

- (MKPointAnnotation *)lastDronePosition
{
    static MKPointAnnotation *position;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        position = [[MKPointAnnotation alloc] init];
        [self.droneMap addAnnotation:position];
    });
    
    return position;
}

- (void)setupPressForPin
{
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(dropPinGesureDetected:)];
    longGesture.minimumPressDuration = 1.0;
    [self.droneMap addGestureRecognizer:longGesture];
    
    self.lastDroppedPin = [[MKPointAnnotation alloc] init];
    
    [self.droneMap addAnnotation:self.lastDroppedPin];
}

- (void)dropPinGesureDetected:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.droneMap];
    CLLocationCoordinate2D touchMapCoordinate = [self.droneMap convertPoint:touchPoint toCoordinateFromView:self.droneMap];
    self.destinationCoordinate = touchMapCoordinate;

    self.lastDroppedPin.coordinate = touchMapCoordinate;
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView
didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.005;
    mapRegion.span.longitudeDelta = 0.005;
    
    //[mapView setRegion:mapRegion animated: YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
    MKPinAnnotationView *annView = nil;
    
    if ([annotation isEqual:self.lastDroppedPin]) {
        annView = [[MKPinAnnotationView alloc]
                   initWithAnnotation:annotation
                   reuseIdentifier:@"destinationPin"];
        annView.pinColor = MKPinAnnotationColorGreen;
    } else if ([annotation isEqual:self.lastDronePosition]) {
        annView = [[MKPinAnnotationView alloc]
                   initWithAnnotation:annotation
                   reuseIdentifier:@"dronePin"];
        annView.pinColor = MKPinAnnotationColorRed;
    }
    
    return annView;
}



#pragma mark - LocalClientDelegate

- (void)peerDidConnect:(MCPeerID *)peer
{
    self.droneStatusConnectionLabel.text = @"Connected";
    self.droneStatusConnectionLabel.textColor = [UIColor greenColor];

}

- (void)peerDidDisconnect:(MCPeerID *)peer
{
    if (self.localClient.session.connectedPeers.count == 0) {
        self.droneStatusConnectionLabel.text = @"Disconnected";
        self.droneStatusConnectionLabel.textColor = [UIColor redColor];
    }
}

- (void)localClient:(LocalClient *)client didReceiveLocation:(CLLocation *)coordinate
{
    MKPointAnnotation *annot = self.lastDronePosition;
    annot.coordinate = coordinate.coordinate;
}

- (void)didReceiveBatteryInfo:(NSNumber *)battery
{
    NSString *percentString = [NSString stringWithFormat:@"%@ %%", battery];
    self.labelBatteryPercent.text = percentString;
    self.labelBatteryPercent.textColor = battery.intValue < 35 ? [UIColor redColor] : [UIColor greenColor];
    
}

#pragma mark - actions

- (IBAction)goPressed:(id)sender
{
    CLLocation *destinationLocation = [[CLLocation alloc] initWithCoordinate:self.destinationCoordinate altitude:3 horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    
        CLLocation *droneLocation = [[CLLocation alloc] initWithCoordinate:self.lastDronePosition.coordinate altitude:3 horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    
    BOOL tooFar = [destinationLocation distanceFromLocation:droneLocation] > 100;
    if (tooFar) {
        [[[UIAlertView alloc] initWithTitle:@"Too far away!"
                                    message:@"Please select something closer than 100 meters from the drone"
                                   delegate:nil
                          cancelButtonTitle:@"OK!" otherButtonTitles:nil, nil] show];
        return;
    }
    
    
    if ((self.destinationCoordinate.latitude != 0) && (self.destinationCoordinate.longitude != 0)) {
        NSNumber *latitude = @(self.destinationCoordinate.latitude);
        NSNumber *longitude = @(self.destinationCoordinate.longitude);
        NSDictionary *destination = @{@"latitude": latitude,
                                      @"longitude": longitude};
        
        [self.localClient sendDictionaryToAllPeers:destination];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Can't go there"
                                    message:@"Please select a valid point to go"
                                   delegate:nil
                          cancelButtonTitle:@"Darn" otherButtonTitles:nil, nil] show];
    }

}

- (IBAction)stopPressed:(id)sender
{
    [self.localClient sendDictionaryToAllPeers:@{@"stop": @YES}];
}
- (IBAction)resetPressed:(id)sender
{
    [self.localClient sendDictionaryToAllPeers:@{@"reset": @YES}];
}

- (IBAction)takeOffPressed:(id)sender
{
    [self.localClient sendDictionaryToAllPeers:@{@"takeoff": @YES}];
}

- (IBAction)landPressed:(id)sender
{
    [self.localClient sendDictionaryToAllPeers:@{@"land": @YES}];
}

@end
