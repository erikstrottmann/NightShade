//
//  NightShadeView.m
//  NightShade
//
//  Created by Erik Strottmann on 11/12/17.
//  Copyright © 2017 Erik Strottmann. All rights reserved.
//

#import "NightShadeView.h"

static NSString * const MODULE_NAME = @"com.erikstrottmann.NightShade";
static NSString * const KEY_SHOW_HEX_CODE = @"showHexCode";
static NSString * const KEY_TIME_SEPARATOR_OPTION = @"timeSeparatorOption";

typedef NS_ENUM(NSInteger, TimeSeparatorOption) {
    TimeSeparatorOptionNeverShow = 0,
    TimeSeparatorOptionFlash,
    TimeSeparatorOptionAlwaysShow,
};

@interface NightShadeView ()

@property (nonatomic) IBOutlet NSPanel *configSheet;
@property (weak) IBOutlet NSButton *showHexCodeCheckBox;
@property (weak) IBOutlet NSPopUpButton *timeSeparatorsPopUp;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) NSFont *timeFont;
@property (nonatomic) NSFont *hexFont;
@property (nonatomic) NSColor *darkTextColor;
@property (nonatomic) NSColor *lightTextColor;

@property (nonatomic) BOOL previousForegroundColorWasDark;

@property (nonatomic) BOOL showsHexCode;
@property (nonatomic) TimeSeparatorOption timeSeparatorOption;

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
            _timeFont = [NSFont monospacedDigitSystemFontOfSize:40 weight:NSFontWeightUltraLight];
            _hexFont = [NSFont monospacedDigitSystemFontOfSize:8 weight:NSFontWeightUltraLight];
        } else {
            _timeFont = [NSFont monospacedDigitSystemFontOfSize:200 weight:NSFontWeightUltraLight];
            _hexFont = [NSFont monospacedDigitSystemFontOfSize:40 weight:NSFontWeightUltraLight];
        }
        _darkTextColor = [NSColor colorWithWhite:0 alpha:0.5];
        _lightTextColor = [NSColor colorWithWhite:1 alpha:0.7];

        _previousForegroundColorWasDark = NO;

        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MODULE_NAME];
        [defaults registerDefaults:@{KEY_SHOW_HEX_CODE: @YES,
                                     KEY_TIME_SEPARATOR_OPTION: @(TimeSeparatorOptionNeverShow)}];

        [self setShowsHexCode:[defaults boolForKey:KEY_SHOW_HEX_CODE]];
        [self setTimeSeparatorOption:[defaults integerForKey:KEY_TIME_SEPARATOR_OPTION]];

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

    NSAttributedString *timeString = [self timeStringFromDate:date withForegroundColor:foregroundColor];
    NSRect timeRect = [self centeredRectForString:timeString];
    [timeString drawInRect:timeRect];

    if ([self showsHexCode]) {
        NSAttributedString *hexString = [self rgbHexStringFromColor:backgroundColor withForegroundColor:foregroundColor];
        NSRect hexRect = [self cornerRectForString:hexString];
        [hexString drawInRect:hexRect];
    }
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow *)configureSheet
{
    if (![self configSheet]) {
        [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ConfigSheet" owner:self topLevelObjects:nil];
    }

    [[self showHexCodeCheckBox] setState:[self showsHexCode]];
    [[self timeSeparatorsPopUp] selectItemAtIndex:[self timeSeparatorOption]];

    return [self configSheet];
}

#pragma mark IBActions

- (IBAction)cancelConfigSheet:(NSButton *)sender {
    [[NSApplication sharedApplication] endSheet:[self configSheet]];
}

- (IBAction)okConfigSheet:(id)sender {
    [self setShowsHexCode:[[self showHexCodeCheckBox] state]];
    [self setTimeSeparatorOption:[[self timeSeparatorsPopUp] indexOfSelectedItem]];

    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MODULE_NAME];
    [defaults setBool:[self showsHexCode] forKey:KEY_SHOW_HEX_CODE];
    [defaults setInteger:[self timeSeparatorOption] forKey:KEY_TIME_SEPARATOR_OPTION];
    [defaults synchronize];

    [[NSApplication sharedApplication] endSheet:[self configSheet]];
}

#pragma mark Helpers

- (NSColor *)backgroundColorFromDate:(NSDate *)date
{
    NSCalendarUnit units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponents = [[self calendar] components:units fromDate:date];

    CGFloat red = (CGFloat) [dateComponents valueForComponent:NSCalendarUnitHour];
    CGFloat green = (CGFloat) [dateComponents valueForComponent:NSCalendarUnitMinute];
    CGFloat blue = (CGFloat) [dateComponents valueForComponent:NSCalendarUnitSecond];

    CGFloat maxRed = (CGFloat) NSMaxRange([[self calendar] maximumRangeOfUnit:NSCalendarUnitHour]);
    CGFloat maxGreen = (CGFloat) NSMaxRange([[self calendar] maximumRangeOfUnit:NSCalendarUnitMinute]);
    CGFloat maxBlue = (CGFloat) NSMaxRange([[self calendar] maximumRangeOfUnit:NSCalendarUnitSecond]);

    return [NSColor colorWithRed:red / maxRed
                           green:green / maxGreen
                            blue:blue / maxBlue
                           alpha:1];
}

- (NSColor *)foregroundColorForBackgroundColor:(NSColor *)backgroundColor
{
    CGFloat luminance = [self luminanceOfColor:backgroundColor];
    if (luminance > 0.7 || (luminance > 0.65 && [self previousForegroundColorWasDark])) {
        [self setPreviousForegroundColorWasDark:YES];
        return [self darkTextColor];
    } else {
        [self setPreviousForegroundColorWasDark:NO];
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
    const CGFloat *colorComponents = CGColorGetComponents([color CGColor]);
    CGFloat red = colorComponents[0];
    CGFloat green = colorComponents[1];
    CGFloat blue = colorComponents[2];

    return (red * 299 + green * 587 + blue * 114) / 1000;
}

- (NSAttributedString *)timeStringFromDate:(NSDate *)date withForegroundColor:(NSColor *)foregroundColor
{
    NSString *dateString = [[self dateFormatter] stringFromDate:date];

    NSDictionary<NSAttributedStringKey, id> *attributes = @{NSFontAttributeName: [self timeFont],
                                                            NSForegroundColorAttributeName: foregroundColor};
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
    switch ([self timeSeparatorOption]) {
        case TimeSeparatorOptionNeverShow:
            return NO;
        case TimeSeparatorOptionFlash: {
            NSInteger second = [[self calendar] component:NSCalendarUnitSecond fromDate:date];
            return second % 2 != 0;
        }
        case TimeSeparatorOptionAlwaysShow:
            return YES;
    }
}

- (NSArray<NSTextCheckingResult *> *)matchesForTimeSeparatorInString:(NSString *)string
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@":" options:0 error:nil];
    return [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
}

- (NSAttributedString *)rgbHexStringFromColor:(NSColor *)color withForegroundColor:(NSColor *)foregroundColor
{
    const CGFloat *colorComponents = CGColorGetComponents([color CGColor]);
    long red = lround(colorComponents[0] * 0xFF);
    long green = lround(colorComponents[1] * 0xFF);
    long blue = lround(colorComponents[2] * 0xFF);
    NSString *hexString = [NSString stringWithFormat:@"#%02lX%02lX%02lX", red, green, blue];

    NSDictionary<NSAttributedStringKey, id> *attributes = @{NSFontAttributeName: [self hexFont],
                                                            NSForegroundColorAttributeName: foregroundColor};
    return [[NSAttributedString alloc] initWithString:hexString attributes:attributes];
}

- (NSRect)centeredRectForString:(NSAttributedString *)string
{
    NSSize size = [string size];
    NSRect stringRect = NSMakeRect(0, 0, size.width, size.height);
    return SSCenteredRectInRect(stringRect, [self frame]);
}

- (NSRect)cornerRectForString:(NSAttributedString *)string
{
    NSSize size = [string size];
    return NSMakeRect(size.height / 2, size.height * 7 / 24, size.width, size.height);
}

@end
