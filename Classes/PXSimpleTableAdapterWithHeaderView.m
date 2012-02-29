//
//  PXSimpleTableAdapterWithHeaderView.m
//  PXSimpleTableAdapterWithHeaderView
//
//  Created by Alex Rozanski on 25/03/2011.
//  Copyright 2011 Alex Rozanski. All rights reserved.
//

#import "PXSimpleTableAdapterWithHeaderView.h"

@implementation PXSimpleTableAdapterWithHeaderView

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    PXSimpleTableSection *theSection = [self.sections objectAtIndex:section];
	return theSection.sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    PXSimpleTableSection *theSection = [self.sections objectAtIndex:section];
	return theSection.sectionHeaderView.frame.size.height;
}

@end
