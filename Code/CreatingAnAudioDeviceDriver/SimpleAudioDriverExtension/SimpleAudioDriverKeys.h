/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constants for identifiers used by both the user client and the driver.
*/

#ifndef SimpleAudioDriverKeys_h
#define SimpleAudioDriverKeys_h

#define kSimpleAudioDriverClassName "SimpleAudioDriver"
#define kSimpleAudioDriverDeviceUID "SimpleAudioDevice-UID"

#define kSimpleAudioDriverCustomPropertySelector 'sadc'
#define kSimpleAudioDriverCustomPropertyQualifier0 "Qualifier-0"
#define kSimpleAudioDriverCustomPropertyQualifier1 "Qualifier-1"
#define kSimpleAudioDriverCustomPropertyDataValue0 "Default-0"
#define kSimpleAudioDriverCustomPropertyDataValue1 "Default-1"

enum SimpleAudioDriverExternalMethod
{
    SimpleAudioDriverExternalMethod_Open, // No arguments.
    SimpleAudioDriverExternalMethod_Close, // No arguments.
    SimpleAudioDriverExternalMethod_ToggleDataSource, // No argument. Used to switch between data source selection.
    SimpleAudioDriverExternalMethod_TestConfigChange // No arguments. Used to switch between sample rates and excercise config change mechanism.
};

#endif /* SimpleAudioDriverKeys_h */
