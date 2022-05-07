/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of macOS window controller.
*/

#import "AAPLWindowController.h"
#import "AAPLViewControllerMac.h"

#define kToggleUIIdentifier (@"ToggleUI")

@interface AAPLWindowController ()

@end

@implementation AAPLWindowController
{
    __weak IBOutlet NSToolbar *_mainToolbar;
    __weak IBOutlet NSButton *_toggleUIButton;
}

// --
- (void)handleButtonState:(NSControlStateValue)state
{
    AAPLViewControllerMac* contentView = (AAPLViewControllerMac*)self.contentViewController;
    contentView.isUIDisplayed = (state == NSControlStateValueOn);
}

// --
- (void)windowDidLoad
{
    [super windowDidLoad];

    _mainToolbar.allowsUserCustomization = NO;
    _mainToolbar.allowsExtensionItems = NO;
    _mainToolbar.autosavesConfiguration = NO;

    _toggleUIButton.state = NSControlStateValueOn;
    [self handleButtonState:NSControlStateValueOn];
}

- (IBAction)toggleUIButtonCallback:(NSButton *)sender
{
    [self handleButtonState:sender.state];
}

@end
