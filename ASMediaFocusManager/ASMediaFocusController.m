//
//  ASMediaFocusViewController.m
//  ASMediaFocusManager
//
//  Created by Philippe Converset on 21/12/12.
//  Copyright (c) 2012 AutreSphere. All rights reserved.
//

#import "ASMediaFocusController.h"
#import "NonBlockingAlertView.h"

static NSTimeInterval const kDefaultOrientationAnimationDuration = 0.4;

@interface ASMediaFocusController ()

@property(nonatomic, assign) UIDeviceOrientation previousOrientation;

@end

@implementation ASMediaFocusController
@synthesize buttonPanel = _buttonPanel;

static UIImage *normalImage;
static UIImage *highlightedImage;

- (void)viewDidUnload {
    [self setMainImageView:nil];
    [self setContentView:nil];
    [super viewDidUnload];
}

+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size; {
    UIImage *img = nil;

    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

+ (void)initialize {
    [super initialize];
    normalImage = [ASMediaFocusController imageWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.2] andSize:CGSizeMake(10, 10)];
    highlightedImage = [ASMediaFocusController imageWithColor:[[UIColor blackColor] colorWithAlphaComponent:0.7] andSize:CGSizeMake(10, 10)];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect rect = _contentView.frame;
    rect.origin.y = rect.size.height - 70;
    rect.size.width = 200;
    rect.size.height = 60;

    _buttonPanel = [[UIView alloc] initWithFrame:rect];
    _buttonPanel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _buttonPanel.alpha = 0;


    // Download
    UIButton *button = [self getButton];
    [button setTitle:@"\uf106" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 100, 60);
    [_buttonPanel addSubview:button];

    // Share
    button = [self getButton];
    [button setTitle:@"\uf107" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(shareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(100, 0, 100, 60);
    [_buttonPanel addSubview:button];

    [_contentView addSubview:_buttonPanel];
}

- (UIButton *)getButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont fontWithName:@"lohasus" size:36];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(6, 0, 0, 0)];
    [button setBackgroundImage:normalImage forState:UIControlStateNormal];
    [button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    return button;
}

- (void)saveButtonPressed {
    if (self.mainImageView.image) {
        UIImageWriteToSavedPhotosAlbum(self.mainImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(id)image didFinishSavingWithError:(id)error contextInfo:(id)contextInfo {
    if (error) {
        [NonBlockingAlertView showFailureAlertViewWithMessage:[error localizedDescription]];
    }
    [NonBlockingAlertView showSuccessAlertViewWithMessage:@"图片已保存"];
}

- (void)shareButtonPressed {
    [[NSNotificationCenter defaultCenter] postNotificationName:LUNProductImageShare object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)isParentSupportingInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortrait;

        case UIInterfaceOrientationPortraitUpsideDown:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskPortraitUpsideDown;

        case UIInterfaceOrientationLandscapeLeft:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeLeft;

        case UIInterfaceOrientationLandscapeRight:
            return [self.parentViewController supportedInterfaceOrientations] & UIInterfaceOrientationMaskLandscapeRight;
    }
}

#pragma mark - Public
- (void)updateOrientationAnimated:(BOOL)animated {
    CGAffineTransform transform;
    CGRect frame;
    NSTimeInterval duration = kDefaultOrientationAnimationDuration;

    if ([UIDevice currentDevice].orientation == self.previousOrientation)
        return;

    if ((UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation) && UIInterfaceOrientationIsLandscape(self.previousOrientation))
            || (UIInterfaceOrientationIsPortrait([UIDevice currentDevice].orientation) && UIInterfaceOrientationIsPortrait(self.previousOrientation))) {
        duration *= 2;
    }

    if (([UIDevice currentDevice].orientation == UIInterfaceOrientationPortrait)
            || [self isParentSupportingInterfaceOrientation:[UIDevice currentDevice].orientation]) {
        transform = CGAffineTransformIdentity;
    }
    else {
        switch ([UIDevice currentDevice].orientation) {
            case UIInterfaceOrientationLandscapeLeft:
                if (self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait) {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                else {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
            break;

            case UIInterfaceOrientationLandscapeRight:
                if (self.parentViewController.interfaceOrientation == UIInterfaceOrientationPortrait) {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                else {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
            break;

            case UIInterfaceOrientationPortrait:
                transform = CGAffineTransformIdentity;
            break;

            case UIInterfaceOrientationPortraitUpsideDown:
                transform = CGAffineTransformMakeRotation(M_PI);
            break;

            case UIDeviceOrientationFaceDown:
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationUnknown:
                return;
        }
    }

    if (animated) {
        frame = self.contentView.frame;
        [UIView animateWithDuration:duration
                         animations:^{
                             self.contentView.transform = transform;
                             self.contentView.frame = frame;
                         }];
    }
    else {
        frame = self.contentView.frame;
        self.contentView.transform = transform;
        self.contentView.frame = frame;
    }
    self.previousOrientation = [UIDevice currentDevice].orientation;
}

#pragma mark - Notifications
- (void)orientationDidChangeNotification:(NSNotification *)notification {
    [self updateOrientationAnimated:YES];
}
@end
