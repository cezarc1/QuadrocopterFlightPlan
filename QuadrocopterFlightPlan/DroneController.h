//
// Created by chris on 06.01.14.
//

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@class DroneController;

typedef enum DroneActivity_e {
    DroneActivityNone,
    DroneActivityFlyToTarget,
    DroneActivityHover,
} DroneActivity;

@class DroneController;
@class DroneCommunicator;
@class Navigator;
@class CLLocation;

@protocol DroneControllerDelegate <NSObject>

- (void)droneController:(DroneController *)controller updateTimerFired:(NSTimer *)fired;
- (void)droneController:(DroneController *)controller batteryUpdated:(NSNumber *)number;
- (void)droneController:(DroneController *)controller droneStateUpdated:(NSString *)state;
@end

@interface DroneController : NSObject

@property (nonatomic) DroneActivity droneActivity;
@property (nonatomic,weak) id<DroneControllerDelegate> delegate;

- (id)initWithCommunicator:(DroneCommunicator *)communicator navigator:(Navigator *)navigator;
- (void)start;
- (void)stop;

- (void)goTo:(CLLocation *)newLocation;
- (void)takeOff;
- (void)land;
- (void)hover;

- (NSString *)droneActivityDescription;

@end
