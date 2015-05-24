//
//  Timeline.h
//  Espresshots
//
//  Created by Kostas on 16/02/2015.
//  Copyright (c) 2015 gl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "App.h"

@interface Timeline : UIViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource>

- (void)setApp:(App *)app;
- (void)refreshStatistics;

@end

