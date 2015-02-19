//
//  Timeline.m
//  Espresshots
//
//  Created by Kostas on 16/02/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import "Timeline.h"

@interface Timeline ()

@property (strong, nonatomic) App* app;
@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (strong, nonatomic) NSMutableArray* samples;
@property (strong, nonatomic) NSMutableDictionary* groupedSamples;
@property (strong, nonatomic) NSMutableDictionary* dailySums;
@property BOOL compactTableMode;
@property BOOL editingTable;
@property double highestSampleConsumption;
@property double highestDailyConsumption;

- (IBAction)pinchOnView:(UIPinchGestureRecognizer *)sender;
- (IBAction)addDefaultAmount:(id)sender;
- (IBAction)addDoubleAmount:(id)sender;
- (IBAction)addTripleAmount:(id)sender;
- (IBAction)addCustomAmount:(id)sender;
- (IBAction)editTable:(UIBarButtonItem *)button;

@end

@implementation Timeline





#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _compactTableMode = true;
    _samples = _app.samples;
    _groupedSamples = [[NSMutableDictionary alloc] init];
    _dailySums = [[NSMutableDictionary alloc] init];
    _highestSampleConsumption = 0.0;
    _highestDailyConsumption = 0.0;
    
    [_app addBlurEffectToNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [_app checkForHealthkitPermissions:^(NSError *error) {
        [self refreshStatistics];
    }];
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}





#pragma mark - Helpers

- (void)setApp:(App *)app {
    _app = app;
}

- (void)refreshStatistics {
    HKQuantityType *caffeineConsumedType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    
    [_app fetchSamplesForType:caffeineConsumedType unit:[HKUnit gramUnit] days:8 completion:^(NSArray *samples, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _samples = [samples mutableCopy];
            [_tableView reloadData];
        });
    }];
}




#pragma mark - Table DataSource

// numberOfSectionsInTableView
// =============================================================================
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!(_samples.count > 0)) {
        return 0;
    }
    
    // Calculate the number of days since the oldest sample
    // -------------------------------------------------------------------------
    HKQuantitySample *oldestSample = [_samples lastObject];
    NSDate * date1 = oldestSample.startDate;
    NSDate * date2 = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSDateComponents *components = [calendar components:unitFlags
                                                fromDate:date1
                                                  toDate:date2 options:0];
    NSInteger days = [components day];
    
    // Calculate individual day sections for use later in the table
    // -------------------------------------------------------------------------
    _highestSampleConsumption = 0.0;
    _highestDailyConsumption = 0.0;
    
    for (int section = 0; section < days; section++) {
        //NSDate *now = [NSDate date];
        NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:section+1
                                                toDate:[calendar startOfDayForDate:oldestSample.startDate]
                                               options:0];
        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                               value:section+2
                                              toDate:[calendar startOfDayForDate:oldestSample.startDate]
                                             options:0];
        
        NSMutableArray *sectionSamples = [[NSMutableArray alloc] init];
        double dailyConsumption = 0.0;
        
        for (HKQuantitySample *sample in _samples) {
            if ([sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"g"]] > _highestSampleConsumption) {
                _highestSampleConsumption = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"g"]];
            }
            
            if (([sample.startDate compare:startDate] == NSOrderedDescending) &&
                ([sample.startDate compare:endDate] == NSOrderedAscending)) {
                [sectionSamples addObject:sample];
                dailyConsumption += [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"g"]];
            }
        }

        // daily samples
        [_groupedSamples setValue:sectionSamples
                           forKey:[NSString stringWithFormat:@"section%ld", (long)section]];
        // daily sum
        [_dailySums setValue:[NSNumber numberWithDouble:dailyConsumption]
                           forKey:[NSString stringWithFormat:@"section%ldsum", (long)section]];

        
        if (dailyConsumption > _highestDailyConsumption) {
            _highestDailyConsumption = dailyConsumption;
        }
    }
    
    return days;
}

// heightForHeaderInSection
// =============================================================================
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 33.0f;
}

// viewForHeaderInSection
// =============================================================================
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:@"header"];
    
    // Set quantity bar
    // -------------------------------------------------------------------------
    CGFloat progressWidthAdjustment = 1.0f;
    NSNumber *dailySum = [_dailySums objectForKey:[NSString stringWithFormat:@"section%ldsum", (long)section]];
    CGFloat progressWidth = (((self.view.frame.size.width * 0.8) * [dailySum doubleValue]) / _highestDailyConsumption) * progressWidthAdjustment;
    CGRect progressFrame = CGRectMake(-1, 0, progressWidth, 40.0f);
    UIView *progressView = [[UIView alloc] initWithFrame:progressFrame];
    progressView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    progressView.layer.borderColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f].CGColor;
    progressView.layer.borderWidth = 1.0f;
    [headerView.contentView insertSubview:progressView atIndex:0];
    
    // Set header title
    // -------------------------------------------------------------------------
    UILabel *headerTitle = (UILabel *)[headerView viewWithTag:1];
    NSMutableArray *sectionSamples = [_groupedSamples objectForKey:[NSString stringWithFormat:@"section%ld", (long)section]];
    HKQuantitySample *sample;
    if (sectionSamples.count > 0) {
        sample = [sectionSamples objectAtIndex:0];
    }
    
    // Day
    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
    [theDateFormatter setDateFormat:@"EE"];
    NSString *dateString = [theDateFormatter stringFromDate:sample.startDate];
    
    // Amount
    NSString *amountString = [NSString stringWithFormat:@"%d◉",/*◉*/
                        (int)(([dailySum doubleValue] * 1000) / _app.defaultEspressoShotMg)];
    
    
    headerTitle.text = [NSString stringWithFormat:@"%@   %@", dateString, amountString];
    
    return headerView.contentView;
}

// numberOfRowsInSection
// =============================================================================
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_compactTableMode && section < (_groupedSamples.count - 1)) return 0;
    
    NSMutableArray *sectionArray = [_groupedSamples objectForKey:[NSString stringWithFormat:@"section%ld", (long)section]];
    return sectionArray.count;
}

// cellForRowAtIndexPath
// =============================================================================
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    NSMutableArray *sectionSamples = [_groupedSamples objectForKey:[NSString stringWithFormat:@"section%ld", (long)indexPath.section]];
    HKQuantitySample *sample = [sectionSamples objectAtIndex:indexPath.row];
    
    NSString *extraInfo = @"";
    if (![sample.source.bundleIdentifier isEqualToString:_app.bundleIdentifier] && sample.source.name) {
        extraInfo = [NSString stringWithFormat:@"%@ – ", sample.source.name];
    }
    
    // Set detail text
    NSDateFormatter* timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *time =  [timeFormatter stringFromDate:sample.startDate];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@", extraInfo, time];
    
    // Set title text
    cell.textLabel.text = [NSString stringWithFormat:@"%d◉",
                           (int)([sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"mg"]] / _app.defaultEspressoShotMg)];
    
    return cell;
}

// canEditRowAtIndexPath
// =============================================================================
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    NSMutableArray *sectionSamples = [_groupedSamples objectForKey:[NSString stringWithFormat:@"section%ld", (long)indexPath.section]];
    HKQuantitySample *sample = [sectionSamples objectAtIndex:indexPath.row];
    
    if ([sample.source.bundleIdentifier isEqualToString:_app.bundleIdentifier] || !sample.source.name) return YES;
    else return NO;
}

// commitEditingStyle
// =============================================================================
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *sectionSamples = [_groupedSamples objectForKey:[NSString stringWithFormat:@"section%ld", (long)indexPath.section]];
    HKQuantitySample *sample = [sectionSamples objectAtIndex:indexPath.row];
    [self deleteSample:sample indexPath:indexPath];
}


#pragma mark - IBActions
- (IBAction)pinchOnView:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGFloat scale = [(UIPinchGestureRecognizer *)sender scale];
        
        if (scale > 1.0f) _compactTableMode = NO;
        else _compactTableMode = YES;
        
        NSRange range = NSMakeRange(0, _groupedSamples.count - 1);
        NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
        [_tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];

    }
}

- (IBAction)addDefaultAmount:(id)sender { [self addAmount:_app.defaultEspressoShotMg]; }
- (IBAction)addDoubleAmount:(id)sender { [self addAmount:_app.defaultEspressoShotMg * 2]; }
- (IBAction)addTripleAmount:(id)sender { [self addAmount:_app.defaultEspressoShotMg * 3]; }

- (IBAction)addCustomAmount:(id)sender {
}

- (IBAction)editTable:(UIBarButtonItem *)button {
    if (!_editingTable) {
        [_tableView setEditing:YES animated:YES];
        _editingTable = YES;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editTable:)];
    } else {
        [_tableView setEditing:NO animated:YES];
        _editingTable = NO;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTable:)];
    }
}





#pragma mark - Healthkit

- (void)addAmount:(double)quantity {
    __unsafe_unretained typeof(self) weakSelf = self;
    [_app addQuantity:quantity completion:^(HKQuantitySample *sample, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [weakSelf.samples insertObject:sample atIndex:0];
                [weakSelf.tableView reloadData];
                NSLog(@"HK updated");
            } else {
                NSLog([NSString stringWithFormat:@"Error: %@", error]);
            }
        });
    }];
}

- (void)deleteSample:(HKQuantitySample *)sample indexPath:(NSIndexPath *)indexPath {
    // Update local array
    [_samples removeObject:sample];
    
    // Remove row from table
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    [_app deleteSample:sample completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            NSLog(@"HK updated");
        });
    }];
}

@end
