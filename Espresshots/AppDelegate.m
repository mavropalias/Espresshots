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
    [self initApp];
    
    // Style app
    // -------------------------------------------------------------------------
    // page title
    [[UINavigationBar appearance] setTitleTextAttributes: @{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    
    // navigation bar background
    //[[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:(210.0f/255.0f) green:(210.0f/255.0f) blue:(210.0f/255.0f) alpha:0.2f]];
    
    // toolbar icon buttons
    [[UIBarButtonItem appearance] setTintColor:[UIColor lightGrayColor]];
    
    // 'back' buttons
    //[[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.0f green:(112.0f/255.0f) blue:(186.0f/255.0f) alpha:1.0f]];
    
    // Tint color
    [self.window setTintColor:[UIColor whiteColor]];
    
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
    UITabBarController *tabBarController = (UITabBarController *)[self.window rootViewController];
    
    for (UINavigationController *navigationController in tabBarController.viewControllers) {
        id viewController = navigationController.topViewController;
        
        if ([viewController respondsToSelector:@selector(refreshStatistics)]) {
            [viewController refreshStatistics];
        }
    }
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
    
    UITabBarController *tabBarController = (UITabBarController *)[self.window rootViewController];
    
    for (UINavigationController *navigationController in tabBarController.viewControllers) {
        id viewController = navigationController.topViewController;
        
        if ([viewController respondsToSelector:@selector(setApp:)]) {
            [viewController setApp:_app];
        }
    }
}

@end
