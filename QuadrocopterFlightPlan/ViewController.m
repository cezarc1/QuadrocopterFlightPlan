//
//  ViewController.m
//  ARDrone
//
//  Created by Chris Eidhof on 29.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "ViewController.h"
#import "DroneCommunicator.h"
#import "Navigator.h"
#import "DroneNavigationState.h"
#import "DroneController.h"
#import "RemoteClient.h"
#import <MobileCoreServices/MobileCoreServices.h>

@import MultipeerConnectivity;

@interface ViewController () <DroneControllerDelegate, RemoteClientDelegate, CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
}

@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) DroneController *droneController;
@property (nonatomic, strong) Navigator *navigator;
@property (nonatomic, strong) RemoteClient *remoteClient;
@property (nonatomic, strong) DroneCommunicator *communicator;

@end



@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.communicator = [[DroneCommunicator alloc] init];
    [self.communicator setupDefaults];

    self.navigator = [[Navigator alloc] init];
    self.droneController = [[DroneController alloc] initWithCommunicator:self.communicator navigator:self.navigator];
    self.droneController.delegate = self;
    
    self.remoteClient = [[RemoteClient alloc] init];
    [self.remoteClient startBrowsing];
    self.remoteClient.navigator = self.navigator;
    self.remoteClient.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.droneController start];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self.droneController stop];
}

- (void)updateDisplay
{
    DroneNavigationState *droneState = self.communicator.navigationState;
    
    self.textView.text = droneState ? droneState.description : @"NO DATA";
    [self updateDroneStatus];
    [self updateClientStatus];

    self.labelStatusDrone.text = droneState ? droneState.controlStateDescription : @"Unknown";
    self.labelInternalStatusDrone.text = self.droneController.droneActivityDescription;
    
    NSString *direction = [NSString stringWithFormat:@"%f°", self.navigator.directionDifferenceToTarget];
    self.labelDirectionDifferenceToTarget.text = direction;
    
    NSString *distance = [NSString stringWithFormat:@"%f meters", self.navigator.distanceToTarget];
    self.labelDistanceToTarget.text = distance;
    
    NSString *rotationSpeed = [NSString stringWithFormat:@"%f ", self.communicator.rotationSpeed];
    self.labelRotationSpeed.text = rotationSpeed;
    
    NSString *fowardSpeed = [NSString stringWithFormat:@"%f ", self.communicator.forwardSpeed];
    self.labelFowardSpeed.text = fowardSpeed;
}

- (void)updateClientStatus
{
    switch (self.remoteClient.session.connectedPeers.count) {
        case 0:
            self.labelConnectionStatusClient.text = @"Disconnected";
            self.labelConnectionStatusClient.textColor = [UIColor redColor];
            break;
    
        default:
            self.labelConnectionStatusClient.text = @"Connected";
            self.labelConnectionStatusClient.textColor = [UIColor greenColor];
            break;
    }
    NSMutableString *clientDesc = [NSMutableString stringWithFormat:@"%lu Clients: ", (unsigned long)self.remoteClient.session.connectedPeers.count];
    for (MCPeerID *peer in self.remoteClient.session.connectedPeers) {
        [clientDesc appendString:peer.displayName];
    }
    self.labelNamesClients.text = clientDesc;
}

- (void)updateDroneStatus
{
    DroneNavigationState *droneState = self.communicator.navigationState;
    BOOL hasConnection = (droneState != nil) || droneState.controlState != DroneControlStateInvalid;
    
    if (!hasConnection) {
        self.labelConnectionStatusDrone.text = @"Disconnected";
        self.labelConnectionStatusDrone.textColor = [UIColor redColor];
        self.labelBatteryLevel.text = @"???";
        [self.communicator setupSockets];
        [self.communicator setupDefaults];
    } else {
        self.labelConnectionStatusDrone.text = @"Connected";
        self.labelConnectionStatusDrone.textColor = [UIColor greenColor];
        
        self.labelBatteryLevel.text = [NSString stringWithFormat:@"%d %%", droneState.batteryLevel];
        self.labelBatteryLevel.textColor = droneState.batteryLevel < 35 ? [UIColor redColor] : [UIColor greenColor];
    }
    
}

#pragma mark - DroneControllerDelegate
- (void)droneController:(DroneController *)controller updateTimerFired:(NSTimer *)fired
{
    [self updateDisplay];
}

- (void)droneController:(DroneController *)controller batteryUpdated:(NSNumber *)number
{
    [self.remoteClient sendDictionaryToAllPeers:@{@"battery": number}];
}

- (void)droneController:(DroneController *)controller droneStateUpdated:(NSString *)state
{
    [self.remoteClient sendDictionaryToAllPeers:@{@"droneState": state}];
}

#pragma mark - Actions

- (IBAction)takeoff:(id)sender {
    [self.droneController takeOff];
}

- (IBAction)hover:(id)sender {
    [self.droneController hover];
}

- (IBAction)land:(id)sender {
    [self.droneController land];
}

- (IBAction)reset:(id)sender {
    [self.communicator resetEmergency];
    self.droneController.droneActivity = DroneActivityNone;
}

#pragma mark RemoteClient delegate

- (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location
{
    [self.droneController goTo:location];
}

- (void)remoteClientDidReceiveResetCommand:(RemoteClient *)client
{
    [self reset:nil];
}

- (void)remoteClientDidReceiveTakeOffCommand:(RemoteClient *)client
{
    [self takeoff:nil];
}

- (void)remoteClientDidReceiveLandCommand:(RemoteClient *)client
{
    [self land:nil];
}

- (void)remoteClientDidReceiveStopCommand:(RemoteClient *)client
{
    [self hover:nil];
}

- (CLLocation *)remoteClientdidRequestDroneLocation:(RemoteClient *)client;
{
    return self.navigator.lastKnowLocation;
}

@end
