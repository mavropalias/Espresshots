//
//  Timeline.m
//  Espresshots
//
//  Created by Kostas on 16/02/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import "Timeline.h"
#import "TimelineHeaderView.h"
#import "ScaleCollectionViewCell.h"

@interface Timeline ()

@property (strong, nonatomic) App* app;
@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIButton *addCoffeeButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *addCoffeeVisualEffectView;
@property (weak, nonatomic) IBOutlet UIButton *adjustServingSizeButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *adjustServingSizeVisualEffectView;
@property (weak, nonatomic) IBOutlet UIImageView *scaleImageView;
@property (strong, nonatomic) NSMutableArray* samples;
@property (strong, nonatomic) NSMutableDictionary* groupedSamples;
@property (strong, nonatomic) NSMutableDictionary* dailySums;
@property BOOL compactTableMode;
@property BOOL editingTable;
@property double highestSampleConsumption;
@property double highestDailyConsumption;

- (IBAction)pinchOnView:(UIPinchGestureRecognizer *)sender;
- (IBAction)addCustomAmount:(id)sender;
- (IBAction)editTable:(UIBarButtonItem *)button;

@end

@implementation Timeline





#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    // initial values
    _compactTableMode = true;
    _samples = _app.samples;
    _groupedSamples = [[NSMutableDictionary alloc] init];
    _dailySums = [[NSMutableDictionary alloc] init];
    _highestSampleConsumption = 0.0;
    _highestDailyConsumption = 0.0;

    // style button bgs
    _addCoffeeVisualEffectView.layer.cornerRadius = _addCoffeeVisualEffectView.frame.size.height / 2;
    _addCoffeeVisualEffectView.layer.masksToBounds = YES;

    _adjustServingSizeVisualEffectView.layer.cornerRadius = _adjustServingSizeVisualEffectView.frame.size.height / 2;
    _adjustServingSizeVisualEffectView.layer.masksToBounds = YES;

    [_app addBlurEffectToNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [_app checkForHealthkitPermissions:^(NSError *error) {
        [self refreshStatistics];
    }];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [_tableView setContentInset:UIEdgeInsetsMake(0, 0, (self.view.frame.size.height / 2), 0)];
//    [self drawScale];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}





#pragma mark - Helpers

- (void)drawScale {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(_scaleImageView.frame.size.width,
                                                      _scaleImageView.frame.size.height),
                                           NO,
                                           0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat leftMargin= _scaleImageView.frame.size.width / 2;
    CGFloat topMargin = 0;
    CGFloat height = 30;
    CGFloat width = _scaleImageView.frame.size.width;
    CGFloat minorTickSpace = 10;
    int multiple = 5;              // number of minor ticks per major tick
    CGFloat majorTickLength = 10;  // must be smaller or equal height,
    CGFloat minorTickLength = 10;  // must be smaller than majorTickLength

    CGFloat baseY = topMargin + height;
    CGFloat minorY = baseY - minorTickLength;
    CGFloat majorY = baseY - majorTickLength;
    CGFloat majorTickSpace = minorTickSpace * multiple;

    int step = 0;
    for (CGFloat x = leftMargin; x <= leftMargin + width; x += minorTickLength) {
        if (((int)(x - leftMargin) % (int)majorTickSpace) == 0) {
            CGContextSetLineWidth(context, 5.0f);
            //CGContextSetStrokeColorWithColor(context, [app.utility colorWithHex:[key[@"Stroke"] objectForKey:@"Color"]].CGColor);
        } else {
            CGContextSetLineWidth(context, 1.0f);
        }

        CGContextMoveToPoint(context, x, baseY);
        CGFloat endY = (((int)(x - leftMargin) % (int)majorTickSpace)  == 0) ? majorY : minorY;

        CGContextAddLineToPoint(context, x, endY);
        CGContextStrokePath(context);
        step++;  // step contains the minorTickCount in case you want to draw labels
    }

    // Retrieve the drawn image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_scaleImageView setImage:image];
}

- (void)setApp:(App *)app {
    _app = app;
}

- (void)refreshStatistics {
    HKQuantityType *caffeineConsumedType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    
    [_app fetchSamplesForType:caffeineConsumedType unit:[HKUnit gramUnit] days:51 completion:^(NSArray *samples, NSError *error) {
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
    NSInteger days = [components day] + 1;
    
    // Calculate individual day sections for use later in the table
    // -------------------------------------------------------------------------
    _highestSampleConsumption = 0.0;
    _highestDailyConsumption = 0.0;
    
    for (int section = 0; section < days; section++) {
        //NSDate *now = [NSDate date];
        NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                                 value:section
                                                toDate:[calendar startOfDayForDate:oldestSample.startDate]
                                               options:0];
        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay
                                               value:section+1
                                              toDate:[calendar startOfDayForDate:oldestSample.startDate]
                                             options:0];
        
        NSMutableArray *sectionSamples = [[NSMutableArray alloc] init];
        double dailyConsumption = 0.0;
        
        for (HKQuantitySample *sample in _samples) {
            //NSLog([NSString stringWithFormat:@"%@", sample.startDate]);
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
    if (_compactTableMode) return 21.0f;
    else return 60.0f;
}

// viewForHeaderInSection
// =============================================================================
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    TimelineHeaderView *headerView = [tableView dequeueReusableCellWithIdentifier:@"header"];
    
    // Set quantity bar
    // -------------------------------------------------------------------------
    CGFloat progressWidthAdjustment = 1.0f;
    NSNumber *dailySum = [_dailySums objectForKey:[NSString stringWithFormat:@"section%ldsum", (long)section]];
    CGFloat progressWidth = (((self.view.frame.size.width * 0.9) * [dailySum doubleValue]) / _highestDailyConsumption) * progressWidthAdjustment;
    if (progressWidth < 1.0f) {
        progressWidth = 1.0f;
    }
    headerView.progressViewWidthConstraint.constant = progressWidth;

    // Set header title
    // -------------------------------------------------------------------------
    UILabel *headerTitle = (UILabel *)[headerView viewWithTag:1];

    if (!_compactTableMode) {
        headerView.visualEffectView.hidden = NO;
        headerView.detailLabel.hidden = NO;
        headerTitle.hidden = NO;

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
        
        
        headerTitle.text = [NSString stringWithFormat:@"%@", amountString];
        headerView.detailLabel.text = dateString;
    } else {
        headerTitle.hidden = YES;
        headerView.detailLabel.hidden = YES;
        headerView.visualEffectView.hidden = YES;
    }
    
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
        extraInfo = [NSString stringWithFormat:@" (%@)", sample.source.name];
    }
    
    // Set detail text
    UILabel *detailText = (UILabel *)[cell viewWithTag:2];
    NSDateFormatter* timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *time =  [timeFormatter stringFromDate:sample.startDate];
    detailText.text = [NSString stringWithFormat:@"%@",time];
    
    // Set title text
    UILabel *cellText = (UILabel *)[cell viewWithTag:1];
    cellText.text = [NSString stringWithFormat:@"%d◉ %@",
                     (int)([sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"mg"]] / _app.defaultEspressoShotMg),
                     extraInfo];
    
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





#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return 20;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ScaleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    cell.lineLabel.text = @"10";

    return cell;
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
