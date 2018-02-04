//
//  AppDelegate.m
//  NightShadeDebug
//
//  Created by Erik Strottmann on 11/12/17.
//  Copyright © 2017 Erik Strottmann. All rights reserved.
//

#import "AppDelegate.h"
#import "NightShadeView.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property NightShadeView *nightShadeView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.nightShadeView = [[NightShadeView alloc] initWithFrame:self.window.contentView.bounds isPreview:NO];
    [self.window.contentView addSubview:self.nightShadeView];
}

@end
