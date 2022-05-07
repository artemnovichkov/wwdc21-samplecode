/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for view controller.
*/

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "AAPLRenderer.h"

@interface AAPLViewController : NSViewController

@property (nonatomic, weak) IBOutlet NSSegmentedControl* renderModeControl;
@property (nonatomic, weak) IBOutlet NSSlider* speedSlider;
@property (nonatomic, weak) IBOutlet NSView* configBackdrop;

- (IBAction)onRenderModeSegmentedControlAction:(id)sender;
- (IBAction)onSpeedSliderAction:(id)sender;

@end
