//
//  App.h
//  Espresshots
//
//  Created by Kostas on 16/02/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import <Foundation/Foundation.h>
@import HealthKit;
@import UIKit;

@interface App : NSObject

@property BOOL healthkitAuthorised;
@property double defaultEspressoShotMg;
@property (strong, nonatomic) NSString *bundleIdentifier;
@property (strong, nonatomic) NSMutableArray *samples;

- (void)addBlurEffectToNavigationBar:(UINavigationBar *)navigationBar;
- (void)checkForHealthkitPermissions:(void (^)(NSError *))completionHandler;
- (void)fetchSamplesForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit days:(int)days completion:(void (^)(NSArray *, NSError *))completionHandler;
- (void)addQuantity:(double)quantityMg completion:(void (^)(HKQuantitySample *, NSError *))completionHandler;
- (void)deleteSample:(HKQuantitySample *)sample completion:(void (^)(BOOL, NSError *))completionHandler;
- (NSDictionary *)dictionaryFromSamples:(NSArray *)samples;

@end
