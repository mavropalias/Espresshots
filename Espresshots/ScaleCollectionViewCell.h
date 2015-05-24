//
//  ScaleCollectionViewCell.h
//  Espresshots
//
//  Created by Kostas on 25/05/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScaleCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *line;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineWidthConstraint;
@property (weak, nonatomic) IBOutlet UILabel *lineLabel;


@end
