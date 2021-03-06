//
//  AppDelegate.m
//  Espresshots
//
//  Created by Kostas on 16/02/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import "AppDelegate.h"
#import "App.h"
#import "Timeline.h"
@import HealthKit;

@interface AppDelegate ()

@property (nonatomic, strong) App *app;

@end

@implementation AppDelegate





#pragma mark - Application

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //[application setStatusBarHidden:YES];

    [self initApp];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    UINavigationController *navController = (UINavigationController *)[self.window rootViewController];
    Timeline *rootController = (Timeline *)[navController topViewController];
    [rootController refreshStatistics];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}





#pragma mark - Helpers

- (void)initApp {
    _app = [[App alloc] init];
    
    UINavigationController *navController = (UINavigationController *)[self.window rootViewController];
    Timeline *rootController = (Timeline *)[navController topViewController];
    [rootController setApp:_app];
}

@end
