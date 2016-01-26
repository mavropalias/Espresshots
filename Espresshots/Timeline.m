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
@property (weak, nonatomic) IBOutlet UIButton *removeServingButton;
@property (weak, nonatomic) IBOutlet UIButton *addServingButton;
@property (weak, nonatomic) IBOutlet UICollectionView *scaleCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tip1Label;
@property (weak, nonatomic) IBOutlet UILabel *tip2Label;
@property (strong, nonatomic) NSMutableDictionary *samples;
@property (strong, nonatomic) NSArray *samplesDictionaryKeysOrderedByDate;
@property (nonatomic, assign) BOOL shouldScrollToLastRow;
@property (strong, nonatomic) NSDateFormatter * theDateFormatter;
@property BOOL compactTableMode;
@property BOOL editingTable;
@property double highestOverallConsumptionInOneDay;
@property double userQuantity;
@property double servingQuantity;
@property double weeklyQuantity;
@property double monthlyQuantity;

@property int minValue;
@property int maxValue;
@property int labelInterval;
@property int minorStepInterval;
@property int majorStepInterval;

// UI Theme
@property (strong, nonatomic) UIColor *bgColor;
@property (strong, nonatomic) UIColor *textOnBgColor;
@property (strong, nonatomic) UIColor *tintColor;
@property (strong, nonatomic) UIColor *dailyProgressBarColor;
@property (strong, nonatomic) UIColor *dailyTextColor;
@property (strong, nonatomic) UIColor *sampleTextColor;

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
    _tableView.scrollsToTop = YES;
    _scaleCollectionView.scrollsToTop = NO;

    _samples = [[_app dictionaryFromSamples:_app.samples] mutableCopy];

    // Get highest consumption and remove the keys
    NSNumber *highestConsumptionTemp = [_samples objectForKey:@"highestOverallConsumptionInOneDay"];
    _highestOverallConsumptionInOneDay = [highestConsumptionTemp doubleValue];
    [_samples removeObjectForKey:@"highestOverallConsumptionInOneDay"];
    [_samples removeObjectForKey:@"highestSampleEntry"];


    _samplesDictionaryKeysOrderedByDate = [[_samples allKeys] sortedArrayUsingSelector:@selector(compare:)];
    _highestOverallConsumptionInOneDay = [(NSNumber *)[_samples objectForKey:@"highestOverallConsumptionInOneDay"] doubleValue];

    [self setAddCoffeeButtonTitle:@"One" subtitle:@"Shot"];

    _theDateFormatter = [[NSDateFormatter alloc] init];
    [_theDateFormatter setFormatterBehavior:NSDateFormatterBehaviorDefault];
    [_theDateFormatter setDateFormat:@"yyyyMMdd"];

    // config values
    _minValue = 0;
    _maxValue = 400;
    _servingQuantity = 75.0f;
    _userQuantity = _servingQuantity;
    _minorStepInterval = 5;
    _majorStepInterval = _servingQuantity;
    _labelInterval = 10;

    // style button bgs
    _addCoffeeButton.layer.cornerRadius = _addCoffeeButton.frame.size.height / 2;
    _addCoffeeButton.layer.masksToBounds = YES;

    _addServingButton.layer.cornerRadius = _addServingButton.frame.size.height / 2;
    _addServingButton.layer.masksToBounds = YES;

    _removeServingButton.layer.cornerRadius = _removeServingButton.frame.size.height / 2;
    _removeServingButton.layer.masksToBounds = YES;

    //[_app addBlurEffectToNavigationBar:self.navigationController.navigationBar];
    [self manageWelcomeMessageVisibility];
    [self getTheme];
    [self applyTheme];
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
        _shouldScrollToLastRow = NO;
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
    
    [_app fetchSamplesForType:caffeineConsumedType unit:[HKUnit gramUnit] days:180 completion:^(NSArray *samples, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _samples = [[_app dictionaryFromSamples:samples] mutableCopy];

            // Get highest consumption and remove the keys
            NSNumber *highestConsumptionTemp = [_samples objectForKey:@"highestOverallConsumptionInOneDay"];
            _highestOverallConsumptionInOneDay = [highestConsumptionTemp doubleValue];
            [_samples removeObjectForKey:@"highestOverallConsumptionInOneDay"];
            [_samples removeObjectForKey:@"highestSampleEntry"];

            _samplesDictionaryKeysOrderedByDate = [[_samples allKeys] sortedArrayUsingSelector:@selector(compare:)];
            [_tableView reloadData];
            [self manageWelcomeMessageVisibility];
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

- (void)manageWelcomeMessageVisibility {
    if (_samples.count > 0) {
        _welcomeLabel.hidden = YES;
        _tip1Label.hidden = YES;
        _tip2Label.hidden = YES;
    } else {
        _welcomeLabel.hidden = NO;
        _tip1Label.hidden = NO;
        _tip2Label.hidden = NO;
    }
}

- (void)getTheme {
    _bgColor = [_app colorWithHex:@"000000"];
    _textOnBgColor = [_app colorWithHex:@"FF197D"];
    _tintColor = [_app colorWithHex:@"93C3CC"];
    _dailyProgressBarColor = [_app colorWithHex:@"444444"];
    _dailyTextColor = [_app colorWithHex:@"bbbbbb"];
    _sampleTextColor = [_app colorWithHex:@"bbbbbb"];
}

- (void)applyTheme {
    self.view.backgroundColor = _bgColor;
    self.view.window.tintColor = _tintColor;
    self.navigationController.navigationBar.tintColor = _tintColor;
    
    // Welcome message
    _welcomeLabel.textColor = _textOnBgColor;
    _tip1Label.textColor = _textOnBgColor;
    _tip2Label.textColor = _textOnBgColor;
    
    _addCoffeeButton.backgroundColor = _tintColor;
    _addServingButton.backgroundColor = _tintColor;
    _removeServingButton.backgroundColor = _tintColor;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* button = [UIAlertAction
                             actionWithTitle:@"Ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 //Handel your yes please button action here
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [alert addAction:button];
    [self presentViewController:alert animated:YES completion:nil];
}





#pragma mark - Table DataSource

// numberOfSectionsInTableView
// =============================================================================
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _samples.count;
}

// heightForHeaderInSection
// =============================================================================
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44.0f;
}

// viewForHeaderInSection
// =============================================================================
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    TimelineHeaderView *headerView = [tableView dequeueReusableCellWithIdentifier:@"header"];
    NSString *sampleKey = [_samplesDictionaryKeysOrderedByDate objectAtIndex:section];
    NSMutableDictionary *dateDictionary = [_samples objectForKey:sampleKey];

    
    // Set quantity bar
    // -------------------------------------------------------------------------
    UIView *barView = (UIView *)[headerView viewWithTag:2];
    barView.backgroundColor = _dailyProgressBarColor;
    CGFloat progressWidthAdjustment = 0.9f;
    NSNumber *dailySum = [dateDictionary objectForKey:@"dailySum"];
    _weeklyQuantity += [dailySum doubleValue]; // TODO: change the way we calculate weekly sum
    _monthlyQuantity += [dailySum doubleValue]; // TODO: change the way we calculate monthly sum
    CGFloat progressWidth = 0;
    if (_highestOverallConsumptionInOneDay > 0) progressWidth = ((self.view.frame.size.width * [dailySum doubleValue]) / _highestOverallConsumptionInOneDay) * progressWidthAdjustment;
    if (progressWidth < 1.0f) {
        progressWidth = 1.0f;
    }
    headerView.progressViewWidthConstraint.constant = progressWidth;


    // Day & Shots
    // -------------------------------------------------------------------------
    UILabel *shotsLabel = (UILabel *)[headerView viewWithTag:1];
    UILabel *dayLabel = (UILabel *)[headerView viewWithTag:3];

    dayLabel.text = [dateDictionary objectForKey:@"date"];
    dayLabel.textColor = _dailyTextColor;

    NSNumber *shots = @(ceil(([dailySum doubleValue] * 1000) / _app.defaultEspressoShotMg));
    NSString *amountString = [NSString stringWithFormat:@"%@ Shots",/*◉*/ shots];
    shotsLabel.text = [NSString stringWithFormat:@"%@", amountString];
    shotsLabel.textColor = _dailyTextColor;

    [shotsLabel setAlpha:1.0f];
    [dayLabel setAlpha:1.0f];


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
    if (_compactTableMode && section != _samplesDictionaryKeysOrderedByDate.count - 1) return 0;
    
    NSString *sampleKey = [_samplesDictionaryKeysOrderedByDate objectAtIndex:section];
    NSMutableDictionary *dateDictionary = [_samples objectForKey:sampleKey];
    NSArray *samplesArray = [dateDictionary objectForKey:@"samples"];
    return samplesArray.count;
}

// cellForRowAtIndexPath
// =============================================================================
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    NSString *sampleKey = [_samplesDictionaryKeysOrderedByDate objectAtIndex:indexPath.section];
    NSMutableDictionary *dateDictionary = [_samples objectForKey:sampleKey];
    NSArray *samplesArray = [dateDictionary objectForKey:@"samples"];
    HKQuantitySample *sample = [samplesArray objectAtIndex:indexPath.row];
    
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
    detailText.textColor = _sampleTextColor;
    
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
    cellText.textColor = _sampleTextColor;

    return cell;
}

// canEditRowAtIndexPath
// =============================================================================
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *sampleKey = [_samplesDictionaryKeysOrderedByDate objectAtIndex:indexPath.section];
    NSMutableDictionary *dateDictionary = [_samples objectForKey:sampleKey];
    NSMutableArray *sectionSamples = [dateDictionary objectForKey:@"samples"];
    HKQuantitySample *sample = [sectionSamples objectAtIndex:indexPath.row];
    
    if ([sample.source.bundleIdentifier isEqualToString:_app.bundleIdentifier] || !sample.source.name) return YES;
    else return NO;
}

// commitEditingStyle
// =============================================================================
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sampleKey = [_samplesDictionaryKeysOrderedByDate objectAtIndex:indexPath.section];
    NSMutableDictionary *dateDictionary = [_samples objectForKey:sampleKey];
    NSMutableArray *sectionSamples = [dateDictionary objectForKey:@"samples"];
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

    // apply theme
    cell.line.backgroundColor = _sampleTextColor;
    cell.lineLabel.textColor = _sampleTextColor;



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
        
        NSRange range = NSMakeRange(0, _samples.count - 1); // TODO: fix this to count all samples instead of just sections
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
                
                NSString *sampleKey = [weakSelf.samplesDictionaryKeysOrderedByDate objectAtIndex:(_samplesDictionaryKeysOrderedByDate.count-1)];

                if (sampleKey) {
                    NSMutableDictionary *dateDictionary = [weakSelf.samples objectForKey:sampleKey];
                    NSMutableArray *sectionSamples = [dateDictionary objectForKey:@"samples"];
                    if (sectionSamples == nil) {
                        sectionSamples = [@[] mutableCopy];
                    }

                    [sectionSamples addObject:sample];
                    [weakSelf manageWelcomeMessageVisibility];

                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[weakSelf.tableView numberOfSections] - 1];
                    [weakSelf.tableView beginUpdates];
                    [weakSelf.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [weakSelf.tableView endUpdates];
                }

                [weakSelf refreshStatistics];
                NSLog(@"HK updated");
            } else {
                NSLog(@"Error: %@", error.description);
                if (error.code == 4) {
                    [weakSelf showAlertWithTitle:error.localizedDescription message:@"Espresshots is not authorized to write data in HealthKit. Please enable access in the Health app's settings."];
                }
            }
        });
    }];
}

- (void)deleteSample:(HKQuantitySample *)sample indexPath:(NSIndexPath *)indexPath {
    // Remove cell from table
    NSString *sampleKey = [_samplesDictionaryKeysOrderedByDate objectAtIndex:indexPath.section];
    NSMutableDictionary *dateDictionary = [_samples objectForKey:sampleKey];
    NSMutableArray *sectionSamples = [dateDictionary objectForKey:@"samples"];
    [sectionSamples removeObjectAtIndex:indexPath.row];

    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    // Remove sample from HK and refreshStatistics
    __unsafe_unretained typeof(self) weakSelf = self;
    [_app deleteSample:sample completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf refreshStatistics];
            NSLog(@"HK updated");
        });
    }];
}

@end
