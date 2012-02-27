//
//  NewBlogViewController.h
//  SocialFusion
//
//  Created by He Ruoyun on 12-2-26.
//  Copyright (c) 2012年 TJU. All rights reserved.
//

#import "PostViewController.h"

@interface NewBlogViewController : PostViewController<UIScrollViewDelegate> {
    BOOL _postToRenren;
    BOOL _postToWeibo;
    NSUInteger _currentPage;
}

@property (nonatomic, retain) IBOutlet UITextView *blogTextView;

@property (nonatomic, retain) IBOutlet UIButton *postRenrenButton;
@property (nonatomic, retain) IBOutlet UIButton *postWeiboButton;

@property (nonatomic, retain) IBOutlet UIButton *blogBodyButton;
@property (nonatomic, retain) IBOutlet UIButton *blogTitleButton;

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

- (IBAction)didClickPostToRenrenButton:(id)sender;
- (IBAction)didClickPostToWeiboButton:(id)sender;

- (IBAction)didClickBlogTitleButton:(id)sender;
- (IBAction)didClickBlogBodyButton:(id)sender;

@end
