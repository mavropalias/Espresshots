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
            completionHandler(quantitySample, error);
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
    
    // Samples
    NSData *samples = [NSKeyedArchiver archivedDataWithRootObject:_samples];
    
    // Shot amount
    NSNumber *shotAmount = [NSNumber numberWithDouble:_defaultEspressoShotMg];
    
    // Theme
    NSNumber *theme = [NSNumber numberWithInt:_currentTheme];
    
    // Save data
    NSDictionary *userData = [[NSDictionary alloc] initWithObjectsAndKeys:
                              samples, @"samples",
                              shotAmount, @"shotAmount",
                              theme, @"theme",
                              nil];
    [prefs setObject:userData forKey:@"userData"];
    [prefs synchronize];
}

- (void)loadUserDefaults {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    // Samples
    NSDictionary *userData = [[prefs dictionaryForKey:@"userData"] mutableCopy];
    _samples = [NSKeyedUnarchiver unarchiveObjectWithData:userData[@"samples"]];
    
    // Shot amount
    NSNumber *shotAmount = [prefs objectForKey:@"shotAmount"];
    if (shotAmount > 0) {
        _defaultEspressoShotMg = [shotAmount doubleValue];
    } else {
        _defaultEspressoShotMg = 75.0f;
    }
    
    // Theme
    NSNumber *theme = [prefs objectForKey:@"theme"];
    if (theme > 0) {
        _currentTheme = [theme intValue];
    } else {
        _currentTheme = 0;
    }
}





#pragma mark - Helpers

// Create the following dictionary structure:
//    – {samplesDictionary}
//        – * highestSampleEntry
//        – * highestOverallConsumptionInOneDay
//        – {dates dictionary}
//          – {dateSum dictionary}
//          – {dateSum dictionary}
//              – [samples]
//              – * dailySum
- (NSDictionary *)dictionaryFromSamples:(NSArray *)samples {
    if (!(samples.count > 0)) { return nil; }

    NSMutableDictionary *samplesDictionary = [[NSMutableDictionary alloc] init];

    double highestSampleEntry = 0.0;
    double highestOverallConsumptionInOneDay = 0.0;

    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
    [theDateFormatter setDateFormat:@"yyyyMMdd"];

    // Parse _samples_ and put them in _samplesDictionary_, grouped by date
    for (HKQuantitySample *sample in samples) {
        // META – Update highestSampleEntry
        if ([sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"g"]] > highestSampleEntry) {
            highestSampleEntry = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"g"]];
            [samplesDictionary setValue:[NSNumber numberWithDouble:highestSampleEntry] forKey:@"highestSampleEntry"];
        }

        // Get sample's date
        NSString *sampleDateString = [theDateFormatter stringFromDate:sample.startDate];

        // Get dictionary for sample's date
        NSMutableArray *dicArracy;
        NSMutableDictionary *dateDictionary = [[NSMutableDictionary alloc] init];
        if ([samplesDictionary objectForKey:sampleDateString]) {
            dateDictionary = [samplesDictionary objectForKey:sampleDateString];
        } else {
            [dateDictionary setValue:[self humanReadableStringFromDate:sample.startDate] forKey:@"date"];

            // Check if we're on the 1st of a month
            NSDateFormatter *monthDayFormat = [[NSDateFormatter alloc] init];
            [monthDayFormat setDateFormat:@"d"];
            NSInteger day = [[monthDayFormat stringFromDate:sample.startDate] intValue];
            if (day == 1) {
                [dateDictionary setValue:@1 forKey:@"isNewMonth"];
            }
        }

            // Update samples array
            dicArracy = [dateDictionary objectForKey:@"samples"];
            if (dicArracy == nil) {
                dicArracy = [@[] mutableCopy];
            }
            [dicArracy insertObject:sample atIndex:dicArracy.count];
            [dateDictionary setValue:dicArracy forKey:@"samples"];

            // Calculate daily sum
            double currentDailySum = [[dateDictionary valueForKey:@"dailySum"] doubleValue];
            double sampleValue = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"g"]];
            double newDailySum = currentDailySum + sampleValue;
            [dateDictionary setValue:[NSNumber numberWithDouble:newDailySum] forKey:@"dailySum"];

            // Update highestOverallConsumptionInOneDay
            if (newDailySum > highestOverallConsumptionInOneDay) {
                highestOverallConsumptionInOneDay = newDailySum;
            }

        // Assign the updated/new dateDictionary to the samplesDictionary master list
//        if ([samplesDictionary objectForKey:@"dateArray"]) {
//            NSMutableArray *dateArray = [samplesDictionary objectForKey:"dateArray"];
//            [dateArray addObject:dateDictionary];
//        } else {
//            [dateDictionary setValue:@[dateDictionary] forKey:@"dateArray"];
//        }
        [samplesDictionary setValue:dateDictionary forKey:sampleDateString];

    }

    // Update highestOverallConsumptionInOneDay
    [samplesDictionary setValue:[NSNumber numberWithDouble:highestOverallConsumptionInOneDay] forKey:@"highestOverallConsumptionInOneDay"];


    NSLog(@"Created NSDictionary for %lu days", (unsigned long)samplesDictionary.count);

    return samplesDictionary;
}

- (NSString *)humanReadableStringFromDate:(NSDate *)date {
    NSString *returnDateString = @"";
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay
                                               fromDate:date
                                                 toDate:[NSDate date] options:0];
    NSInteger daysAgo = [components day] + 1;

    NSDateFormatter *monthDayFormat = [[NSDateFormatter alloc] init];
    [monthDayFormat setDateFormat:@"d"];
    NSInteger day = [[monthDayFormat stringFromDate:date] intValue];

    if ([[NSCalendar currentCalendar] isDateInToday:date]) {
        returnDateString = @"Today";
    } else if (day == 1) {
        NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
        [theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
        [theDateFormatter setDateFormat:@"MMMM"];
        returnDateString = [NSString stringWithFormat:@"%@⇣", [theDateFormatter stringFromDate:date]];
    } else if ([[NSCalendar currentCalendar] isDateInYesterday:date]) {
        returnDateString = @"Yesterday";
    } else if (daysAgo < 7) {
        NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
        [theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
        [theDateFormatter setDateFormat:@"EEEE"];
        returnDateString = [theDateFormatter stringFromDate:date];
    } else if (daysAgo == 14) {
        returnDateString = @"2 weeks ago";
    } else if (daysAgo == 21) {
        returnDateString = @"3 weeks ago";
    } else {
//        NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
//        [theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
//        [theDateFormatter setDateFormat:@"EEEE d/MMM"];
        returnDateString = @"";
    }

    //[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];

    return returnDateString;
}

- (UIColor*)colorWithHex:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];

    // strip # if it appears
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];

    if ([cString length] != 6) return  [UIColor grayColor];

    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];

    range.location = 2;
    NSString *gString = [cString substringWithRange:range];

    range.location = 4;
    NSString *bString = [cString substringWithRange:range];

    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];

    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

@end
