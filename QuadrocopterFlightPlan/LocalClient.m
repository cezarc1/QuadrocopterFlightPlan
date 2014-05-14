//
//  LocalClient.m
//  QuadrocopterFlightPlan
//
//  Created by Cezar Cocu on 5/10/14.
//  Copyright (c) 2014 Cezar Cocu, Ahmed Shaikh. All rights reserved.
//

#import "LocalClient.h"


@interface LocalClient () <MCNearbyServiceBrowserDelegate, MCSessionDelegate>

@property (nonatomic, weak) UIViewController *controller;

@end

@implementation LocalClient

- (instancetype)initWithController:(UIViewController *)controller
{
    self = [super init];
    if (self) {
        MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:@"loc-broadcaster"];
        self.browser.delegate = self;
        
        self.session = [[MCSession alloc] initWithPeer:peerId
                                      securityIdentity:nil
                                  encryptionPreference:MCEncryptionNone];
        self.session.delegate = self;
        
        self.controller = controller;
    }
    return self;
}

- (void)lookForPeers
{

    [self.browser startBrowsingForPeers];
}

- (void)sendDictionaryToAllPeers:(NSDictionary *)dict
{
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
    if (!err) {
        if (![self.session sendData:jsonData
                            toPeers:self.session.connectedPeers
                           withMode:MCSessionSendDataReliable
                              error:&err]) {
            NSLog(@"[Error] %@", err);
        }
    } else {
         NSLog(@"[Error] %@", err);
    }
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate peerDidDisconnect:peerID];
    }];
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         NSNumber *latitude = result[@"latitude"];
         NSNumber *longitude = result[@"longitude"];
         NSNumber *batteryLevel = result[@"battery"];
         NSString *droneState = result[@"droneState"];
         
         if ([latitude isKindOfClass:[NSNumber class]] && [longitude isKindOfClass:[NSNumber class]]) {
             CLLocation* location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
             [self.delegate localClient:self didReceiveLocation:location];
         }
         if ([batteryLevel isKindOfClass:[NSNumber class]] ) {
             [self.delegate didReceiveBatteryInfo:batteryLevel];
         }
         if ([droneState isKindOfClass:[NSString class]]) {
             [self.delegate didReceiveDoneState:droneState];
         }
     }];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate peerDidConnect:peerID];
        }];
    }
}

@end
