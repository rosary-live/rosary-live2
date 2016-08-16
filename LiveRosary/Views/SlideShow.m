//
//  SlideShow.m
//  LiveRosary
//
//  Created by Richard Taylor on 3/28/16.
//  Copyright © 2016 PocketCake. All rights reserved.
//

#import "SlideShow.h"
#import "ConfigModel.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface SlideShow ()

@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic, strong) UIImageView* slideImage1;
@property (nonatomic, strong) UIImageView* slideImage2;
@property (nonatomic) BOOL image1;
@property (nonatomic) BOOL firstTime;
@property (nonatomic) NSInteger lastSlideIndex;

@end

@implementation SlideShow

- (void)awakeFromNib
{
    self.lastSlideIndex = -1;
    self.firstTime = YES;
    self.image1 = YES;
    
    self.slideImage1 = [[UIImageView alloc] initWithFrame:self.frame];
    self.slideImage1.contentMode = UIViewContentModeScaleAspectFill;
    self.slideImage1.backgroundColor = [UIColor clearColor];
    self.slideImage1.opaque = NO;
    self.slideImage1.alpha = 1.0;
    [self addSubview:self.slideImage1];
    
    self.slideImage2 = [[UIImageView alloc] initWithFrame:self.frame];
    self.slideImage2.contentMode = UIViewContentModeScaleAspectFill;
    self.slideImage2.backgroundColor = [UIColor clearColor];
    self.slideImage2.opaque = NO;
    self.slideImage2.alpha = 0.0;
    [self addSubview:self.slideImage2];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)start
{
    if(self.timer == nil)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.changeInterval target:self selector:@selector(changeSlide) userInfo:nil repeats:YES];
    }
    
    [self changeSlide];
}

- (void)stop
{
    if(self.timer != nil)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)changeSlide
{
    if(self.hidden) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned int randomSlideIndex;

        do
        {
            randomSlideIndex = arc4random() % [ConfigModel sharedInstance].slideImageURLs.count;
        } while(randomSlideIndex == self.lastSlideIndex);
        
        self.lastSlideIndex = randomSlideIndex;
        
        NSString* slideImageURL = [ConfigModel sharedInstance].slideImageURLs[randomSlideIndex];
        
        if(self.firstTime)
        {
            self.firstTime = NO;
            [self.slideImage1 sd_setImageWithURL:[NSURL URLWithString:slideImageURL]];
        }
        else
        {
            if(self.image1)
            {
                [self.slideImage1 sd_setImageWithURL:[NSURL URLWithString:slideImageURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    
                    [UIView animateWithDuration:0.5 animations:^{
                        self.slideImage1.alpha = 1.0;
                        self.slideImage2.alpha = 0.0;
                    }];
                }];
            }
            else
            {
                [self.slideImage2 sd_setImageWithURL:[NSURL URLWithString:slideImageURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    
                    [UIView animateWithDuration:0.5 animations:^{
                        self.slideImage1.alpha = 0.0;
                        self.slideImage2.alpha = 1.0;
                    }];
                }];
            }
        }
        
        self.image1 = !self.image1;
    });
}

@end
