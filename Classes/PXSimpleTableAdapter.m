//
//  PXSimpleTableAdapter.m
//  PXSimpleTableAdapter
//
//  Created by Alex Rozanski on 25/03/2011.
//  Copyright 2011 Alex Rozanski. All rights reserved.
//

#import "PXSimpleTableAdapter.h"

#import "PXSimpleTableSection+Private.h"

@implementation PXSimpleTableAdapter

@synthesize tableView;
@synthesize sections = _sections;
@synthesize delegate = _delegate;

#pragma mark - Init/Dealloc

- (id)init
{
    if((self = [super init])) {
        _sections = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [_sections release], _sections=nil;
    
    [super dealloc];
}

#pragma mark - plist setup

- (BOOL)setUpTableFromPropertyList:(id)propertyList
{
    if(![propertyList isKindOfClass:[NSDictionary class]]&&![propertyList isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    NSArray *sections = nil;
    
    //Work out where the section data starts
    if([propertyList isKindOfClass:[NSArray class]]) {
        sections = propertyList;
    }
    else {
        //If we are using a dictionary take the first array that we can find
        NSArray *objects = [propertyList allObjects];
        
        for(id object in objects) {
            if([object isKindOfClass:[NSArray class]]) {
                sections = object;
                break;
            }
        }
        
        if(!sections) {
            return NO;
        }
    }
    
    NSMutableArray *newSections = [[NSMutableArray alloc] init];
    
    //Loop through the sections
    for(id section in sections) {
        if([section isKindOfClass:[NSDictionary class]]) {
            PXSimpleTableSection *newSection = [[PXSimpleTableSection alloc] initWithRows:nil];
            
            newSection.sectionHeaderTitle = [section objectForKey:@"headerTitle"];
            newSection.sectionFooterTitle = [section objectForKey:@"footerTitle"];
            
            NSArray *sectionRows = [section objectForKey:@"rows"];
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            
            //Loop through the rows
            for(id row in sectionRows) {
                if([row isKindOfClass:[NSDictionary class]]) {
                    PXSimpleTableRow *newRow = [[PXSimpleTableRow alloc] initWithTitle:[row objectForKey:@"title"]];
                    
                    //Set the icon if we have one
                    NSString *iconName = [row objectForKey:@"iconName"];
                    if(iconName) {
                        newRow.icon = [UIImage imageNamed:iconName];
                    }
                    
                    NSNumber *isDisclosureRow = [row objectForKey:@"isDisclosureRow"];
                    if(isDisclosureRow&&[isDisclosureRow isKindOfClass:[NSNumber class]]) {
                        
						if ([isDisclosureRow boolValue]) {
							newRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
						} else {
							newRow.accessoryType = UITableViewCellAccessoryNone;
						}
                    }
                    
                    [rows addObject:newRow];
                    [newRow release];
                }
                else {
                    [rows release];
                    [newSection release];
                    [newSections release];
                    return NO;
                }
            }
            
            newSection.rows = rows;
            [rows release];
            
            [newSections addObject:newSection];
            [newSection release];
        }
        else {
            [newSections release];
            return NO;
        }
    }
    
    self.sections = newSections;

    [newSections release];
    return YES;
}

#pragma mark - Section Management

- (void)addSection:(PXSimpleTableSection*)section
{
    NSUInteger index = [_sections count];
	[self insertSection:section atIndex:index];
}

- (void)insertSection:(PXSimpleTableSection *)section atIndex:(NSUInteger)index 
{
	[_sections insertObject:section atIndex:index];
	[self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)removeSection:(PXSimpleTableSection *)section 
{
	NSUInteger index = [_sections indexOfObject:section];
	[_sections removeObject:section];
	
	[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
}

- (PXSimpleTableSection*)sectionAtIndex:(NSUInteger)index
{
    return [self.sections objectAtIndex:index];
}

#pragma mark - Data Handling

- (PXSimpleTableRow*)rowAtIndexPath:(NSIndexPath*)indexPath
{
    return [[[self.sections objectAtIndex:indexPath.section] rows] objectAtIndex:indexPath.row];
}

#pragma mark - Selection

- (PXSimpleTableRow*)selectedRow
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    
    if(selectedIndexPath) {
        return [[[self.sections objectAtIndex:selectedIndexPath.section] rows] objectAtIndex:selectedIndexPath.row];
    }
    
    return nil;
}

- (void)deselectRow:(PXSimpleTableRow*)row
{
    [self.tableView deselectRowAtIndexPath:row.indexPath animated:YES];
}

#pragma mark - Custom Accessors

- (void)setTableView:(UITableView*)newTableView
{
    tableView.delegate = nil;
    tableView.dataSource = nil;
    
    tableView = newTableView;
    
    tableView.delegate = self;
    tableView.dataSource = self;
}

- (void)setSections:(NSArray*)newSections
{
    //Untag ourselves from the sections
    for(PXSimpleTableSection *theSection in _sections) {
        theSection.adapter=nil;
    }
    
	id old = _sections;
    _sections = [newSections mutableCopy];
	[old release];
    
    //Tag ourselves to the new sections
    for(PXSimpleTableSection *theSection in _sections) {
        theSection.adapter=self;
    }
    
    [self.tableView reloadData];
}

- (NSArray *)sections 
{
	return [[_sections copy] autorelease];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    PXSimpleTableSection *theSection = [self.sections objectAtIndex:section];
    
    return [theSection.rows count];
}

- (UITableViewCell*)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PXSimpleTableRow *row = [self rowAtIndexPath:indexPath];
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:[[row class] cellIdentifier]];
    
    if(!cell) {
        cell = [[[row class] newCellForRow] autorelease];
    }
    
    [row setUpContentsOfCell:cell];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	PXSimpleTableSection *section = [self.sections objectAtIndex:indexPath.section];
	PXSimpleTableRow *row = [section.rows objectAtIndex:indexPath.row];
	return [row rowHeight];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    PXSimpleTableSection *theSection = [self.sections objectAtIndex:section];
    
    return theSection.sectionHeaderTitle;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    PXSimpleTableSection *theSection = [self.sections objectAtIndex:section];
    
    return theSection.sectionFooterTitle;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	PXSimpleTableSection *section = [self.sections objectAtIndex:indexPath.section];
	PXSimpleTableRow *row = [section.rows objectAtIndex:indexPath.row];
	
	PXSimpleTableRowSelectionBlock selectionBlock = row.selectionBlock;
	if(selectionBlock) { 
        selectionBlock(row);
    }
	
    if([self.delegate respondsToSelector:@selector(simpleTableAdapter:didSelectRow:)]) {
        [self.delegate simpleTableAdapter:self didSelectRow:row];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	PXSimpleTableSection *section = [self.sections objectAtIndex:indexPath.section];
	PXSimpleTableRow *row = [section.rows objectAtIndex:indexPath.row];
	
	PXSimpleTableRowSelectionBlock accessoryTappedBlock = row.accessoryTappedBlock;
	if ((accessoryTappedBlock)) accessoryTappedBlock(row);
	
	if([self.delegate respondsToSelector:@selector(simpleTableAdapter:accessoryButtonTappedForRow:)]) {
        [self.delegate simpleTableAdapter:self accessoryButtonTappedForRow:row];
	}
}

@end
