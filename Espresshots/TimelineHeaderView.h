//
//  TimelineHeaderView.h
//  Espresshots
//
//  Created by Kostas on 22/05/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimelineHeaderView : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *visualEffectView;

@end
