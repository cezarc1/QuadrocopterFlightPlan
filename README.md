QuadrocopterFlightPlan for iOS
======================

Extension on [objc.io's Quadrocopter Project](http://www.objc.io/issue-8/)

###Motivation

This project attempts to add a Flight Plan feature to Parrot's AR Drone. It attempts to accomplish this without Parrot's Flight Recorder.

This by using two iOS devices: One devices strapped to the drone and another acting as the "terminal" which the user interacts with.

![Remote Client](https://github.com/ggamecrazy/QuadrocopterFlightPlan/blob/master/Screenshots/Remote_Client.jpg?raw=true)
![Local Client](https://github.com/ggamecrazy/QuadrocopterFlightPlan/blob/master/Screenshots/Local_Client.jpg?raw=true)

The Red pin represents the Drone's Position and the Green pin represents the drones destination.

###Usage

####Building the Local Client or "Terminal"

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //Local
    ClientViewController *cvc = [[ClientViewController alloc] init];
    self.window.rootViewController = cvc;
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    return YES;
}

```

####Building the Remote Client or the iOS device attached to the drone

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //Remote
    self.vc = [[ViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.vc;
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    return YES;
}

```

### Features
* Communication between the iOS devices is accomplished via the multipeer connectivity introduced in iOS 7.
* Ability to land, Hover and choose a location which is outside the drone's range.
* Choosing a new waypoint is done by long pressing on the client map untill a pin appears then tapping "GO".

### License
This project is released under the MIT License.

