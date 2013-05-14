//
//  RMSwipeTableViewCell.m
//  RMSwipeTableView
//
//  Created by Rune Madsen on 2012-11-24.
//  Copyright (c) 2012 The App Boutique. All rights reserved.
//

#import "RMSwipeTableViewCell.h"

@interface RMSwipeTableViewCell ()

@end

@implementation RMSwipeTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // We need to set the contentView's background colour, otherwise the sides are clear on the swipe and animations
        [self.contentView setBackgroundColor:[UIColor whiteColor]];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [panGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:panGestureRecognizer];

        self.revealDirection = RMSwipeTableViewCellRevealDirectionRight;
        self.animationType = RMSwipeTableViewCellAnimationTypeBounce;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
        backgroundView.backgroundColor = [UIColor whiteColor];
        self.backgroundView = backgroundView;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint translation = [panGestureRecognizer translationInView:self.superview];
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan && [panGestureRecognizer numberOfTouches] > 0) {
        if ([self.delegate respondsToSelector:@selector(swipeTableViewCellDidStartSwiping:fromTouchLocation:)]) {
            [self.delegate swipeTableViewCellDidStartSwiping:self fromTouchLocation:translation];
        }
        [self animateContentViewForPoint:translation];
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged && [panGestureRecognizer numberOfTouches] > 0) {
        [self animateContentViewForPoint:translation];
	} else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
		[self resetBackViewFromPoint:translation];
	}
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    // We only want to deal with the gesture of it's a pan gesture
    if ([panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint translation = [panGestureRecognizer translationInView:[self superview]];
        return (fabs(translation.x) / fabs(translation.y) > 1) ? YES : NO;
    } else {
        return NO;
    }
}

#pragma mark - Gesture animations 

-(void)animateContentViewForPoint:(CGPoint)translation {
    if ((translation.x > 0 && self.revealDirection == RMSwipeTableViewCellRevealDirectionLeft) || (translation.x < 0 && self.revealDirection == RMSwipeTableViewCellRevealDirectionRight) || self.revealDirection == RMSwipeTableViewCellRevealDirectionBoth) {
        if (!_backView) {
            [self.backgroundView addSubview:self.backView];
        }
        float drag = 0;
        if (translation.x < 0) {
            drag = expf(translation.x / CGRectGetWidth(self.frame)) * translation.x;
        } else {
            drag = (1.0 / expf(translation.x / CGRectGetWidth(self.frame))) * translation.x;
        }
        self.contentView.frame = CGRectOffset(self.contentView.bounds, drag, 0);
        if ([self.delegate respondsToSelector:@selector(swipeTableViewCell:swipedToLocation:)]) {
            [self.delegate swipeTableViewCell:self swipedToLocation:translation];
        }
    }
}

-(void)resetBackViewFromPoint:(CGPoint)translation {
    if ([self.delegate respondsToSelector:@selector(swipeTableViewCellWillResetState:fromLocation:withAnimation:)]) {
        [self.delegate swipeTableViewCellWillResetState:self fromLocation:translation withAnimation:self.animationType];
    }
    if (self.animationType == RMSwipeTableViewCellAnimationTypeBounce) {
        [self animateVelocityBounce:translation];
    }
}

-(void)animateVelocityBounce:(CGPoint)translation {
    if ((self.revealDirection == RMSwipeTableViewCellRevealDirectionLeft && translation.x < 0) || (self.revealDirection == RMSwipeTableViewCellRevealDirectionRight && translation.x > 0)) {
        return;
    }
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.contentView.frame = CGRectOffset(self.contentView.bounds, 0 - (translation.x * 0.03), 0);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              self.contentView.frame = CGRectOffset(self.contentView.bounds, 0 + (translation.x * 0.02), 0);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.1
                                                                    delay:0
                                                                  options:UIViewAnimationOptionCurveEaseOut
                                                               animations:^{
                                                                   self.contentView.frame = self.contentView.bounds;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   if ([self.delegate respondsToSelector:@selector(swipeTableViewCellDidResetState:fromLocation:withAnimation:)]) {
                                                                       [self.delegate swipeTableViewCellDidResetState:self fromLocation:translation withAnimation:self.animationType];
                                                                   }
                                                               }
                                               ];
                                          }
                          ];
                     }
     ];
}

-(UIView*)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:self.contentView.frame];
        _backView.backgroundColor = [UIColor redColor];
    }
    return _backView;
}

@end
