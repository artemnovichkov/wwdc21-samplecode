/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for UI Options.
*/

#ifndef UIOptionEnums_h
#define UIOptionEnums_h

// --
typedef enum TonemapOperatorType
{
    kTonemapOperatorTypeReinhard = 0,
    kTonemapOperatorTypeReinhardEx,
    kTonemapOperatorTypeCount
}TonemapOperatorType;

// --
typedef enum ExposureControlType
{
    kExposureControlTypeManual = 0,
    kExposureControlTypeKey,
    kExposureControlTypeCount
}ExposureControlType;

#endif /* UIOptionEnums_h */
