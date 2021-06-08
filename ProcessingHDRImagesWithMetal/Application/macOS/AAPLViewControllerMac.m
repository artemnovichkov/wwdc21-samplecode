/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of macOS view controller.
*/

#import "AAPLViewControllerMac.h"
#import "AAPLRenderer.h"
#import "UIOptionEnums.h"
#import "AAPLMathUtilities.h"
#import "AAPLUtility.hpp"
#import "UIDefaults.h"

@implementation AAPLViewControllerMac
{
    MTKView *_view;
    AAPLRenderer *_renderer;

    __weak IBOutlet NSSwitch *_postProcessingEnabled;

    __weak IBOutlet NSTextField *_bloomSectionLabel;

    __weak IBOutlet NSTextField *_bloomIntensityLabel;
    __weak IBOutlet NSSlider *_bloomIntensitySlider;
    __weak IBOutlet NSTextField *_bloomIntensityTextField;

    __weak IBOutlet NSTextField *_bloomThresholdLabel;
    __weak IBOutlet NSSlider *_bloomThresholdSlider;
    __weak IBOutlet NSTextField *_bloomThresholdTextField;

    __weak IBOutlet NSTextField *_bloomRangeLabel;
    __weak IBOutlet NSSlider *_bloomRangeSlider;
    __weak IBOutlet NSTextField *_bloomRangeTextField;

    __weak IBOutlet NSTextField *_exposureSectionLabel;

    __weak IBOutlet NSTextField *_exposureTypeLabel;
    __weak IBOutlet NSPopUpButton *_exposureTypePopUp;

    __weak IBOutlet NSTextField *_manualExposureLabel;
    __weak IBOutlet NSSlider *_manualExposureSlider;
    __weak IBOutlet NSTextField *_manualExposureTextField;

    __weak IBOutlet NSTextField *_exposureKeyLabel;
    __weak IBOutlet NSSlider *_exposureKeySlider;
    __weak IBOutlet NSTextField *_exposureKeyTextField;

    __weak IBOutlet NSTextField *_tonemapSectionLabel;

    __weak IBOutlet NSTextField *_tonemapOperatorLabel;
    __weak IBOutlet NSPopUpButton *_tonemapOperatorPopUp;
    __weak IBOutlet NSTextField *_tonemapWhitePointLabel;
    __weak IBOutlet NSSlider *_tonemapWhitePointSlider;
    __weak IBOutlet NSTextField *_tonemapWhitePointTextField;
    __weak IBOutlet NSTextField *_tonemapScaleLabel;
    __weak IBOutlet NSSlider *_tonemapEDRScalingWeightSlider;
    __weak IBOutlet NSTextField *_tonemapEDRScalingTextField;

    __weak IBOutlet NSTextField *_edrSectionLabel;

    __weak IBOutlet NSTextField *_maxEDRValueLabel;
    __weak IBOutlet NSTextField *_maxEDRValueTextField;
    __weak IBOutlet NSTextField *_maxEDRReferenceLabel;
    __weak IBOutlet NSTextField *_maxEDRReferenceTextField;
    __weak IBOutlet NSTextField *_maxEDRPotentialLabel;
    __weak IBOutlet NSTextField *_maxEDRPotentialTextField;

    __weak IBOutlet NSTextField *_gpuSectionLabel;

    __weak IBOutlet NSTextField *_gpuNameLabel;
    __weak IBOutlet NSTextField *_gpuNameTextField;
    __weak IBOutlet NSTextField *_avgGPUTimeLabel;
    __weak IBOutlet NSTextField *_avgGPUTimeTextField;
    __weak IBOutlet NSTextField *_resolutionScaleLabel;
    __weak IBOutlet NSSlider *_resolutionScaleSlider;

    __weak IBOutlet NSTextField *_cameraSectionLabel;

    __weak IBOutlet NSTextField *_cameraAnimationLabel;
    __weak IBOutlet NSButton *_cameraAnimationCheckBox;
    __weak IBOutlet NSTextField *_cameraFrameIndexLabel;
    __weak IBOutlet NSSlider *_cameraFrameIndexSlider;
    __weak IBOutlet NSTextField *_cameraFrameIndexTextField;
    __weak IBOutlet NSStepper *_cameraFrameIndexStepper;

    __weak IBOutlet NSBox *_UIContainer;

    NSNumberFormatter * _numberFormatter;
}

#pragma mark -
#pragma mark Initialization

// --
- (void)viewDidLoad
{
    [super viewDidLoad];

    _numberFormatter = [NSNumberFormatter new];
    _numberFormatter.usesSignificantDigits = YES;
    _numberFormatter.maximumSignificantDigits = 3ul;

    _view = (MTKView *)self.view;

    // Register for display change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDisplayChange)
                                                 name:NSWindowDidChangeScreenNotification
                                               object:nil];

    // Register for EDR headroom change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onEDRUpdate)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];

    // Register callback for GPU plug/unplug events
    id <NSObject> metalDeviceObserver = nil;
    MTLCopyAllDevicesWithObserver(&metalDeviceObserver, ^(id<MTLDevice> device, MTLDeviceNotificationName name)
    {
        [self onGPUPlugEventWithDevice:device andNotification:name];
    });

    // This method call will assign the MTLDevice associated with the current screen to the MTKView
    [self onDisplayChange];

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view
                                           cameraStepCount:kDefaultCameraStepCount
                                      resolutionScale:kDefaultResolutionScale];

    NSAssert(_renderer, @"Renderer failed initialization");

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;

    AAPLViewControllerMac * __weak weakSelf = self;
    _renderer.frameIndexBlock = ^(NSUInteger index)
    {
        AAPLViewControllerMac * strongSelf = weakSelf;

        strongSelf->_cameraFrameIndexSlider.intValue = (int)index;
        strongSelf->_cameraFrameIndexTextField.intValue = (int)index;
        strongSelf->_cameraFrameIndexStepper.intValue = (int)index;
    };

    _renderer.averageGPUTimeBlock = ^(CFTimeInterval avgTime)
    {
        AAPLViewControllerMac * strongSelf = weakSelf;

        // Scale from seconds to milliseconds
        NSNumber * num = [NSNumber numberWithFloat:avgTime * 1000.f];
        strongSelf->_avgGPUTimeTextField.stringValue = [strongSelf->_numberFormatter stringFromNumber:num];
    };

    [self configureUIElements];
    [self handleExposureTypeUpdate:kDefaultExposureControlType];
    [self handleTonemapTypeUpdate:kDefaultTonemapOperatorType];

    [self handlePostProcessingToggle:YES];
    _postProcessingEnabled.state = NSControlStateValueOn;
}

#pragma mark -
#pragma mark Helpers

// --
- (void)onDisplayChange
{
    // Migrate to new MTLDevice if needed
    NSNumber* NSScreenNumber = _view.window.screen.deviceDescription[@"NSScreenNumber"];

    id<MTLDevice> newDevice = CGDirectDisplayCopyCurrentMetalDevice([NSScreenNumber unsignedIntValue]);
    if (_view.device != newDevice)
    {
        _view.device = newDevice;
        [_renderer updateWithDevice:newDevice andView:_view];

        _gpuNameTextField.stringValue = newDevice.name;
    }

    // Update to match display colorspace to disable color space transformations
    CAMetalLayer * camLayer = (CAMetalLayer *)_view.layer;
    camLayer.colorspace = nil;
    camLayer.wantsExtendedDynamicRangeContent = YES;

    [self onEDRUpdate];
}

// --
- (void)onGPUPlugEventWithDevice:(id<MTLDevice>)device andNotification:(MTLDeviceNotificationName)notifier
{
    [self onDisplayChange];
}

// --
- (void)onEDRUpdate
{
    // Query and set new values.
    _renderer.maximumEDRValue = _view.window.screen.maximumExtendedDynamicRangeColorComponentValue;
    _renderer.maximumEDRValue = MAX(_renderer.maximumEDRValue, 1.0);

    _maxEDRValueTextField.floatValue = _view.window.screen.maximumExtendedDynamicRangeColorComponentValue;

    if (@available(macOS 10.15, *))
    {
        _renderer.maximumEDRPotentialValue = _view.window.screen.maximumPotentialExtendedDynamicRangeColorComponentValue;
        _maxEDRPotentialTextField.floatValue = _view.window.screen.maximumPotentialExtendedDynamicRangeColorComponentValue;

        _renderer.maximumEDRReferenceValue = _view.window.screen.maximumReferenceExtendedDynamicRangeColorComponentValue;
        _maxEDRReferenceTextField.floatValue = _view.window.screen.maximumReferenceExtendedDynamicRangeColorComponentValue;
    }
    else
    {
        _renderer.maximumEDRPotentialValue = 1.f;
        _renderer.maximumEDRReferenceValue = 1.f;

        _maxEDRReferenceLabel.enabled = NO;
        _maxEDRReferenceTextField.enabled = NO;

        _maxEDRPotentialLabel.enabled = NO;
        _maxEDRPotentialTextField.enabled = NO;
    }
}

- (void)handlePostProcessingToggle:(BOOL)enabled
{
    _renderer.postProcessingEnabled = enabled;

    _bloomIntensitySlider.enabled = enabled;
    _bloomIntensityTextField.enabled = enabled;
    _bloomThresholdSlider.enabled = enabled;
    _bloomThresholdTextField.enabled = enabled;
    _bloomRangeTextField.enabled = enabled;
    _bloomRangeSlider.enabled = enabled;
    _exposureTypePopUp.enabled = enabled;
    _tonemapOperatorPopUp.enabled = enabled;
    _tonemapWhitePointSlider.enabled = enabled;
    _tonemapWhitePointTextField.enabled = enabled;
    _tonemapEDRScalingWeightSlider.enabled = enabled;
    _tonemapEDRScalingTextField.enabled = enabled;

    if(enabled)
    {
        _bloomSectionLabel.textColor = NSColor.labelColor;
        _bloomIntensityLabel.textColor = NSColor.labelColor;
        _bloomThresholdLabel.textColor = NSColor.labelColor;
        _bloomRangeLabel.textColor = NSColor.labelColor;
        _exposureSectionLabel.textColor = NSColor.labelColor;
        _exposureTypeLabel.textColor = NSColor.labelColor;
        _manualExposureLabel.textColor = NSColor.labelColor;
        _tonemapSectionLabel.textColor = NSColor.labelColor;
        _tonemapOperatorLabel.textColor = NSColor.labelColor;
        _tonemapWhitePointLabel.textColor = NSColor.labelColor;
        _tonemapScaleLabel.textColor = NSColor.labelColor;

        [self handleExposureTypeUpdate:(ExposureControlType)_exposureTypePopUp.indexOfSelectedItem];
    }
    else
    {
        _bloomSectionLabel.textColor = NSColor.disabledControlTextColor;
        _bloomIntensityLabel.textColor = NSColor.disabledControlTextColor;
        _bloomThresholdLabel.textColor = NSColor.disabledControlTextColor;
        _bloomRangeLabel.textColor = NSColor.disabledControlTextColor;
        _exposureSectionLabel.textColor = NSColor.disabledControlTextColor;
        _exposureTypeLabel.textColor = NSColor.disabledControlTextColor;
        _exposureKeyLabel.textColor = NSColor.disabledControlTextColor;
        _manualExposureLabel.textColor = NSColor.disabledControlTextColor;
        _tonemapSectionLabel.textColor = NSColor.disabledControlTextColor;
        _tonemapOperatorLabel.textColor = NSColor.disabledControlTextColor;
        _tonemapWhitePointLabel.textColor = NSColor.disabledControlTextColor;
        _tonemapScaleLabel.textColor = NSColor.disabledControlTextColor;

        _exposureKeySlider.enabled = NO;
        _exposureKeyTextField.enabled = NO;
        _manualExposureSlider.enabled = NO;
        _manualExposureTextField.enabled = NO;
    }
}

// --
- (void)configureUIElements
{
    // Bloom
    _bloomSectionLabel.stringValue = [kBloomSectionLabel copy];

    // Intensity
    _bloomIntensityLabel.stringValue = [kBloomIntensitySliderLabel copy];

    _bloomIntensitySlider.minValue = kBloomIntensityMinimum;
    _bloomIntensitySlider.maxValue = kBloomIntensityMaximum;
    _bloomIntensitySlider.floatValue = kDefaultBloomIntensity;

    _bloomIntensityTextField.floatValue = kDefaultBloomIntensity;
    _renderer.bloomIntensity = kDefaultBloomIntensity;

    // Threshold
    _bloomThresholdLabel.stringValue = [kBloomThresholdSliderLabel copy];

    _bloomThresholdSlider.minValue = kBloomThresholdMinimum;
    _bloomThresholdSlider.maxValue = kBloomThresholdMaximum;
    _bloomThresholdSlider.floatValue = kDefaultBloomThreshold;

    _bloomThresholdTextField.floatValue = kDefaultBloomThreshold;
    _renderer.bloomThreshold = kDefaultBloomThreshold;

    // Range
    _bloomRangeLabel.stringValue = [kBloomRangeSliderLabel copy];

    _bloomRangeSlider.minValue = kBloomRangeMinimum;
    _bloomRangeSlider.maxValue = kBloomRangeMaximum;
    _bloomRangeSlider.floatValue = kDefaultBloomRange;

    _bloomRangeTextField.floatValue = kDefaultBloomRange;
    _renderer.bloomRange = kDefaultBloomRange;

    // Exposure
    _exposureSectionLabel.stringValue = [kExposureSectionLabel copy];

    _exposureTypeLabel.stringValue = [kExposureTypeLabel copy];

    [_exposureTypePopUp removeAllItems];
    [_exposureTypePopUp insertItemWithTitle:[kExposureTypeManualLabel copy] atIndex:kExposureControlTypeManual];
    [_exposureTypePopUp insertItemWithTitle:[kExposureTypeKeyLabel copy] atIndex:kExposureControlTypeKey];
    [_exposureTypePopUp selectItemAtIndex:kDefaultExposureControlType];
    _renderer.exposureType = kDefaultExposureControlType;

    _manualExposureLabel.stringValue = [kExposureTypeManualLabel copy];
    _manualExposureSlider.minValue = kManualExposureMinimum;
    _manualExposureSlider.maxValue = kManualExposureMaximum;
    _manualExposureSlider.floatValue = kDefaultManualExposure;
    _manualExposureTextField.floatValue = kDefaultManualExposure;
    _renderer.manualExposureValue = kDefaultManualExposure;

    _exposureKeyLabel.stringValue = [kExposureTypeKeyLabel copy];

    _exposureKeySlider.minValue = 0;
    _exposureKeySlider.maxValue = kExposureKeyCount - 1;
    _exposureKeySlider.numberOfTickMarks = kExposureKeyCount;
    _exposureKeySlider.intValue = [_exposureKeySlider closestTickMarkValueToValue:(double)kDefaultExposureKeyIndex];

    _exposureKeyTextField.floatValue = kExposureKeys[kDefaultExposureKeyIndex];
    _renderer.exposureKeyIndex = kDefaultExposureKeyIndex;

    _renderer.tonemapEDRScalingWeight = kDefaultTonemapEDRScaleWeight;

    // Tonemapping
    _tonemapSectionLabel.stringValue = [kTonemapSectionLabel copy];

    _tonemapOperatorLabel.stringValue = [kTonemapOperatorLabel copy];

    [_tonemapOperatorPopUp removeAllItems];
    [_tonemapOperatorPopUp insertItemWithTitle:[kTonemapOperatorReinhardLabel copy] atIndex:kTonemapOperatorTypeReinhard];
    [_tonemapOperatorPopUp insertItemWithTitle:[kTonemapOperatorReinhardExLabel copy] atIndex:kTonemapOperatorTypeReinhardEx];
    [_tonemapOperatorPopUp selectItemAtIndex:kDefaultTonemapOperatorType];
    _renderer.tonemapType = kDefaultTonemapOperatorType;

    _tonemapWhitePointLabel.stringValue = [kTonemapWhitePointLabel copy];
    _tonemapWhitePointSlider.minValue = kTonemapWhitePointMinimum;
    _tonemapWhitePointSlider.maxValue = kTonemapWhitePointMaximum;
    _tonemapWhitePointSlider.floatValue = kDefaultTonemapWhitePoint;
    _tonemapWhitePointTextField.floatValue = kDefaultTonemapWhitePoint;
    _tonemapEDRScalingWeightSlider.minValue = 0;
    _tonemapEDRScalingWeightSlider.maxValue = 1.0;
    _tonemapEDRScalingTextField.floatValue = kDefaultTonemapEDRScaleWeight;
    _tonemapEDRScalingWeightSlider.floatValue = kDefaultTonemapEDRScaleWeight;
    _renderer.tonemapWhitepoint = kDefaultTonemapWhitePoint;

    // Extended Dynamic Range
    _edrSectionLabel.stringValue = [kEDRSectionLabel copy];

    _maxEDRValueLabel.stringValue = [kMaxEDRValueLabel copy];
    _maxEDRReferenceLabel.stringValue = [kMaxEDRReferenceLabel copy];
    _maxEDRPotentialLabel.stringValue = [kMaxEDRPotentialLabel copy];

    // GPU
    _gpuSectionLabel.stringValue = [kGPUSectionLabel copy];

    _gpuNameLabel.stringValue = [kGPUNameLabel copy];
    _avgGPUTimeLabel.stringValue = [kGPUTimeLabel copy];

    _resolutionScaleLabel.stringValue = [kResolutionScaleLabel copy];
    _resolutionScaleSlider.minValue = _renderer.minimumResolutionScale;
    _resolutionScaleSlider.maxValue = _renderer.maximumResolutionScale;

    // Let the renderer clamp this value before assigning to slider
    _renderer.resolutionScale = kDefaultResolutionScale;
    _resolutionScaleSlider.floatValue = _renderer.resolutionScale;

    _resolutionScaleSlider.continuous = NO;

    // Camera
    _cameraSectionLabel.stringValue = [kCameraSectionLabel copy];

    _cameraAnimationLabel.stringValue = [kCameraAnimationLabel copy];
    _cameraAnimationCheckBox.state = (kDefaultIsCameraAnimationEnabled == YES) ? NSControlStateValueOn : NSControlStateValueOff;
    _renderer.isCameraAnimating = kDefaultIsCameraAnimationEnabled;

    _cameraFrameIndexLabel.stringValue = [kCameraFrameIDLabel copy];
    _cameraFrameIndexSlider.intValue = kDefaultCameraFrameIndex;
    _cameraFrameIndexSlider.maxValue = _renderer.cameraAnimationStepCount - 1;
    _cameraFrameIndexTextField.intValue = kDefaultCameraFrameIndex;
    _cameraFrameIndexTextField.highlighted = NO;
    _cameraFrameIndexStepper.autorepeat = YES;
    _cameraFrameIndexStepper.valueWraps = YES;
    _cameraFrameIndexStepper.minValue = 0;
    _cameraFrameIndexStepper.maxValue = _renderer.cameraAnimationStepCount - 1;
    _cameraFrameIndexStepper.intValue = kDefaultCameraFrameIndex;
    _renderer.cameraAnimationFrameIndex = kDefaultCameraFrameIndex;

    _UIContainer.contentView.wantsLayer = YES;
}

// --
- (void)handleExposureTypeUpdate:(ExposureControlType) type
{
    switch(type)
    {
        case kExposureControlTypeManual:
        {
            _manualExposureLabel.enabled = true;
            _manualExposureLabel.textColor = NSColor.labelColor;
            _manualExposureSlider.enabled = true;
            _manualExposureTextField.enabled = true;

            _exposureKeyLabel.enabled = false;
            _exposureKeyLabel.textColor = NSColor.disabledControlTextColor;
            _exposureKeySlider.enabled = false;
            _exposureKeyTextField.enabled = false;

            _renderer.exposureType = kExposureControlTypeManual;
            _manualExposureSlider.floatValue = _renderer.manualExposureValue;
            _manualExposureTextField.floatValue = _renderer.manualExposureValue;
        }
        return;

        case kExposureControlTypeKey:
        {
            _manualExposureLabel.enabled = false;
            _manualExposureLabel.textColor = NSColor.disabledControlTextColor;
            _manualExposureSlider.enabled = false;
            _manualExposureTextField.enabled = false;

            _exposureKeyLabel.enabled = true;
            _exposureKeyLabel.textColor = NSColor.labelColor;
            _exposureKeySlider.enabled = true;
            _exposureKeyTextField.enabled = true;

            _renderer.exposureType = kExposureControlTypeKey;
            _renderer.exposureKeyIndex = _exposureKeySlider.intValue;
        }
        return;

        default: break;
    };
}

// --
- (void)handleTonemapTypeUpdate:(TonemapOperatorType)type
{
    switch (type)
   {
       case kTonemapOperatorTypeReinhard:
       {
           _tonemapWhitePointLabel.enabled = false;
           _tonemapWhitePointLabel.textColor = NSColor.disabledControlTextColor;
           _tonemapWhitePointSlider.enabled = false;
           _tonemapWhitePointTextField.enabled = false;

           _renderer.tonemapType = kTonemapOperatorTypeReinhard;

           break;
       }

       case kTonemapOperatorTypeReinhardEx:
       {
           _tonemapWhitePointLabel.enabled = true;
           _tonemapWhitePointLabel.textColor = NSColor.labelColor;
           _tonemapWhitePointSlider.enabled = true;
           _tonemapWhitePointTextField.enabled = true;

           _renderer.tonemapType = kTonemapOperatorTypeReinhardEx;

           break;
       }

       default: break;
   }
}

#pragma mark -
#pragma mark Properties

// --
- (void)setIsUIDisplayed:(BOOL)isUIDisplayed
{
    static const CGFloat kAnimationDuration = .5f;
    if (isUIDisplayed)
    {
        __weak AAPLViewControllerMac * weakSelf = self;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
        {
            context.duration = kAnimationDuration;
            AAPLViewControllerMac * strongSelf = weakSelf;
            strongSelf->_UIContainer.contentView.superview.animator.alphaValue = 1.f;
            strongSelf->_UIContainer.contentView.superview.hidden = NO;
        }
        completionHandler:^
        {
            AAPLViewControllerMac * strongSelf = weakSelf;
            strongSelf->_UIContainer.contentView.superview.alphaValue = 1.f;
        }];
    }
    else
    {
        __weak AAPLViewControllerMac * weakSelf = self;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
        {
            context.duration = kAnimationDuration;
            AAPLViewControllerMac * strongSelf = weakSelf;
            strongSelf->_UIContainer.contentView.superview.animator.alphaValue = 0.f;
        }
        completionHandler:^
        {
            AAPLViewControllerMac * strongSelf = weakSelf;
            strongSelf->_UIContainer.contentView.superview.hidden = YES;
            strongSelf->_UIContainer.contentView.superview.alphaValue = 0.f;
        }];
    }
}

#pragma mark -
#pragma mark Callbacks
// Post Processing
- (IBAction)postProcessingEnabledCallback:(NSSwitch *)sender
{
    [self handlePostProcessingToggle:(sender.state == NSControlStateValueOn)];
    _postProcessingEnabled.state = sender.state;
}

// Bloom
- (IBAction)bloomIntensitySliderCallback:(NSSlider *)sender
{
    _renderer.bloomIntensity = sender.floatValue;
    _bloomIntensityTextField.floatValue = sender.floatValue;
}

- (IBAction)bloomThresholdSliderCallback:(NSSlider *)sender
{
    _renderer.bloomThreshold = sender.floatValue;
    _bloomThresholdTextField.floatValue = sender.floatValue;
}

- (IBAction)bloomRangeSliderCallback:(NSSlider *)sender
{
    _renderer.bloomRange = sender.floatValue;
    _bloomRangeTextField.floatValue = sender.floatValue;
}

// Exposure

- (IBAction)exposureTypePopUpCallback:(NSPopUpButton *)sender
{
    [self handleExposureTypeUpdate:(ExposureControlType)sender.indexOfSelectedItem];
}

- (IBAction)manualExposureSliderCallback:(NSSlider *)sender
{
    _renderer.manualExposureValue = sender.floatValue;
    _manualExposureTextField.floatValue = sender.floatValue;
}

- (IBAction)exposureKeySliderCallback:(NSSlider *)sender
{
    _renderer.exposureKeyIndex = sender.intValue;
    _exposureKeyTextField.floatValue = kExposureKeys[sender.intValue];
}

// Tonemapping

- (IBAction)tonemapOperatorPopUpCallback:(NSPopUpButton *)sender
{
    [self handleTonemapTypeUpdate:(TonemapOperatorType)sender.indexOfSelectedItem];
}

- (IBAction)tonemapWhitePointSliderCallback:(NSSlider *)sender
{
    _tonemapWhitePointTextField.floatValue = sender.floatValue;
    _renderer.tonemapWhitepoint = sender.floatValue;
}
- (IBAction)tonemapEDRScalingWeightSliderCallback:(NSSlider *)sender
{
    _tonemapEDRScalingTextField.floatValue = sender.floatValue;
    _renderer.tonemapEDRScalingWeight = sender.floatValue;
}


// Resolution Scale
- (IBAction)resolutionScaleSliderCallback:(NSSlider *)sender
{
    _renderer.resolutionScale = sender.floatValue;
}

// Camera

- (IBAction)cameraIsAnimatingButtonCallback:(NSButton *)sender
{
    _renderer.isCameraAnimating = (sender.state == NSControlStateValueOn);
}

- (void)handleFrameIndexUpdateWithControl:(NSControl *)control rangeClamped:(BOOL)isRangeClamped
{
    _renderer.isCameraAnimating = false;
    _cameraAnimationCheckBox.state = NSControlStateValueOff;

    if (isRangeClamped)
    {
        int32_t v = CLAMP(0, (int)_renderer.cameraAnimationStepCount - 1, control.intValue);

        _renderer.cameraAnimationFrameIndex = v;
        _cameraFrameIndexTextField.intValue = v;
        _cameraFrameIndexStepper.intValue = v;
    }
    else
    {
        _renderer.cameraAnimationFrameIndex = control.intValue;
        _cameraFrameIndexTextField.intValue = control.intValue;
        _cameraFrameIndexStepper.intValue = control.intValue;
    }
}

- (IBAction)cameraFrameIndexSliderCallback:(NSSlider *)sender
{
    [self handleFrameIndexUpdateWithControl:sender rangeClamped:NO];
}

- (IBAction)cameraFrameIndexTextFieldCallback:(NSTextField *)sender
{
    [self handleFrameIndexUpdateWithControl:sender rangeClamped:YES];
}

- (IBAction)cameraFrameIndexStepperCallback:(NSStepper *)sender
{
    [self handleFrameIndexUpdateWithControl:sender rangeClamped:NO];
}

@end
