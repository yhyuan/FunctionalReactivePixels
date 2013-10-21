//
//  FRPPhotoDetailViewController.m
//  FRP
//
//  Created by Ash Furrow on 10/15/2013.
//  Copyright (c) 2013 Ash Furrow. All rights reserved.
//

// View Controllers
#import "FRPPhotoDetailViewController.h"
#import "FRPLoginViewController.h"

// Model
#import "FRPPhotoModel.h"

// Utilities
#import "FRPPhotoImporter.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface FRPPhotoDetailViewController ()

// Private assignment
@property (nonatomic, strong) FRPPhotoModel *photoModel;

@end

@implementation FRPPhotoDetailViewController

-(instancetype)initWithPhotoModel:(FRPPhotoModel *)photoModel
{
    self = [self init];
    if (!self) return nil;
    
    self.photoModel = photoModel;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    @weakify(self);
    
    // Configure self
    self.title = self.photoModel.photoName;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil];
    self.navigationItem.rightBarButtonItem.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                [subscriber sendCompleted];
            }];
            
            return nil;
        }];
    }];
    
    // Configure self's view
    self.view.backgroundColor = [UIColor blackColor];
    
    // Configure subviews
    UILabel *ratingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.bounds), 100)];
    RAC(ratingLabel, text) = [RACObserve(self.photoModel, rating) map:^id(id value) {
        return [NSString stringWithFormat:@"%0.2f", [value floatValue]];
    }];
    ratingLabel.font = [UIFont boldSystemFontOfSize:80];
    ratingLabel.textColor = [UIColor whiteColor];
    ratingLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:ratingLabel];
    
    UILabel *photoNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(ratingLabel.frame), CGRectGetWidth(self.view.bounds), 20)];
    RAC(photoNameLabel, text) = RACObserve(self.photoModel, photoName);
    photoNameLabel.font = [UIFont systemFontOfSize:16];
    photoNameLabel.textColor = [UIColor whiteColor];
    photoNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:photoNameLabel];
    
    UILabel *photographerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(photoNameLabel.frame), CGRectGetWidth(self.view.bounds), 20)];
    RAC(photographerNameLabel, text) = RACObserve(self.photoModel, photographerName);
    photographerNameLabel.font = [UIFont systemFontOfSize:16];
    photographerNameLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
    photographerNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:photographerNameLabel];
    
    UIButton *voteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    voteButton.frame = CGRectMake(20, CGRectGetHeight(self.view.bounds) - 44 - 20, CGRectGetWidth(self.view.bounds) - 40, 44);
    voteButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    // Note: can't use getter keypath
    [RACObserve(self.photoModel, votedFor) subscribeNext:^(id x) {
        if ([x boolValue]) {
            [voteButton setTitle:@"Voted For!" forState:UIControlStateNormal];
        } else {
            [voteButton setTitle:@"Vote" forState:UIControlStateNormal];
        }
    }];
    voteButton.rac_command = [[RACCommand alloc] initWithEnabled:[RACObserve(self.photoModel, isVotedFor) not] signalBlock:^RACSignal *(id input) {
        if ([[PXRequest apiHelper] authMode] == PXAPIHelperModeNoAuth) {
            // Not logged in
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                @strongify(self);
                
                [[[self rac_signalForSelector:@selector(viewDidAppear:)] take:1] subscribeNext:^(id x) {
                    [[FRPPhotoImporter voteForPhoto:self.photoModel] replay];
                }];
                
                FRPLoginViewController *viewController = [[FRPLoginViewController alloc] initWithNibName:@"FRPLoginViewController" bundle:nil];
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
                
                [self presentViewController:navigationController animated:YES completion:^{
                    [subscriber sendCompleted];
                }];
                
                return nil;
            }];
        } else {
            return [FRPPhotoImporter voteForPhoto:self.photoModel];
        }
    }];
    [voteButton.rac_command.errors subscribeNext:^(id x) {
        [x subscribeNext:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }];
    }];
    [self.view addSubview:voteButton];
}

@end
