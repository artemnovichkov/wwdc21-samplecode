/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the main view controller, which provides a user
            interface for installing and interacting with the driver.
*/

#import "ViewController.h"

#import "SimpleAudioDriverKeys.h"

#import <SystemExtensions/SystemExtensions.h>
#import <os/log.h>
#import <IOKit/IOKitLib.h>

#import <CoreAudio/CoreAudio.h>
#import <CoreAudio/AudioServerPlugIn.h>
#import <vector>
#import <exception>

#define DRIVER_BUNDLE_IDENTIFIER @"com.example.apple-samplecode.SimpleAudioDriver"

static
os_log_t
loghandle(void) {
	static os_log_t loghandle;
	static dispatch_once_t logpred;
	dispatch_once(&logpred, ^{
		loghandle = os_log_create("com.example.apple-samplecode.SimpleAudio", "ViewController");
	});
	return loghandle;
}

@interface ViewController (OSSystemExtensionRequestDelegate) <OSSystemExtensionRequestDelegate>

@end

@interface ViewController ()
@property (strong) OSSystemExtensionRequest *request;
@property (weak) IBOutlet NSTextField *resultField;

@property IONotificationPortRef mIOKitNotificationPort;
@property io_object_t ioObject;
@property io_connect_t ioConnection;
@property (weak) IBOutlet NSTextField *userClientConnectionField;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];
	
	// Update the view, if already loaded.
}

// Use the SystemExtension framework to install the dext.
- (IBAction)installExtension:(id)sender {
	if (self.request) {
		NSBeep();
		return;
	}
	
	os_log(loghandle(), "Beginning to install extension");
	OSSystemExtensionRequest *request =
    [OSSystemExtensionRequest activationRequestForExtension:DRIVER_BUNDLE_IDENTIFIER
                                                      queue:dispatch_get_main_queue()];
	request.delegate = self;
	
	[[OSSystemExtensionManager sharedManager] submitRequest:request];
	self.request = request;
	_resultField.stringValue = @"Begun 🔄";
}

// Use the SystemExtension framework to remove the dext.
- (IBAction)removeExtension:(id)sender {
	if (self.request) {
		NSBeep();
		return;
	}
	
	os_log(loghandle(), "Beginning to remove extension");
	OSSystemExtensionRequest *request =
    [OSSystemExtensionRequest deactivationRequestForExtension:DRIVER_BUNDLE_IDENTIFIER
                                                        queue:dispatch_get_main_queue()];
	request.delegate = self;
	
	[[OSSystemExtensionManager sharedManager] submitRequest:request];
	self.request = request;
	
	_resultField.stringValue = @"Begun uninstall 🚮";
}

// Handle a request to update the dext.
- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest OS_UNUSED *)request actionForReplacingExtension:(OSSystemExtensionProperties *)existing withExtension:(OSSystemExtensionProperties *)extension
{
	os_log(loghandle(), "Received the upgrade request (%{public}@ -> %{public}@), answering replace", existing.bundleVersion, extension.bundleVersion);
	return OSSystemExtensionReplacementActionReplace;
}

// Update the UI if the dext installation request requires user approval.
- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request
{
	if (request != self.request) {
		os_log(loghandle(), "UNEXPECTED NON-CURRENT Request to activate %{public}@ succeeded", request.identifier);
		return;
	}
	os_log(loghandle(), "Request to activate %{public}@ awaiting approval", request.identifier);
	_resultField.stringValue = @"Awaiting Approval ⏱";
}

// Handle the result of the install, remove, and upgrade requests.
- (void)request:(OSSystemExtensionRequest *)request didFinishWithResult:(OSSystemExtensionRequestResult)result
{
	if (request != self.request) {
		os_log(loghandle(), "UNEXPECTED NON-CURRENT Request to activate %{public}@ succeeded", request.identifier);
		return;
	}
	os_log(loghandle(), "Request to activate %{public}@ succeeded (%zu)!", request.identifier, (unsigned long)result);
	_resultField.stringValue = result == OSSystemExtensionRequestCompleted
	? @"Succeeded ✅" : @"Will succeed on reboot ✅";
	self.request = nil;
}

// Handle failure of the install, remove, and upgrade requests.
- (void)request:(OSSystemExtensionRequest *)request didFailWithError:(NSError *)error
{
	if (request != self.request) {
		os_log(loghandle(), "UNEXPECTED NON-CURRENT Request to activate %{public}@ failed with error %{public}@.", request.identifier, error);
		return;
	}
	os_log(loghandle(), "Request to activate %{public}@ failed with error %{public}@.", request.identifier, error);
	_resultField.stringValue = [NSString stringWithFormat:@"Failed ❌\n%@.", error.localizedDescription];
	self.request = nil;
}

// Validate the device's custom properties by checking the data types, selector,
// qualifier, and data value.
- (OSStatus)checkDeviceCustomProperties
{
	OSStatus err = kAudioHardwareNoError;
	try
	{
		AudioObjectPropertyAddress prop_addr = {kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
		
		prop_addr = {kAudioHardwarePropertyTranslateUIDToDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
		auto device_uid = CFSTR(kSimpleAudioDriverDeviceUID);
		AudioObjectID device_id = kAudioObjectUnknown;
		UInt32 out_size = sizeof(AudioObjectID);
		auto err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &prop_addr, sizeof(CFStringRef), &device_uid, &out_size, &device_id);
		if (err)
		{
			throw std::runtime_error("Failed to get SimpleAudioDevice by uid");
		}
		
		prop_addr = {kAudioObjectPropertyCustomPropertyInfoList, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
		err = AudioObjectGetPropertyDataSize(device_id, &prop_addr, 0, nullptr, &out_size);
		if (err)
		{
			throw std::runtime_error("Failed to get custom property list size");
		}
		
		auto num_items = out_size/sizeof(AudioServerPlugInCustomPropertyInfo);
		std::vector<AudioServerPlugInCustomPropertyInfo> custom_prop_list(num_items);
		err = AudioObjectGetPropertyData(device_id, &prop_addr, 0, nullptr, &out_size, custom_prop_list.data());
		if (err)
		{
			throw std::runtime_error("Failed to get custom property list");
		}
		num_items = out_size / sizeof(AudioServerPlugInCustomPropertyInfo);
		custom_prop_list.resize(num_items);
		if (num_items != 1)
		{
			throw std::runtime_error("Should only have one custom property on the SimpleAudioDevice");
		}
		
		AudioServerPlugInCustomPropertyInfo custom_prop_info = custom_prop_list.front();
		if (custom_prop_info.mSelector != kSimpleAudioDriverCustomPropertySelector)
		{
			throw std::runtime_error("Custom property selector is incorrect");
		}
		if (custom_prop_info.mQualifierDataType != kAudioServerPlugInCustomPropertyDataTypeCFString)
		{
			throw std::runtime_error("Custom property qualifier type is incorrect");
		}
		if (custom_prop_info.mPropertyDataType != kAudioServerPlugInCustomPropertyDataTypeCFString)
		{
			throw std::runtime_error("Custom property data type is incorrect");
		}

		std::vector<std::pair<CFStringRef, CFStringRef>> custom_prop_qualifier_data_pair = {
			{ CFSTR(kSimpleAudioDriverCustomPropertyQualifier0), CFSTR(kSimpleAudioDriverCustomPropertyDataValue0) },
			{ CFSTR(kSimpleAudioDriverCustomPropertyQualifier1), CFSTR(kSimpleAudioDriverCustomPropertyDataValue1) },
		};
		
		prop_addr = { custom_prop_info.mSelector, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain };
		for (const auto &[qualifier, data] : custom_prop_qualifier_data_pair)
		{
			CFStringRef custom_prop_data = nullptr;
			UInt32 the_size = sizeof(CFStringRef);
			err = AudioObjectGetPropertyData(device_id, &prop_addr, sizeof(CFStringRef), &qualifier, &the_size, &custom_prop_data);
			if (err)
			{
				throw std::runtime_error("Error getting custom property value");
			}
			CFComparisonResult compare_result = CFStringCompare(data, custom_prop_data, kCFCompareCaseInsensitive);
			if (compare_result != kCFCompareEqualTo)
			{
				throw std::runtime_error("Custom property data is incorrect");
			}
			CFRelease(custom_prop_data);
		}
	}
	catch(...)
	{
		NSLog(@"Caught exception trying to validate custom properties.");
	}
	return err;
}

// Open a user client instance, which initiates communication with the driver.
- (IBAction)openUserClient:(id)sender {
	
	if (_ioObject == IO_OBJECT_NULL && _ioConnection == IO_OBJECT_NULL)
	{
        // Get the IOKit main port.
		mach_port_t theMainPort = MACH_PORT_NULL;
		kern_return_t theKernelError = IOMainPort(bootstrap_port, &theMainPort);
		if (theKernelError != kIOReturnSuccess)
		{
			_userClientConnectionField.stringValue = @"Failed to get IOMainPort.";
			return;
		}
		
        // Create a matching dictionary for the driver class. Note that classes
        // published by a DEXT need to be matched by class name rather than
        // other methods. So be sure to use IOServiceNameMatching rather than
        // IOServiceMatching to construct the dictionary.
		CFDictionaryRef theMatchingDictionary = IOServiceNameMatching(kSimpleAudioDriverClassName);
		io_service_t matchedService = IOServiceGetMatchingService(theMainPort, theMatchingDictionary);
		if (matchedService)
		{
			_ioObject = matchedService;
			theKernelError = IOServiceOpen(_ioObject, mach_task_self(), 0, &_ioConnection);
			if (theKernelError != kIOReturnSuccess)
			{
				
				_userClientConnectionField.stringValue = [NSString stringWithFormat:@"failed to connect to user client, error:%u.", theKernelError];
			}
			else
			{
				_userClientConnectionField.stringValue = [NSString stringWithFormat:@"Connection to user client succeeded,"];
				
				OSStatus error = [self checkDeviceCustomProperties];
				if (error)
				{
					_userClientConnectionField.stringValue = [NSString stringWithFormat:@"Connection to user client succeeded, but custom properties could not be validated."];
				}
			}
		}
	}
}

// Closes the user client, which terminates communication with the driver.

- (IBAction)closeUserClient:(id)sender
{
	if (_ioObject != IO_OBJECT_NULL && _ioConnection != IO_OBJECT_NULL)
	{
		IOServiceClose(_ioConnection);
		_ioObject = IO_OBJECT_NULL;
		_ioConnection = IO_OBJECT_NULL;
		_userClientConnectionField.stringValue = [NSString stringWithFormat:@"Disconnected user client."];
	}
}

// Instructs the user client to toggle the driver's data source,
// which changes the generated sine tone's frequency.
- (IBAction)toggleToneFrequency:(id)sender
{
	if (_ioConnection == IO_OBJECT_NULL)
	{
		_userClientConnectionField.stringValue = @"Cannot toggle data source since user client is not connected.";
		return;
	}
	
    // Call custom user client method to toggle the data source directly on the driver extension.
    // This should result in the CoreAudio HAL updating the selector control, and listeners such
    // as Audio MIDI Setup will get a properties changed notification.
	kern_return_t error = IOConnectCallMethod(_ioConnection,
											  static_cast<uint64_t>(SimpleAudioDriverExternalMethod_ToggleDataSource),
											  nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);
	if (error != kIOReturnSuccess)
	{
		_userClientConnectionField.stringValue = [NSString stringWithFormat:@"Failed to toggle data source, error:%u.", error];
	}
}

// Instructs the user client to perform a configuration change, which toggles
// the device's sample rate.
- (IBAction)toggleRate:(id)sender
{
	if (_ioConnection == IO_OBJECT_NULL)
	{
		_userClientConnectionField.stringValue = @"Cannot toggle device sample rate since user client is not connected.";
		return;
	}
	
    // Call custom user client method to change the test config change mechanism,
    // which toggles the device's sample rate.
	kern_return_t error = IOConnectCallMethod(_ioConnection,
											  static_cast<uint64_t>(SimpleAudioDriverExternalMethod_TestConfigChange),
											  nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);
	if (error != kIOReturnSuccess)
	{
		_userClientConnectionField.stringValue = [NSString stringWithFormat:@"Failed to toggle device sample rate, error:%u.", error];
	}
}
@end
