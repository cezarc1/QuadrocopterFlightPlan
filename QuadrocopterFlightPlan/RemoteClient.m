//
// Created by chris on 06.01.14.
//

#import "RemoteClient.h"
#import "Navigator.h"
#import <AudioToolbox/AudioServices.h>

@import MultipeerConnectivity;
@import CoreLocation;

#define CLCOORDINATE_EPSILON 0.0005f
#define CLCOORDINATES_EQUAL2( coord1, coord2 ) (fabs(coord1.latitude - coord2.latitude) < CLCOORDINATE_EPSILON && fabs(coord1.longitude - coord2.longitude) < CLCOORDINATE_EPSILON)

@interface RemoteClient () <MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, assign) CLLocationCoordinate2D lastSentDroneCord;

@end

@implementation RemoteClient

- (void)startBrowsing
{
    self.peerID = [[MCPeerID alloc] initWithDisplayName:@"Drone"];

    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID
                                                     discoveryInfo:nil
                                                       serviceType:@"loc-broadcaster"];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
    
    self.session = [[MCSession alloc] initWithPeer:self.peerID
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;

}

- (void)setNavigator:(Navigator *)navigator
{
    _navigator = navigator;
    
    NSString *key = NSStringFromSelector(@selector(lastKnowLocation));
    [_navigator addObserver:self
                 forKeyPath:key
                    options:NSKeyValueObservingOptionOld
                    context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"lastKnowLocation"] && (self.session.connectedPeers.count > 0)) {
        CLLocationCoordinate2D loc = self.navigator.lastKnowLocation.coordinate;
        NSDictionary *dict = @{@"latitude": @(loc.latitude),
                               @"longitude": @(loc.longitude)};
        [self sendDictionaryToAllPeers:dict];
    }
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

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{

    invitationHandler(YES, self.session);
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected) {
        CLLocation *loc = [self.delegate remoteClientdidRequestDroneLocation:self];
        if (loc) {
            self.lastSentDroneCord = loc.coordinate;
            
            NSDictionary *dict = @{@"latitude": @(loc.coordinate.latitude),
                                   @"longitude": @(loc.coordinate.longitude)};
            [self sendDictionaryToAllPeers:dict];
        }
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
}


- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSNumber* latitude = result[@"latitude"];
        NSNumber* longitude = result[@"longitude"];

        if ([latitude isKindOfClass:[NSNumber class]] && [longitude isKindOfClass:[NSNumber class]]) {
            CLLocation* location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
            [self.delegate remoteClient:self didReceiveTargetLocation:location];
        }

        if (result[@"land"]) {
            [self.delegate remoteClientDidReceiveLandCommand:self];
        }
        if (result[@"takeoff"]) {
            [self.delegate remoteClientDidReceiveTakeOffCommand:self];
        }
        if (result[@"reset"]) {
            [self.delegate remoteClientDidReceiveResetCommand:self];
        };
        if (result[@"stop"]) {
            [self.delegate remoteClientDidReceiveStopCommand:self];
        };
    }];
}

@end
