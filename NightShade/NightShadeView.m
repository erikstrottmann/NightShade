//
//  NightShadeView.m
//  NightShade
//
//  Created by Erik Strottmann on 11/12/17.
//  Copyright © 2017 Erik Strottmann. All rights reserved.
//

#import "NightShadeView.h"

@interface NightShadeView ()

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) NSFont *font;
@property (nonatomic) NSColor *darkTextColor;
@property (nonatomic) NSColor *lightTextColor;

@end

@implementation NightShadeView

#pragma mark ScreenSaverView overrides

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"HH:mm:ss"];

        if (isPreview) {
            _font = [NSFont monospacedDigitSystemFontOfSize:40 weight:NSFontWeightUltraLight];
        } else {
            _font = [NSFont monospacedDigitSystemFontOfSize:200 weight:NSFontWeightUltraLight];
        }
        _darkTextColor = [NSColor colorWithWhite:0 alpha:0.7];
        _lightTextColor = [NSColor colorWithWhite:1 alpha:0.7];

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
    NSCalendarUnit units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponents = [[self calendar] components:units fromDate:date];

    CGFloat red = (CGFloat) [dateComponents valueForComponent:NSCalendarUnitHour];
    CGFloat green = (CGFloat) [dateComponents valueForComponent:NSCalendarUnitMinute];
    CGFloat blue = (CGFloat) [dateComponents valueForComponent:NSCalendarUnitSecond];

    CGFloat maxRed, maxGreen, maxBlue;
    BOOL useTimeAsPercentage = YES;
    if (useTimeAsPercentage) {
        maxRed = (CGFloat) NSMaxRange([[self calendar] maximumRangeOfUnit:NSCalendarUnitHour]);
        maxGreen = (CGFloat) NSMaxRange([[self calendar] maximumRangeOfUnit:NSCalendarUnitMinute]);
        maxBlue = (CGFloat) NSMaxRange([[self calendar] maximumRangeOfUnit:NSCalendarUnitSecond]);
    } else {
        maxRed = 0xFF;
        maxGreen = 0xFF;
        maxBlue = 0xFF;
    }

    return [NSColor colorWithRed:red / maxRed
                           green:green / maxGreen
                            blue:blue / maxBlue
                           alpha:1];
}

- (NSColor *)foregroundColorForBackgroundColor:(NSColor *)backgroundColor
{
    if ([self luminanceOfColor:backgroundColor] > 0.5) {
        return [self darkTextColor];
    } else {
        return [self lightTextColor];
    }
}

/**
 The luminance (perceived brightness) of the color, as a value in the range 0–1.0.

 Calculated using the W3C formula from http://www.w3.org/WAI/ER/WD-AERT/#color-contrast

 @param color The color to calculate the luminance of.
 @return The luminance of the given color.
 */
- (CGFloat)luminanceOfColor:(NSColor *)color
{
    // ((Red value X 299) + (Green value X 587) + (Blue value X 114)) / 1000
    return 0;
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
