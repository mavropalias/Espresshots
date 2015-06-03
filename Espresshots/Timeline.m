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
@property (weak, nonatomic) IBOutlet UIButton *removeServingButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *removeServingVisualEffectView;
@property (weak, nonatomic) IBOutlet UIButton *addServingButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *addServingVisualEffectView;
@property (weak, nonatomic) IBOutlet UIImageView *scaleImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *scaleCollectionView;
@property (strong, nonatomic) NSMutableArray* samples;
@property (strong, nonatomic) NSMutableDictionary* groupedSamples;
@property (strong, nonatomic) NSMutableDictionary* dailySums;
@property (nonatomic, assign) BOOL shouldScrollToLastRow;
@property BOOL compactTableMode;
@property BOOL editingTable;
@property double highestSampleConsumption;
@property double highestDailyConsumption;
@property double userQuantity;
@property double servingQuantity;
@property double weeklyQuantity;
@property double monthlyQuantity;

@property int minValue;
@property int maxValue;
@property int labelInterval;
@property int minorStepInterval;
@property int majorStepInterval;

- (IBAction)pinchOnView:(UIPinchGestureRecognizer *)sender;
- (IBAction)addCustomAmount:(id)sender;
- (IBAction)editTable:(UIBarButtonItem *)button;
- (IBAction)increaseServings:(id)sender;
- (IBAction)decreaseServings:(id)sender;


@end

@implementation Timeline





#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    // initial values
    _shouldScrollToLastRow = YES;
    _compactTableMode = true;
    _samples = _app.samples;
    _groupedSamples = [[NSMutableDictionary alloc] init];
    _dailySums = [[NSMutableDictionary alloc] init];
    _highestSampleConsumption = 0.0;
    _highestDailyConsumption = 0.0;
    [self setAddCoffeeButtonTitle:@"One" subtitle:@"Shot"];

    // config values
    _minValue = 0;
    _maxValue = 400;
    _servingQuantity = 75.0f;
    _userQuantity = _servingQuantity;
    _minorStepInterval = 5;
    _majorStepInterval = _servingQuantity;
    _labelInterval = 10;

    // style button bgs
    _addCoffeeVisualEffectView.layer.cornerRadius = _addCoffeeVisualEffectView.frame.size.height / 2;
    _addCoffeeVisualEffectView.layer.masksToBounds = YES;

    _addServingVisualEffectView.layer.cornerRadius = _addServingVisualEffectView.frame.size.height / 2;
    _addServingVisualEffectView.layer.masksToBounds = YES;

    _removeServingVisualEffectView.layer.cornerRadius = _removeServingVisualEffectView.frame.size.height / 2;
    _removeServingVisualEffectView.layer.masksToBounds = YES;

    [_app addBlurEffectToNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [_app checkForHealthkitPermissions:^(NSError *error) {
        [self refreshStatistics];
    }];

    [_tableView setContentInset:UIEdgeInsetsMake(0, 0, (self.view.frame.size.height / 2), 0)];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSIndexPath *pathForCenterCell = [NSIndexPath indexPathForItem:(_servingQuantity / _minorStepInterval) inSection:0];
    [_scaleCollectionView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Scroll table view to the last row
    if (_shouldScrollToLastRow)
    {
        //_shouldScrollToLastRow = NO;
        if (_tableView.contentSize.height > (self.view.frame.size.height / 2)) {
            [self.tableView setContentOffset:CGPointMake(0,
                                                         _tableView.contentSize.height - (self.view.frame.size.height / 2)
                                                         )];
        }
    }
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
    
    [_app fetchSamplesForType:caffeineConsumedType unit:[HKUnit gramUnit] days:51 completion:^(NSArray *samples, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _samples = [samples mutableCopy];
            [_groupedSamples removeAllObjects];
            [_dailySums removeAllObjects];
            [_tableView reloadData];
        });
    }];
}

- (void)scrollScaleToQuantity:(double)quantity {
    NSIndexPath *pathForCenterCell = [NSIndexPath indexPathForItem:(quantity / _minorStepInterval) inSection:0];
    [_scaleCollectionView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)setQuantityFromScale:(double)quantity {
    _userQuantity = quantity;
    NSString *newButtonLabel = @"";
    if ((int)_userQuantity % (int)_servingQuantity == 0) {
        switch ((int)(_userQuantity / _servingQuantity)) {
            case 1:
                newButtonLabel = [NSString stringWithFormat:@"One"];
                break;
            case 2:
                newButtonLabel = [NSString stringWithFormat:@"Two"];
                break;
            case 3:
                newButtonLabel = [NSString stringWithFormat:@"Three"];
                break;
            case 4:
                newButtonLabel = [NSString stringWithFormat:@"Four"];
                break;
            case 5:
                newButtonLabel = [NSString stringWithFormat:@"Five"];
                break;
            default:
                newButtonLabel = [NSString stringWithFormat:@"One"];
                break;
        }
        [self setAddCoffeeButtonTitle:newButtonLabel subtitle:@""];
    } else {
        newButtonLabel = [NSString stringWithFormat:@"%d", (int)_userQuantity];
        [self setAddCoffeeButtonTitle:newButtonLabel subtitle:@"mg"];
    }
}

- (void)setAddCoffeeButtonTitle:(NSString *)title subtitle:(NSString *)subtitle {
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];

    UIFont *font1 = [UIFont fontWithName:@"HelveticaNeue-Thin" size:35.0f];
    UIFont *font2 = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];

    NSDictionary *dict1 = @{NSFontAttributeName:font1,
                            NSForegroundColorAttributeName: [UIColor whiteColor],
                            NSParagraphStyleAttributeName:paragraphStyle};
    NSDictionary *dict2 = @{NSFontAttributeName:font2,
                            NSForegroundColorAttributeName: [UIColor whiteColor],
                            NSParagraphStyleAttributeName:paragraphStyle};

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] init];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Log\n" attributes:dict2]];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", title] attributes:dict1]];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:subtitle attributes:dict2]];

    [_addCoffeeButton setAttributedTitle:attString forState:UIControlStateNormal];
    [[_addCoffeeButton titleLabel] setNumberOfLines:0];
    [[_addCoffeeButton titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
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
    if (_compactTableMode) return 27.0f;
    else return 60.0f;
}

// viewForHeaderInSection
// =============================================================================
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    TimelineHeaderView *headerView = [tableView dequeueReusableCellWithIdentifier:@"header"];
    
    // Set quantity bar
    // -------------------------------------------------------------------------
    CGFloat progressWidthAdjustment = 0.9f;
    NSNumber *dailySum = [_dailySums objectForKey:[NSString stringWithFormat:@"section%ldsum", (long)section]];
    _weeklyQuantity += [dailySum doubleValue];
    _monthlyQuantity += [dailySum doubleValue];
    CGFloat progressWidth = ((self.view.frame.size.width * [dailySum doubleValue]) / _highestDailyConsumption) * progressWidthAdjustment;
    if (progressWidth < 1.0f) {
        progressWidth = 1.0f;
    }
    headerView.progressViewWidthConstraint.constant = progressWidth;

    // Get sample
    // -------------------------------------------------------------------------
    NSMutableArray *sectionSamples = [_groupedSamples objectForKey:[NSString stringWithFormat:@"section%ld", (long)section]];
    HKQuantitySample *sample;
    if (sectionSamples.count > 0) {
        sample = [sectionSamples objectAtIndex:0];
    }

    // Day & Shots
    // -------------------------------------------------------------------------
    UILabel *shotsLabel = (UILabel *)[headerView viewWithTag:1];
    UILabel *dayLabel = (UILabel *)[headerView viewWithTag:3];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay
                                               fromDate:sample.startDate
                                                 toDate:[NSDate date] options:0];
    NSInteger daysAgo = [components day] + 1;

    if ([[NSCalendar currentCalendar] isDateInToday:sample.startDate]) {
        // Day
        dayLabel.text = @"Today";

        // Shots
        NSString *amountString = [NSString stringWithFormat:@"%d Shots",/*◉*/
                                  (int)(([dailySum doubleValue] * 1000) / _app.defaultEspressoShotMg)];
        shotsLabel.text = [NSString stringWithFormat:@"%@", amountString];

        // Alpha
        [shotsLabel setAlpha:1.0f];
        [dayLabel setAlpha:1.0f];
    } else if ([[NSCalendar currentCalendar] isDateInYesterday:sample.startDate]) {
        // Day
        dayLabel.text = @"Yesterday";

        // Shots
        NSString *amountString = [NSString stringWithFormat:@"%d Shots",/*◉*/
                                  (int)(([dailySum doubleValue] * 1000) / _app.defaultEspressoShotMg)];
        shotsLabel.text = [NSString stringWithFormat:@"%@", amountString];

        // Alpha
        [shotsLabel setAlpha:0.5f];
        [dayLabel setAlpha:0.5f];
    } else if (daysAgo == 7) {
        // Day
        dayLabel.text = @"Last week";

        // Shots
        NSString *amountString = [NSString stringWithFormat:@"%d Shots",/*◉*/
                                  (int)((_weeklyQuantity * 1000) / _app.defaultEspressoShotMg)];
        shotsLabel.text = [NSString stringWithFormat:@"%@", amountString];
        _weeklyQuantity = 0.0f;

        // Alpha
        [shotsLabel setAlpha:0.5f];
        [dayLabel setAlpha:0.5f];
    } else if (daysAgo == 14) {
        // Day
        dayLabel.text = @"Two weeks ago";

        // Shots
        NSString *amountString = [NSString stringWithFormat:@"%d Shots",/*◉*/
                                  (int)((_weeklyQuantity * 1000) / _app.defaultEspressoShotMg)];
        shotsLabel.text = [NSString stringWithFormat:@"%@", amountString];
        _weeklyQuantity = 0.0f;

        // Alpha
        [shotsLabel setAlpha:0.5f];
        [dayLabel setAlpha:0.5f];
    } else if (daysAgo == 21) {
        // Day
        dayLabel.text = @"Three weeks ago";

        // Shots
        NSString *amountString = [NSString stringWithFormat:@"%d Shots",/*◉*/
                                  (int)((_weeklyQuantity * 1000) / _app.defaultEspressoShotMg)];
        shotsLabel.text = [NSString stringWithFormat:@"%@", amountString];
        _weeklyQuantity = 0.0f;

        // Alpha
        [shotsLabel setAlpha:0.5f];
        [dayLabel setAlpha:0.5f];
    } else {
//        NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
//        [theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
//        [theDateFormatter setDateFormat:@"EE"];
//        NSString *dateString = [theDateFormatter stringFromDate:sample.startDate];
//        headerView.detailLabel.text = dateString;
//        headerView.detailLabel.text = @"";

        dayLabel.text = @"";
        shotsLabel.text = @"";
        [shotsLabel setAlpha:0.5f];
        [dayLabel setAlpha:0.5f];
    }

    if (!_compactTableMode) {
        headerView.visualEffectView.hidden = NO;
    } else {
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
    HKQuantitySample *sample = [sectionSamples objectAtIndex:((sectionSamples.count - 1) - indexPath.row)];
    
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
    NSString *shotsText;

    if ((int)[sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"mg"]] % (int)_app.defaultEspressoShotMg == 0) {
        int shotsCount = (int)([sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"mg"]] / _app.defaultEspressoShotMg);
        shotsText = [NSString stringWithFormat:@"%d %@",
                     shotsCount,
                     (shotsCount > 1) ? @"Shots" : @"Shot"];
    } else {
        shotsText = [NSString stringWithFormat:@"%d mg",
                 (int)[sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"mg"]]];
    }

    UILabel *cellText = (UILabel *)[cell viewWithTag:1];
    cellText.text = [NSString stringWithFormat:@"%@ %@",
                     shotsText,
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
    return (_maxValue / _minorStepInterval) + 1;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0,
                            (self.view.frame.size.width / 2) - 20,
                            0,
                            (self.view.frame.size.width / 2) - 20);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ScaleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    // labelInterval
    if ((indexPath.row * _minorStepInterval) % _labelInterval == 0) {
        cell.lineLabel.text = [NSString stringWithFormat:@"%ld",
                               indexPath.row * _minorStepInterval];
    } else {
        cell.lineLabel.text = @"";
    }

    // majorStepInterval
    if ((indexPath.row * _minorStepInterval) % _majorStepInterval == 0) {
        cell.lineWidthConstraint.constant = 5;
    } else {
        cell.lineWidthConstraint.constant = 1;
    }



    return cell;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([scrollView isKindOfClass:[UICollectionView class]] && !scrollView.isDecelerating && !scrollView.isDragging && !scrollView.isZoomBouncing) {
        [self centerCollectionView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([scrollView isKindOfClass:[UICollectionView class]]) {
        [self centerCollectionView];
    }
}

- (void)centerCollectionView {
    NSIndexPath *pathForCenterCell = [_scaleCollectionView indexPathForItemAtPoint:CGPointMake(
                                                                                               CGRectGetMidX(_scaleCollectionView.bounds),
                                                                                               CGRectGetMidY(_scaleCollectionView.bounds)
                                                                                               )
                                      ];
    if ([_scaleCollectionView cellForItemAtIndexPath:pathForCenterCell]) {
        if (pathForCenterCell.row == 0) {
            pathForCenterCell = [NSIndexPath indexPathForItem:1 inSection:0];
        }

        [_scaleCollectionView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        [self setQuantityFromScale:(pathForCenterCell.row * _minorStepInterval)];
    }
}

- (void)centerTable {
    NSIndexPath *pathForCenterCell = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];

    [self.tableView scrollToRowAtIndexPath:pathForCenterCell atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
    [self addAmount:_userQuantity];
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

- (IBAction)increaseServings:(id)sender {
    int userServings = (int)(_userQuantity / _servingQuantity);
    int newUserQuantity = (userServings + 1) * _servingQuantity;
    if (newUserQuantity <= (_maxValue)) {
        _userQuantity = newUserQuantity;
    } else {
        return;
    }

    NSString *newButtonLabel = @"";
    if ((int)_userQuantity % (int)_servingQuantity == 0) {
        switch ((int)(_userQuantity / _servingQuantity)) {
            case 1:
                newButtonLabel = [NSString stringWithFormat:@"One"];
                break;
            case 2:
                newButtonLabel = [NSString stringWithFormat:@"Two"];
                break;
            case 3:
                newButtonLabel = [NSString stringWithFormat:@"Three"];
                break;
            case 4:
                newButtonLabel = [NSString stringWithFormat:@"Four"];
                break;
            case 5:
                newButtonLabel = [NSString stringWithFormat:@"Five"];
                break;
            default:
                newButtonLabel = [NSString stringWithFormat:@"One"];
                break;
        }
        [self setAddCoffeeButtonTitle:newButtonLabel
                             subtitle:(_userQuantity > _servingQuantity) ? @"shots" : @"shot"];
    } else {
        newButtonLabel = [NSString stringWithFormat:@"%d", (int)_userQuantity];
        [self setAddCoffeeButtonTitle:newButtonLabel subtitle:@"gr"];
    }
    [self scrollScaleToQuantity:_userQuantity];
}

- (IBAction)decreaseServings:(id)sender {
    int userServings = (int)(_userQuantity / _servingQuantity);
    if (((int)_userQuantity % (int)_servingQuantity) != 0) {
        userServings++;
    }
    int newUserQuantity = (userServings - 1) * _servingQuantity;
    if (newUserQuantity >= _servingQuantity) {
        _userQuantity = newUserQuantity;
    } else {
        return;
    }

    NSString *newButtonLabel = @"";
    if ((int)_userQuantity % (int)_servingQuantity == 0) {
        switch ((int)(_userQuantity / _servingQuantity)) {
            case 1:
                newButtonLabel = [NSString stringWithFormat:@"One"];
                break;
            case 2:
                newButtonLabel = [NSString stringWithFormat:@"Two"];
                break;
            case 3:
                newButtonLabel = [NSString stringWithFormat:@"Three"];
                break;
            case 4:
                newButtonLabel = [NSString stringWithFormat:@"Four"];
                break;
            case 5:
                newButtonLabel = [NSString stringWithFormat:@"Five"];
                break;
            default:
                newButtonLabel = [NSString stringWithFormat:@"One"];
                break;
        }
        [self setAddCoffeeButtonTitle:newButtonLabel
                             subtitle:(_userQuantity > _servingQuantity) ? @"shots" : @"shot"];
    } else {
        newButtonLabel = [NSString stringWithFormat:@"%d", (int)_userQuantity];
        [self setAddCoffeeButtonTitle:newButtonLabel subtitle:@"gr"];
    }
    [self scrollScaleToQuantity:_userQuantity];
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
