//
//  App.m
//  Espresshots
//
//  Created by Kostas on 16/02/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import "App.h"

@interface App ()

@property (nonatomic, strong) HKHealthStore *healthStore;

@end

@implementation App





#pragma mark - Init

- (App *)init {
    _healthStore = [[HKHealthStore alloc] init];
    _samples = [[NSMutableArray alloc] init];
    _defaultEspressoShotMg = 75.0;
    _bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    [self loadUserDefaults];

    return [super init];
}





#pragma mark - Healthkit

/*- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            
            completionHandler(value, error);
        }
    }];
    
    [_healthStore executeQuery:query];
}*/

- (void)fetchSamplesForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit days:(int)days completion:(void (^)(NSArray *, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesDays:days];
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    NSSortDescriptor *timeSortDescription = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                           predicate:predicate
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:@[timeSortDescription]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                    if (!results) {
                                                                        NSLog(@"No results");
                                                                    } else {
                                                                        NSLog(@"Got samples");
                                                                    }
                                                                    
                                                                    _samples = [results mutableCopy];
                                                                    [self saveUserDefaults];
                                                                    
                                                                    if (completionHandler) {
                                                                        completionHandler(results, error);
                                                                    }
                                                      }
                            ];
    
    [self.healthStore executeQuery:query];
}

- (void)addQuantity:(double)quantityMg completion:(void (^)(HKQuantitySample *, NSError *))completionHandler {
    HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:@"HKQuantityTypeIdentifierDietaryCaffeine"];
    HKUnit *mg = [HKUnit unitFromString:@"mg"];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:mg doubleValue:quantityMg];
    HKQuantitySample *quantitySample = [HKQuantitySample quantitySampleWithType:quantityType quantity:quantity startDate:[NSDate date] endDate:[NSDate date]];
    
    [self.healthStore saveObject:quantitySample withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [_samples insertObject:quantitySample atIndex:0];
            [self saveUserDefaults];
            
            if (completionHandler) {
                completionHandler(quantitySample, error);
            }
        }
        else {
            NSLog(@"An error occured: %@." , error);
            abort();
        }
    }];
}

- (void)deleteSample:(HKQuantitySample *)sample completion:(void (^)(BOOL, NSError *))completionHandler {
    [self.healthStore deleteObject:sample withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [_samples removeObject:sample];
            [self saveUserDefaults];
        }
        else {
            NSLog(@"An error occured: %@." , error);
        }
        
        if (completionHandler) {
            completionHandler(success, error);
        }
    }];
}





#pragma mark - HealthKit Permissions

// Requests permission to access HealthKit and updates the 'healthkitAuthorised' property
- (void)checkForHealthkitPermissions:(void (^)(NSError *))completionHandler {
    if ([HKHealthStore isHealthDataAvailable]) {
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];
        
        [_healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                _healthkitAuthorised = NO;
                return;
            }
            
            _healthkitAuthorised = YES;
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }
}

// Returns the types of data that we wish to write to HealthKit.
- (NSSet *)dataTypesToWrite {
    HKQuantityType *dietaryCaffeineType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    
    return [NSSet setWithObjects:dietaryCaffeineType, nil];
}

// Returns the types of data that we wish to read from HealthKit.
- (NSSet *)dataTypesToRead {
    HKQuantityType *dietaryCaffeineType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    
    return [NSSet setWithObjects:dietaryCaffeineType, nil];
}





#pragma mark - Convenience

- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

- (NSPredicate *)predicateForSamplesDays:(int)numDays {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:[calendar dateByAddingUnit:NSCalendarUnitDay value:-numDays toDate:now options:0]];
    NSDate *endDate = now;

    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}





#pragma mark - Local storage

- (void)saveUserDefaults {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSData *samples = [NSKeyedArchiver archivedDataWithRootObject:_samples];
    NSDictionary *userData = [[NSDictionary alloc] initWithObjectsAndKeys:
                              samples, @"samples",
                              nil];
    [prefs setObject:userData forKey:@"userData"];
    [prefs synchronize];
}

- (void)loadUserDefaults {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *userData = [[prefs dictionaryForKey:@"userData"] mutableCopy];
    
    _samples = [NSKeyedUnarchiver unarchiveObjectWithData:userData[@"samples"]];
}





#pragma mark - Visual effects

- (void)addBlurEffectToNavigationBar:(UINavigationBar *)navigationBar {

    navigationBar.barTintColor = [UIColor colorWithRed:(0.0f/255.0f) green:(250.0f/255.0f) blue:(250.0f/255.0f) alpha:1.0f];
    [navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    navigationBar.shadowImage = [[UIImage alloc] init];
    navigationBar.translucent = YES;
    
    CGRect navBounds = navigationBar.bounds;
    CGRect bounds = CGRectMake(0, -20, navBounds.size.width , navBounds.size.height + 20);
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    visualEffectView.frame = bounds;
    visualEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [navigationBar addSubview:visualEffectView];
    [navigationBar sendSubviewToBack:visualEffectView];
}

@end
