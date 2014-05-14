//
//  LocalClient.h
//  QuadrocopterFlightPlan
//
//  Created by Cezar Cocu on 5/10/14.
//  Copyright (c) 2014 Cezar Cocu, Ahmed Shaikh. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
@import MultipeerConnectivity;

@class LocalClient;

@protocol LocalClientDelegate <NSObject>

- (void)peerDidConnect:(MCPeerID *)peer;
- (void)peerDidDisconnect:(MCPeerID *)peer;
- (void)localClient:(LocalClient *)client didReceiveLocation:(CLLocation *)coordinate;
- (void)didReceiveBatteryInfo:(NSNumber *)battery;
- (void)didReceiveDoneState:(NSString *)state;

@end

@interface LocalClient : NSObject

@property (nonatomic, weak) id<LocalClientDelegate> delegate;

@property (nonatomic, strong) MCSession *session;

@property (nonatomic, strong) MCNearbyServiceBrowser *browser;

- (instancetype)initWithController:(UIViewController *)controller;

- (void)lookForPeers;

- (void)sendDictionaryToAllPeers:(NSDictionary *)dict;

@end
