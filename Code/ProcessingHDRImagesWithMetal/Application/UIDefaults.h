/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for default UI settings.
*/

#ifndef UIDefaults_h
#define UIDefaults_h

#import <Foundation/Foundation.h>
#import "UIOptionEnums.h"

// Functionally our string table for labels in the demo
static const NSString* kBloomSectionLabel              = @"Bloom";
static const NSString* kBloomIntensitySliderLabel      = @"Intensity";
static const NSString* kBloomThresholdSliderLabel      = @"Threshold";
static const NSString* kBloomRangeSliderLabel          = @"Range";

static const NSString* kExposureSectionLabel           = @"Exposure";
static const NSString* kExposureTypeLabel              = @"Type";
static const NSString* kExposureTypeManualLabel        = @"Manual";
static const NSString* kExposureTypeKeyLabel           = @"Key";

static const NSString* kTonemapSectionLabel            = @"Tonemap";
static const NSString* kTonemapOperatorLabel           = @"Operator";
static const NSString* kTonemapOperatorReinhardLabel   = @"Reinhard";
static const NSString* kTonemapOperatorReinhardExLabel = @"ReinhardEx";
static const NSString* kTonemapWhitePointLabel         = @"W. Point";

static const NSString* kEDRSectionLabel                = @"Extended Dynamic Range";
static const NSString* kMaxEDRValueLabel               = @"Max EDR Value";
static const NSString* kMaxEDRReferenceLabel           = @"Max EDR Reference";
static const NSString* kMaxEDRPotentialLabel           = @"Max EDR Potential";

static const NSString* kUtilSectionLabel               = @"Util";

static const NSString* kGPUSectionLabel                = @"GPU";
static const NSString* kGPUNameLabel                   = @"Name";
static const NSString* kGPUTimeLabel                   = @"Avg. Time(ms)";
static const NSString* kResolutionScaleLabel           = @"Resolution %";

static const NSString* kCameraSectionLabel             = @"Camera";
static const NSString* kCameraAnimationLabel           = @"Animation";
static const NSString* kCameraFrameIDLabel             = @"Frame ID";

static const NSString* kUnknownLabel                   = @"Unknown";

static const float kBloomIntensityMinimum = 0.f;
static const float kBloomIntensityMaximum = 1.f;
static const float kDefaultBloomIntensity = .1f;

static const float kBloomThresholdMinimum = 1.f;
static const float kBloomThresholdMaximum = 10.f;
static const float kDefaultBloomThreshold = 6.f;

static const float kBloomRangeMinimum = 0.f;
static const float kBloomRangeMaximum = 10.f;
static const float kDefaultBloomRange = 2.f;

static const enum ExposureControlType kDefaultExposureControlType = kExposureControlTypeKey;
static const float kManualExposureMinimum = -10.f;
static const float kManualExposureMaximum = 10.f;
static const float kDefaultManualExposure = 0.f;

static const float kExposureKeys[] = {.07f, .09f, .18f, .36f, .72f, .96f};
static const uint8_t kExposureKeyCount = sizeof(kExposureKeys) / sizeof(kExposureKeys[0]);
static const uint8_t kDefaultExposureKeyIndex = 4;

static const enum TonemapOperatorType kDefaultTonemapOperatorType = kTonemapOperatorTypeReinhardEx;
static const float kTonemapWhitePointMinimum = 1.f;
static const float kTonemapWhitePointMaximum = 15.f;
static const float kDefaultTonemapWhitePoint = 6.24f;
static const float kDefaultTonemapEDRScaleWeight = 0.5f;

// Note that the app will increment frame in fixed intervals when animating
static const NSUInteger kDefaultCameraStepCount = 1000;
static const uint32_t kDefaultCameraFrameIndex = 390;
static const bool kDefaultIsCameraAnimationEnabled = NO;

static const float kDefaultResolutionScale = 1.f;

#endif /* UIDefaults_h */
