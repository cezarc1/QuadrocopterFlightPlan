//
// Created by chris on 06.01.14.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

@class RemoteClient;
@class Navigator;
@class MCSession;

@protocol RemoteClientDelegate <NSObject>

- (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location;
- (CLLocation *)remoteClientdidRequestDroneLocation:(RemoteClient *)client;
- (void)remoteClientDidReceiveResetCommand:(RemoteClient *)client;
- (void)remoteClientDidReceiveTakeOffCommand:(RemoteClient *)client;
- (void)remoteClientDidReceiveLandCommand:(RemoteClient *)client;
- (void)remoteClientDidReceiveStopCommand:(RemoteClient *)client;
@end

@interface RemoteClient : NSObject

@property (nonatomic, weak) id<RemoteClientDelegate> delegate;
@property (nonatomic, weak) Navigator *navigator;
@property (nonatomic, strong) MCSession *session;

- (void)startBrowsing;
- (void)sendDictionaryToAllPeers:(NSDictionary *)dict;

@end
