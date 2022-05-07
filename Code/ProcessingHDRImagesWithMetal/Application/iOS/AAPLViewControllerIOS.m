/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the iOS view controller.
*/

#import <MetalKit/MetalKit.h>
#import "AAPLViewControllerIOS.h"
#import "AAPLRenderer.h"
#import "UIOptionEnums.h"
#import "AAPLMathUtilities.h"
#import "AAPLUtility.hpp"
#import "UIDefaults.h"

typedef enum _UISegmentIndexType
{
    kUISegmentIndexTypeBloom = 0,
    kUISegmentIndexTypeExposure,
    kUISegmentIndexTypeTonemapping,
    kUISegmentIndexTypeUtil
} UISegmentIndexType;

static const UISegmentIndexType kDefaultUISegmentIndexType = kUISegmentIndexTypeTonemapping;

@implementation AAPLViewControllerIOS
{
    MTKView *_view;
    AAPLRenderer *_renderer;
    NSNumberFormatter * _numberFormatter;

    // For handling panning gestures - animate forward and backward
    IBOutlet UIPanGestureRecognizer *_panGestureRecognizer;
    IBOutlet UITapGestureRecognizer *_tapGestureRecognizer;

    __weak IBOutlet UIView *_mainUIView;

    // On screen UI controls
    __weak IBOutlet UIButton *_settingsOpenButton;
    __weak IBOutlet UILabel *_settingsMenuLabel;
    __weak IBOutlet UIButton *_settingsCloseButton;

    UISegmentIndexType _currentUISegmentIndex;
    __weak IBOutlet UISegmentedControl *_uiSelectionSegmentView;

    // Bloom
    __weak IBOutlet UIView *_bloomUIView;
    __weak IBOutlet UILabel *_bloomThresholdLabel;
    __weak IBOutlet UISlider *_bloomThresholdSlider;
    __weak IBOutlet UILabel *_bloomIntensityLabel;
    __weak IBOutlet UISlider *_bloomIntensitySlider;
    __weak IBOutlet UILabel *_bloomRangeLabel;
    __weak IBOutlet UISlider *_bloomRangeSlider;

    // Exposure and Tonemapping
    __weak IBOutlet UIView *_etUIView;
    __weak IBOutlet UILabel *_etTypeLabel;
    __weak IBOutlet UIPickerView *_etTypePicker;

    __weak IBOutlet UIView *_exposureView;
    __weak IBOutlet UILabel *_exposureLabel;
    __weak IBOutlet UISlider *_exposureSlider;

    __weak IBOutlet UIView *_reinhardExTonemapView;
    __weak IBOutlet UILabel *_reinhardExTonemapWhitePointLabel;
    __weak IBOutlet UISlider *_reinhardExTonemapWhitePointSlider;

    // Util
    __weak IBOutlet UIView *_utilUIView;
    __weak IBOutlet UILabel *_frameIndexLabel;
    __weak IBOutlet UITextField *_frameIndexTextField;
    __weak IBOutlet UILabel *_avgTimeLabel;
    __weak IBOutlet UITextField *_avgTimeTextField;
    __weak IBOutlet UILabel *_resolutionScaleLabel;
    __weak IBOutlet UISlider *_resolutionScaleSlider;
}

#pragma mark Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

    NSAssert(_view.device, @"Metal is not supported on this device");

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view cameraStepCount:kDefaultCameraStepCount resolutionScale:kDefaultResolutionScale];

    NSAssert(_renderer, @"Renderer failed initialization");

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;

    _numberFormatter = [NSNumberFormatter new];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

    __weak AAPLViewControllerIOS * weakSelf = self;
    _renderer.frameIndexBlock = ^(NSUInteger index)
    {
        AAPLViewControllerIOS * strongSelf = weakSelf;
        strongSelf->_frameIndexTextField.text = [NSString stringWithFormat:@"%d", (uint32_t)index];
    };

    _renderer.averageGPUTimeBlock = ^(CFTimeInterval avgTime)
    {
        AAPLViewControllerIOS * strongSelf = weakSelf;
        NSNumber * num = [NSNumber numberWithFloat:avgTime * 1000.f];
        strongSelf->_avgTimeTextField.text = [strongSelf->_numberFormatter stringFromNumber:num];
    };

    _renderer.isCameraAnimating = kDefaultIsCameraAnimationEnabled;
    _renderer.cameraAnimationFrameIndex = kDefaultCameraFrameIndex;

    _etTypePicker.dataSource = self;
    _etTypePicker.delegate = self;

    [self configureUIElements];

    [self handleExposureTypeUpdate:kDefaultExposureControlType];
    [self handleTonemapTypeUpdate:kDefaultTonemapOperatorType];

    _uiSelectionSegmentView.selectedSegmentIndex = kDefaultUISegmentIndexType;
    [self handleUISegmentIndexUpdate:kDefaultUISegmentIndexType];
}

#pragma mark Helpers

// Handles gesture input to ignore touches interacting with our parameter tweak UI
- (bool)isContainedInSceneUIView:(UIGestureRecognizer*)recognizer
{
    CGPoint test = [recognizer locationInView:_mainUIView];

    if (test.x < 0.f || test.x > _mainUIView.bounds.size.width ||
        test.y < 0.f || test.y > _mainUIView.bounds.size.height)
    {
        return NO;
    }

    return YES;
}

// --
- (void)handleExposureTypeUpdate:(ExposureControlType)type
{
    _renderer.exposureType = type;
    [self handleUISegmentIndexUpdate:_currentUISegmentIndex];
}

// --
- (void)handleTonemapTypeUpdate:(TonemapOperatorType)type
{
    _renderer.tonemapType = type;
    [self handleUISegmentIndexUpdate:_currentUISegmentIndex];
}

// --
- (void)handleUISegmentIndexUpdate:(NSInteger)segmentIndex
{
    switch (segmentIndex)
    {
        case kUISegmentIndexTypeBloom:
        {
            _currentUISegmentIndex = kUISegmentIndexTypeBloom;

            _bloomUIView.hidden = NO;

            _etUIView.hidden = YES;
            _utilUIView.hidden = YES;

            break;
        }

        case kUISegmentIndexTypeExposure:
        {
            _currentUISegmentIndex = kUISegmentIndexTypeExposure;

            _etUIView.hidden = NO;
            _exposureView.hidden = NO;

            _bloomUIView.hidden = YES;
            _utilUIView.hidden = YES;
            _reinhardExTonemapView.hidden = YES;

            _etTypeLabel.text = [kExposureTypeLabel copy];

            [_etTypePicker reloadAllComponents];
            [_etTypePicker selectRow:_renderer.exposureType inComponent:0 animated:NO];

            switch (_renderer.exposureType)
            {
                case kExposureControlTypeManual:
                {
                    _exposureLabel.text = [kExposureTypeManualLabel copy];

                    _exposureSlider.minimumValue = kManualExposureMinimum;
                    _exposureSlider.maximumValue = kManualExposureMaximum;
                    _exposureSlider.value = _renderer.manualExposureValue;
                    _exposureSlider.continuous = YES;

                    break;
                }

                case kExposureControlTypeKey:
                {
                    _exposureLabel.text = [kExposureTypeKeyLabel copy];

                    _exposureSlider.minimumValue = 0.f;
                    _exposureSlider.maximumValue = (float)kExposureKeyCount - 1;
                    _exposureSlider.value = (float)_renderer.exposureKeyIndex;
                    _exposureSlider.continuous = NO;

                    break;
                }

                default: break;
            }
            break;
        }

        case kUISegmentIndexTypeTonemapping:
        {
            _currentUISegmentIndex = kUISegmentIndexTypeTonemapping;

            _etUIView.hidden = NO;

            _bloomUIView.hidden = YES;
            _utilUIView.hidden = YES;
            _exposureView.hidden = YES;

            _etTypeLabel.text = [kTonemapOperatorLabel copy];

            [_etTypePicker reloadAllComponents];
            [_etTypePicker selectRow:_renderer.tonemapType inComponent:0 animated:NO];

            switch (_renderer.tonemapType)
            {
                case kTonemapOperatorTypeReinhard:
                {
                    _reinhardExTonemapView.hidden = YES;
                    break;
                }

                case kTonemapOperatorTypeReinhardEx:
                {
                    _reinhardExTonemapView.hidden = NO;
                    break;
                }

                default: break;
            }
            break;
        }

        case kUISegmentIndexTypeUtil:
        {
            _currentUISegmentIndex = kUISegmentIndexTypeUtil;
            _utilUIView.hidden = NO;
            _bloomUIView.hidden = YES;
            _etUIView.hidden = YES;

            break;
        }

        default: break;
    }
}

#pragma mark -
#pragma mark Overrides

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [_renderer updateWithSize:size];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

// Signal desire to hide the home indicator on supported devices
- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

#pragma mark -
#pragma mark Configure UI

- (void)configureUIElements
{
    // Settings menu config
    _settingsOpenButton.layer.cornerRadius = 5.f;
    _settingsOpenButton.hidden = NO;
    _mainUIView.hidden = YES;

    // Bloom
    [_uiSelectionSegmentView setTitle:[kBloomSectionLabel copy] forSegmentAtIndex:kUISegmentIndexTypeBloom];

    _bloomIntensityLabel.text = [kBloomIntensitySliderLabel copy];
    _bloomIntensitySlider.minimumValue = kBloomIntensityMinimum;
    _bloomIntensitySlider.maximumValue = kBloomIntensityMaximum;
    _bloomIntensitySlider.value = kDefaultBloomIntensity;
    _bloomIntensitySlider.continuous = YES;

    _renderer.bloomIntensity = kDefaultBloomIntensity;

    _bloomThresholdLabel.text = [kBloomThresholdSliderLabel copy];
    _bloomThresholdSlider.minimumValue = kBloomThresholdMinimum;
    _bloomThresholdSlider.maximumValue = kBloomThresholdMaximum;
    _bloomThresholdSlider.value = kDefaultBloomThreshold;
    _bloomThresholdSlider.continuous = YES;

    _renderer.bloomThreshold = kDefaultBloomThreshold;

    _bloomRangeLabel.text = [kBloomRangeSliderLabel copy];
    _bloomRangeSlider.minimumValue = kBloomRangeMinimum;
    _bloomRangeSlider.maximumValue = kBloomRangeMaximum;
    _bloomRangeSlider.value = kDefaultBloomRange;
    _bloomRangeSlider.continuous = YES;

    _renderer.bloomRange = kDefaultBloomRange;

    // Exposure
    [_uiSelectionSegmentView setTitle:[kExposureSectionLabel copy] forSegmentAtIndex:kUISegmentIndexTypeExposure];

    _renderer.exposureType = kDefaultExposureControlType;
    _renderer.manualExposureValue = kDefaultManualExposure;
    _renderer.exposureKeyIndex = kDefaultExposureKeyIndex;

    // Tonemapping
    [_uiSelectionSegmentView setTitle:[kTonemapSectionLabel copy] forSegmentAtIndex:kUISegmentIndexTypeTonemapping];

    _renderer.tonemapType = kDefaultTonemapOperatorType;

    //  White point
    _reinhardExTonemapWhitePointSlider.minimumValue = kTonemapWhitePointMinimum;
    _reinhardExTonemapWhitePointSlider.maximumValue = kTonemapWhitePointMaximum;
    _reinhardExTonemapWhitePointSlider.value = kDefaultTonemapWhitePoint;
    _reinhardExTonemapWhitePointSlider.continuous = YES;

    _renderer.tonemapWhitepoint = kDefaultTonemapWhitePoint;

    // Util
    [_uiSelectionSegmentView setTitle:[kUtilSectionLabel copy] forSegmentAtIndex:kUISegmentIndexTypeUtil];

    _frameIndexLabel.text = [kCameraFrameIDLabel copy];
    _frameIndexTextField.text = [NSString stringWithFormat:@"%d", kDefaultCameraFrameIndex];

    _avgTimeLabel.text = [kGPUTimeLabel copy];
    _avgTimeTextField.text = @"0.00";

    _resolutionScaleLabel.text = [kResolutionScaleLabel copy];
    _resolutionScaleSlider.minimumValue = _renderer.minimumResolutionScale;
    _resolutionScaleSlider.maximumValue = _renderer.maximumResolutionScale;

    _renderer.resolutionScale = .8f;

    // Let the renderer clamp to meaningful range
    _resolutionScaleSlider.value = _renderer.resolutionScale;
    _resolutionScaleSlider.continuous = NO;

    // Gesture recognizers
    [self.view addGestureRecognizer:_panGestureRecognizer];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
}

#pragma mark -
#pragma mark UI Callbacks

#pragma mark Gestures

// --
- (IBAction)panGestureCallback:(UIPanGestureRecognizer*)sender
{
    // Let user pan through entire view if app UI isn't visible
    if (_mainUIView.hidden == NO && [self isContainedInSceneUIView:sender])
    {
        return;
    }

    _renderer.isCameraAnimating = NO;

    CGFloat Tx = [sender translationInView:self.view].x;

    Tx = (Tx > 100.f) ? 1.f : Tx / 100.f;

    const NSUInteger kPanScale = (NSUInteger)(3.f * fabs(Tx));

    if (Tx < 0)
    {
        _renderer.cameraAnimationFrameIndex = (_renderer.cameraAnimationFrameIndex + kPanScale)  % _renderer.cameraAnimationStepCount;
    }
    else
    {
        if (_renderer.cameraAnimationFrameIndex <= kPanScale)
            _renderer.cameraAnimationFrameIndex = _renderer.cameraAnimationStepCount - 1;
        else _renderer.cameraAnimationFrameIndex -= kPanScale;
    }
}

// --
- (IBAction)tapGestureCallback:(UITapGestureRecognizer*)sender
{
    // Let user tap anywhere if app UI isn't visible
    if (_mainUIView.hidden == NO &&[self isContainedInSceneUIView:sender])
    {
        return;
    }

    _renderer.isCameraAnimating = !_renderer.isCameraAnimating;
}

#pragma mark Settings Menu Toggle

// --
- (IBAction)settingsOpenButtonCallback:(UIButton *)sender
{
    _mainUIView.hidden = NO;
    _settingsOpenButton.hidden = YES;
}

// --
- (IBAction)settingsCloseButtonCallback:(UIButton *)sender
{
    _mainUIView.hidden = YES;
    _settingsOpenButton.hidden = NO;
}

#pragma mark Segmented Control

// --
- (IBAction)uiSegmentedControlCallback:(UISegmentedControl*)sender
{
    [self handleUISegmentIndexUpdate:sender.selectedSegmentIndex];
}

#pragma mark Bloom

// --
- (IBAction)bloomThresholdSliderCallback:(UISlider*)sender
{
    _renderer.bloomThreshold = sender.value;
}

// --
- (IBAction)bloomIntensitySliderCallback:(UISlider*)sender
{
    _renderer.bloomIntensity = sender.value;
}

// --
- (IBAction)bloomRangeSliderCallback:(UISlider*)sender
{
    _renderer.bloomRange = sender.value;
}

#pragma mark UIPicker: Data Source and Delegate

// UIPickerDataSource

// --
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1l;
}

// --
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (_currentUISegmentIndex)
    {
        case kUISegmentIndexTypeBloom: return 0l;
        case kUISegmentIndexTypeExposure: return kExposureControlTypeCount;
        case kUISegmentIndexTypeTonemapping: return kTonemapOperatorTypeCount;
        case kUISegmentIndexTypeUtil: return 0l;
        default: break;
    }

    return 0l;
}

// UIPickerDelegate

// --
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (_currentUISegmentIndex)
    {
        case kUISegmentIndexTypeBloom: return @"";
        case kUISegmentIndexTypeExposure: return string_for_exposure_control_type((uint32_t)row);
        case kUISegmentIndexTypeTonemapping: return string_for_tonemap_operator_type((uint32_t)row);
        case kUISegmentIndexTypeUtil: return @"";
        default: break;
    }

    return @"";
}

// --
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    const static TonemapOperatorType operatorTypes[] = {kTonemapOperatorTypeReinhard, kTonemapOperatorTypeReinhardEx};
    const static ExposureControlType exposureTypes[] = {kExposureControlTypeManual, kExposureControlTypeKey};

    switch (_currentUISegmentIndex)
    {
        case kUISegmentIndexTypeBloom: return;
        case kUISegmentIndexTypeExposure: [self handleExposureTypeUpdate:exposureTypes[row]]; return;
        case kUISegmentIndexTypeTonemapping: [self handleTonemapTypeUpdate:operatorTypes[row]]; return;
        case kUISegmentIndexTypeUtil: return;
    }
}

#pragma mark Exposure

// --
- (IBAction)exposureSliderCallback:(UISlider *)sender
{
    switch (_renderer.exposureType)
    {
        case kExposureControlTypeManual:
        {
            _renderer.manualExposureValue = sender.value;
            break;
        }

        case kExposureControlTypeKey:
        {
            _exposureSlider.value = roundf(sender.value);
            _renderer.exposureKeyIndex = (NSUInteger)_exposureSlider.value;
            break;
        }

        default: break;
    }
}

#pragma mark Tonemapping

// --
- (IBAction)appleTonemapWhitePointSliderCallback:(UISlider *)sender
{
    _renderer.tonemapWhitepoint = sender.value;
}

// --
- (IBAction)reinhardExWhitepointSliderCallback:(UISlider *)sender
{
    _renderer.tonemapWhitepoint = sender.value;
}

#pragma mark Util

// --
- (IBAction)frameIndexTextFieldCallback:(UITextField *)sender
{
    NSNumber * number = [_numberFormatter numberFromString:sender.text];

    if (number)
    {
        _renderer.isCameraAnimating = NO;
        NSUInteger value = [number unsignedIntegerValue];
        _renderer.cameraAnimationFrameIndex = value >= _renderer.cameraAnimationStepCount ? _renderer.cameraAnimationStepCount - 1 : value;
    }
    else
    {
        sender.text = [NSString stringWithFormat:@"%lx", _renderer.cameraAnimationFrameIndex];
    }
}

// --
- (IBAction)resolutionScaleSliderCallback:(UISlider *)sender
{
    _renderer.resolutionScale = sender.value;
}

@end
