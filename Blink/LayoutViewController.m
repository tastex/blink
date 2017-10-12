//
//  LayoutViewController.m
//  LayoutViewController
//
//  Created by tastex on 19.07.17.
//  Copyright © 2017 Vladimir Bolotov. All rights reserved.
//

#import "LayoutViewController.h"


@interface LayoutViewController ()


@end

@implementation LayoutViewController

- (instancetype) init {
    return [self initWithType:@"=H"];
}

- (instancetype) initWithType:(NSString *)type {
    NSLog(@"init layoutVC with type: %@", type);
    self = [super init];
    self.currentType = type;
    return self;
}

- (NSMutableArray  *)viewControllers {
    if (!_viewControllers) _viewControllers = [[NSMutableArray alloc] init];
    return _viewControllers;
}

- (TermController *)selectedVC {
    if (!_selectedVC) _selectedVC = [self.viewControllers firstObject];
    return _selectedVC;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor grayColor]];
    [self addVC];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    [self updateContent];
  }];
}

- (void)addVC {
    if ((int) [self.viewControllers count] >= [LayoutViewController maxAmountOfVC]) return;
    
    TermController *term = [[TermController alloc] init];
    term.delegate = self.delegate;
    
    [self.viewControllers addObject:term];
    
    //[self setSelectedVC:term];
    [term.terminal performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
    [self updateChildViewControllers];
}

- (void)deleteVC:(id)vc {
    NSLog(@"delete TermController from LayoutVC");
    
    NSInteger idx = [self.viewControllers indexOfObject:vc];
    if(idx == NSNotFound) {
        return;
    }
    
    if (vc == self.selectedVC) self.selectedVC = nil;
    [self.viewControllers removeObject:vc];
    [vc removeFromParentViewController];
    
    NSInteger numViewControllers= [self.viewControllers count];
    if (numViewControllers == 0) {
        [self addVC];
    }else{
        
        TermController *termToFocus = [self.viewControllers firstObject];
        if (idx > 0) termToFocus = [self.viewControllers objectAtIndex:idx-1];
        
        [termToFocus.terminal performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
        [self updateContent];
    }

}


- (void)splitVCVertically {
    if (self.selectedVC == nil) return;
    
    CGRect frame = self.selectedVC.view.frame;
    CGFloat height = frame.size.height/2;
    
    [self.selectedVC.view setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height)];
    [self.selectedVC viewWillAppear:NO];
    
    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y+height, frame.size.width, height);
    TermController *term = [self insertViewControllerAboveSelectedWithViewFrame: newFrame];
    [term viewWillAppear:NO];
    
    [term.terminal performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
}

- (void)splitVCHorizontally {
    if (self.selectedVC == nil) return;
    
    CGRect frame = self.selectedVC.view.frame;
    CGFloat width = frame.size.width/2;
    
    [self.selectedVC.view setFrame:CGRectMake(frame.origin.x, frame.origin.y, width, frame.size.height)];
    [self.selectedVC viewWillAppear:NO];
    
    CGRect newFrame = CGRectMake(frame.origin.x+width, frame.origin.y, width, frame.size.height);
    TermController *term = [self insertViewControllerAboveSelectedWithViewFrame: newFrame];
    [term viewWillAppear:NO];
    
    [term.terminal performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
}

- (TermController *)insertViewControllerAboveSelectedWithViewFrame:(CGRect)frame {
    TermController *term = [[TermController alloc] init];
    term.delegate = self.delegate;
    term.view.frame = frame;
    NSUInteger newVCIndex = [self.viewControllers indexOfObject:self.selectedVC] + 1;
    
    [self addChildViewController:term];
    [self.viewControllers insertObject:term atIndex:newVCIndex];
    [self.view insertSubview:term.view aboveSubview:self.selectedVC.view];
    
    
    return term;
}


- (void)updateChildViewControllers {
    for (UIViewController *vc in self.viewControllers) {
        if ([self.childViewControllers containsObject:vc] == NO) {
            [self addChildViewController:vc];
            [self.view addSubview:vc.view];
        }
    }
    [self updateContent];
}

- (void)setCurrentType:(NSString *)currentType {
    if (_currentType != currentType) {
        _currentType = currentType;
    }
    [self updateContent];
}


- (void)updateContent{
    
    for (UIViewController *childVC in self.viewControllers) {
        CGRect frame = [self getViewFrameForViewController: childVC];
        [childVC.view setFrame:frame];
    }

}




- (CGRect)getViewFrameForViewController:(UIViewController *)vc {
    int amountOfVC = (int) [self.viewControllers count];
    
    if (amountOfVC == 0) {
        return CGRectNull;
    }
    
    CGRect frame = self.view.frame;
    
    int indexOfVC = (int) [self.viewControllers indexOfObject:vc];
    
    if ([self.currentType rangeOfString:@"+H"].location != NSNotFound ) {
        
        frame.size.height = amountOfVC > 1 ? frame.size.height/2 : frame.size.height;
        
        if (indexOfVC == 0) return frame;
        
        frame.origin.y = frame.size.height;
        indexOfVC = indexOfVC-1;
        amountOfVC = amountOfVC-1;
    }else if ([self.currentType rangeOfString:@"+V"].location != NSNotFound ) {
        
        frame.size.width = amountOfVC > 1 ? frame.size.width/2 : frame.size.width;
        
        if (indexOfVC == 0) return frame;
        
        frame.origin.x = frame.size.width;
        indexOfVC = indexOfVC-1;
        amountOfVC = amountOfVC-1;
    }
    
    
    
    CGFloat width = frame.size.width/amountOfVC;
    CGFloat height = frame.size.height;
    CGFloat x = frame.origin.x + width*indexOfVC;
    CGFloat y = frame.origin.y;
    
    
    if ([self.currentType rangeOfString:@"V"].location != NSNotFound ) {
        width = frame.size.width;
        height = frame.size.height/amountOfVC;
        x = frame.origin.x;
        y = frame.origin.y + height*indexOfVC;
    }
    
    return CGRectMake(x, y, width, height);
}



- (NSArray *)layoutTypes {
    if (!_layoutTypes) _layoutTypes = [[NSArray alloc] initWithObjects:@"=H", @"=V", @"1+H", @"1+V", nil];
    return _layoutTypes;
}

+ (int)maxAmountOfVC { return 25;}




@end
