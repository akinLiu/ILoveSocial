//
//  LNRootViewController.m
//  SocialFusion
//
//  Created by Blue Bitch on 12-1-19.
//  Copyright (c) 2012年 Tongji Apple Club. All rights reserved.
//

#import "LNRootViewController.h"
#import "LabelConverter.h"
#import "RenrenUser+Addition.h"
#import "WeiboUser+Addition.h"
#import "NSNotificationCenter+Addition.h"

#define CONTENT_VIEW_ORIGIN_X   7
#define CONTENT_VIEW_ORIGIN_Y   64

#define USER_NOT_OPEN   0

@implementation LNRootViewController;

@synthesize labelBarViewController = _labelBarViewController;
@synthesize contentViewController = _contentViewController;

- (void)dealloc {
    [_labelBarViewController release];
    [_contentViewController release];
    [_openedUserHeap release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *labelIdentifier = [LabelConverter getSystemDefaultLabelsIdentifier];
    _contentViewController = [[LNContentViewController alloc] initWithLabelIdentifiers:labelIdentifier andUsers:self.userDict];
    [self.view addSubview:self.contentViewController.view];
    self.contentViewController.delegate = self;
    self.contentViewController.view.frame = CGRectMake(CONTENT_VIEW_ORIGIN_X, CONTENT_VIEW_ORIGIN_Y, self.contentViewController.view.frame.size.width, self.contentViewController.view.frame.size.height);
    
    [self.view addSubview:self.labelBarViewController.view];
    
    [NSNotificationCenter registerSelectFriendNotificationWithSelector:@selector(selectFriendNotification:) target:self];
    [NSNotificationCenter registerSelectChildLabelNotificationWithSelector:@selector(selectChildLabelNotification:) target:self];
    
    //[self dropLabelBar];
}

- (id)init {
    self = [super init];
    if(self) {
        NSArray *labelInfo = [LabelConverter getSystemDefaultLabelsInfo];
        _labelBarViewController = [[LNLabelBarViewController alloc] initWithLabelInfoArray:labelInfo];
        _labelBarViewController.delegate = self;
        _openedUserHeap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSUInteger)getOpenedUserIndex:(User *)user {
    NSUInteger result = USER_NOT_OPEN;
    if([user isMemberOfClass:[RenrenUser class]]) {
        if([self.renrenUser isEqualToUser:(RenrenUser *)user])
            result = [LabelConverter getSystemDefaultLabelIndexWithIdentifier:KParentUserInfo];
    }
    else if([user isMemberOfClass:[WeiboUser class]]) {
        if([self.weiboUser isEqualToUser:(WeiboUser *)user])
            result = [LabelConverter getSystemDefaultLabelIndexWithIdentifier:KParentUserInfo];
    }
    if(result == USER_NOT_OPEN) {
        NSNumber *storediIndex = [_openedUserHeap objectForKey:user.userID];
        if(storediIndex) {
            result = storediIndex.unsignedIntValue;
        }
    }
    return result;
}

#pragma mark -
#pragma mark LNLabelBarViewController delegate

- (void)labelBarView:(LNLabelBarViewController *)labelBar didSelectParentLabelAtIndex:(NSUInteger)index {
    self.contentViewController.currentContentIndex = index;
}

- (void)labelBarView:(LNLabelBarViewController *)labelBar didSelectChildLabelWithIndentifier:(NSString *)identifier inParentLabelAtIndex:(NSUInteger)index {
    [self.contentViewController setContentViewAtIndex:index forIdentifier:identifier];
}

- (void)labelBarView:(LNLabelBarViewController *)labelBar didRemoveParentLabelAtIndex:(NSUInteger)index {
    [self.contentViewController removeContentViewAtIndex:index];
    NSLog(@"open user heap count:%d", _openedUserHeap.count);
    [_openedUserHeap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSNumber *openedUserIndex = obj;
        if(openedUserIndex.unsignedIntValue == index) {
            [_openedUserHeap removeObjectForKey:key];
            *stop = YES;
        }
    }];
    [_openedUserHeap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSNumber *openedUserIndex = obj;
        if(openedUserIndex.unsignedIntValue > index){
            [_openedUserHeap setObject:[NSNumber numberWithUnsignedInt:openedUserIndex.unsignedIntValue - 1] forKey:key];
        }
    }];
}

- (void)labelBarView:(LNLabelBarViewController *)labelBar willOpenParentLabelAtIndex:(NSUInteger)index {
    NSString *identifier = [self.contentViewController currentContentIdentifierAtIndex:index];
    [self.labelBarViewController selectChildLabelWithIdentifier:identifier];
}

#pragma mark -
#pragma mark handle notifications

- (void)selectChildLabelNotification:(NSNotification *)notification {
    NSString *identifier = notification.object;
    if([identifier isEqualToString:kChildCurrentWeiboFollower] || [identifier isEqualToString:kChildCurrentWeiboFriend]) {
        NSUInteger parentFriendLabelIndex = [LabelConverter getSystemDefaultLabelIndexWithIdentifier:kParentFriend];
        [self.contentViewController setContentViewAtIndex:parentFriendLabelIndex forIdentifier:[identifier stringByReplacingOccurrencesOfString:@"Current" withString:@""]];
        [self.labelBarViewController selectParentLabelAtIndex:parentFriendLabelIndex];
    }
    else {
        [self.labelBarViewController selectChildLabelWithIdentifier:identifier];
        [self.contentViewController setContentViewAtIndex:self.contentViewController.currentContentIndex forIdentifier:identifier];
    }
}

- (void)selectFriendNotification:(NSNotification *)notification {
    NSDictionary *userDict = notification.object;
    NSString *identifier;
    User *selectedUser;
    
    if([userDict objectForKey:kWeiboUser]) {
        identifier = kParentWeiboUser;
        selectedUser = [userDict objectForKey:kWeiboUser];
    }
    else if([userDict objectForKey:kRenrenUser]) {
        identifier = kParentRenrenUser;
        selectedUser = [userDict objectForKey:kRenrenUser];
    }
    
    NSUInteger openedUserIndex = [self getOpenedUserIndex:selectedUser];
    if(openedUserIndex != USER_NOT_OPEN) {
        [self.labelBarViewController selectParentLabelAtIndex:openedUserIndex];
        return;
    }
    
    if(!self.labelBarViewController.isSelectUserLock) {
        NSLog(@"selected user:%@, user id:%@", selectedUser.name, selectedUser.userID);
        [_openedUserHeap setObject:[NSNumber numberWithUnsignedInt:self.labelBarViewController.parentLabelCount] forKey:selectedUser.userID];
        LabelInfo *labelInfo = [LabelConverter getLabelInfoWithIdentifier:identifier];
        labelInfo.isRemovable = YES;
        labelInfo.labelName = selectedUser.name;
        labelInfo.targetUser = selectedUser;
        [self.contentViewController addUserContentViewWithIndentifier:identifier andUsers:userDict];
        [self.labelBarViewController createLabelWithInfo:labelInfo];
    }
}

#pragma mark - 
#pragma makr LNContentViewController delegate

- (void)contentViewController:(LNContentViewController *)vc didScrollToIndex:(NSUInteger)index {
    [self.labelBarViewController selectParentLabelAtIndex:index];
}

#pragma mark -
#pragma mark Animations

- (void)dropLabelBar {
    CGRect labelBarFrame = self.labelBarViewController.view.frame;
    CGFloat offset = 460.0f - labelBarFrame.size.height;
    if(labelBarFrame.origin.y == offset)
        return;
    labelBarFrame.origin.y = offset;
    
    CGRect contentFrame = self.contentViewController.view.frame;
    contentFrame.origin.y = CONTENT_VIEW_ORIGIN_Y + offset;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.labelBarViewController.view.frame = labelBarFrame;
        self.contentViewController.view.frame = contentFrame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)raiseLabelBar {
    CGRect labelBarFrame = self.labelBarViewController.view.frame;
    if(labelBarFrame.origin.y == 0)
        return;
    labelBarFrame.origin.y = 0;
    
    CGRect contentFrame = self.contentViewController.view.frame;
    contentFrame.origin.y = CONTENT_VIEW_ORIGIN_Y;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.labelBarViewController.view.frame = labelBarFrame;
        self.contentViewController.view.frame = contentFrame;
    } completion:^(BOOL finished) {
        
    }];
}

@end
