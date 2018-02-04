//
//  NightShadeView.m
//  NightShade
//
//  Created by Erik Strottmann on 11/12/17.
//  Copyright © 2017 Erik Strottmann. All rights reserved.
//

#import "NightShadeView.h"

@interface NightShadeView ()
@property (nonatomic) NSFont *font;
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation NightShadeView

#pragma mark ScreenSaverView overrides

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        _font = [NSFont monospacedDigitSystemFontOfSize:40 weight:NSFontWeightRegular];
        _calendar = [NSCalendar currentCalendar];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

        [self setAnimationTimeInterval:1/30];
    }
    return self;
}

- (void)animateOneFrame
{
    NSDate *date = [NSDate date];
    NSColor *backgroundColor = [self backgroundColorFromDate:date];
    NSColor *foregroundColor = [self foregroundColorForBackgroundColor:backgroundColor];

    [backgroundColor set];
    NSRectFill([self frame]);

    NSAttributedString *timeString = [self stringFromDate:date color:foregroundColor];
    NSRect timeRect = [self rectForString:timeString];

    [timeString drawInRect:timeRect];
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow *)configureSheet
{
    return nil;
}

#pragma mark Helpers

- (NSColor *)backgroundColorFromDate:(NSDate *)date
{
    return [NSColor lightGrayColor];
}

- (NSColor *)foregroundColorForBackgroundColor:(NSColor *)backgroundColor
{
    return [NSColor darkGrayColor];
}

- (NSAttributedString *)stringFromDate:(NSDate *)date color:(NSColor *)color
{
    NSString *dateString = [[self dateFormatter] stringFromDate:date];

    NSDictionary<NSAttributedStringKey, id> *attributes = @{NSFontAttributeName: [self font],
                                                            NSForegroundColorAttributeName: color};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:dateString
                                                                                         attributes:attributes];

    if (![self shouldShowTimeSeparatorForDate:date]) {
        NSArray<NSTextCheckingResult *> *timeSeparatorMatches = [self matchesForTimeSeparatorInString:dateString];
        for (NSTextCheckingResult *match in timeSeparatorMatches) {
            [attributedString addAttribute:NSForegroundColorAttributeName
                                     value:[NSColor clearColor]
                                     range:[match range]];
        }
    }

    return attributedString;
}

- (BOOL)shouldShowTimeSeparatorForDate:(NSDate *)date
{
    NSInteger second = [[self calendar] component:NSCalendarUnitSecond fromDate:date];
    return second % 2 != 0;
}

- (NSArray<NSTextCheckingResult *> *)matchesForTimeSeparatorInString:(NSString *)string
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@":" options:0 error:nil];
    return [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
}

- (NSRect)rectForString:(NSAttributedString *)string
{
    NSSize size = [string size];
    NSRect stringRect = NSMakeRect(0, 0, size.width, size.height);
    return SSCenteredRectInRect(stringRect, [self frame]);
}

@end
