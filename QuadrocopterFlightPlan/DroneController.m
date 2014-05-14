//
// Created by chris on 06.01.14.
//

#import "DroneController.h"
#import "DroneCommunicator.h"
#import "Navigator.h"
#import "DroneNavigationState.h"

#define kQFPDroneDegreesDifferenceToGoFoward 65.
#define kQFPDroneMaxSpeedFoward 0.35

@interface DroneController ()

@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSTimer *navigationTimer;
@property (nonatomic, strong) DroneCommunicator *communicator;
@property (nonatomic, strong) Navigator *navigator;

@end

@implementation DroneController

- (id)initWithCommunicator:(DroneCommunicator*)communicator navigator:(Navigator*)navigator
{
    self = [super init];
    if (self) {
        self.communicator = communicator;
        self.navigator = navigator;
    }

    return self;
}


- (void)start
{
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                        target:self
                                                      selector:@selector(updateTimerFired:)
                                                      userInfo:nil
                                                       repeats:YES];
    self.navigationTimer = [NSTimer scheduledTimerWithTimeInterval:15
                                                            target:self
                                                          selector:@selector(refreshNavigationTimerFired:)
                                                          userInfo:nil
                                                           repeats:YES];
    
    NSString *key = NSStringFromSelector(@selector(navigationState));
    [self.communicator addObserver:self
                        forKeyPath:key
                           options:0
                           context:nil];
}

- (void)stop
{
    [self.updateTimer invalidate];
    [self.navigationTimer invalidate];
}

- (void)updateTimerFired:(NSTimer *)timer;
{
    [self.delegate droneController:self updateTimerFired:timer];
    
    switch (self.droneActivity) {
        case DroneActivityFlyToTarget:
            [self updateDroneCommands];
            break;
        case DroneActivityHover:
            [self.communicator hover];
            break;
        default:
            break;
    }
}

- (void)refreshNavigationTimerFired:(NSTimer *)timer
{
    [self.communicator refreshNavigationData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSString *key = NSStringFromSelector(@selector(navigationState));
    if ([keyPath isEqualToString:key]) {
        
        [self.delegate droneController:self batteryUpdated:@(self.communicator.navigationState.batteryLevel)];
    }
}



- (void)updateDroneCommands;
{
    if (self.navigator.distanceToTarget < self.navigator.lastKnowLocation.horizontalAccuracy) {
        NSLog(@"Drone: Arrived at destination");
        self.droneActivity = DroneActivityHover;
    } else {
        static double const rotationSpeedScale = 0.01;
        self.communicator.rotationSpeed = self.navigator.directionDifferenceToTarget * rotationSpeedScale;
        BOOL roughlyInRightDirection = fabs(self.navigator.directionDifferenceToTarget) < kQFPDroneDegreesDifferenceToGoFoward;
        self.communicator.forwardSpeed = roughlyInRightDirection ? [self fowardSpeedForDirectionDifference:self.navigator.directionDifferenceToTarget] : 0;
    }
}

- (double)fowardSpeedForDirectionDifference:(double)directionDifference
{
    double maxSpeed = [self maximumSpeedForDistanceLeft:self.navigator.distanceToTarget];
    double ddt = fabs(directionDifference);
    if (ddt == 0.0f) {
        return maxSpeed;
    }
    
    double percentAway = ddt / kQFPDroneDegreesDifferenceToGoFoward;
    double result = fabs((maxSpeed * percentAway) - maxSpeed);
    
    return result;
}

- (double)maximumSpeedForDistanceLeft:(double)distance
{
    if (distance < self.navigator.lastKnowLocation.horizontalAccuracy + 5) {
        return kQFPDroneMaxSpeedFoward * 0.75;
    }
    else {
        return kQFPDroneMaxSpeedFoward;
    }
}

- (void)takeOff
{
    if (! self.communicator.isFlying) {
        [self.communicator takeoff];
        [self.communicator hover];
        self.droneActivity = DroneActivityHover;
        // This is not very pretty. But we just wait a few seconds before doing anything.
        double delayInSeconds = 4.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.communicator.forceHover = NO;
        });
    } else {
        [self hover];
    }
}

- (void)hover
{
    if (self.communicator.isFlying) {
        [self.communicator hover];
        // This is not very pretty. But we just wait a few seconds before doing anything.
        self.droneActivity = DroneActivityHover;
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.communicator.forceHover = NO;
        });
    }
}

- (void)land
{
    [self.communicator land];
    self.droneActivity = DroneActivityNone;
}

- (void)reset
{
    [self.communicator resetEmergency];
    self.droneActivity = DroneActivityNone;
}

- (void)goTo:(CLLocation *)newLocation
{
    if (self.droneActivity == DroneActivityFlyToTarget || self.droneActivity == DroneActivityHover) {
        BOOL tooFar = [newLocation distanceFromLocation:self.navigator.lastKnowLocation] > 100;
        if (!tooFar) {
            self.navigator.targetLocation = newLocation;
            self.droneActivity = DroneActivityFlyToTarget;
        } else {
            NSLog(@"[ERROR] Received Location that is way too far away! Hovering");
            [self hover];
        }
    } else {
        NSLog(@"Received GO command but must be flying first!");
    }

}

- (NSString *)droneActivityDescription
{
    if (self.droneActivity == DroneActivityNone) {
        return @"None";
    } else if (self.droneActivity == DroneActivityHover) {
        return @"Hovering";
    } else {
        return @"Flying to Target";
    }
}

@end
