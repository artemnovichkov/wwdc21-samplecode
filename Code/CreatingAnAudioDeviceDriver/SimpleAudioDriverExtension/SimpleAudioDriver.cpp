/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the driver, which manages communications
             between user clients and the audio device.
*/

// Self Include
#include "SimpleAudioDriver.h"

// Local Include
#include "SimpleAudioDevice.h"
#include "SimpleAudioDriverUserClient.h"
#include "SimpleAudioDriverKeys.h"

// System Include
#include <AudioDriverKit/AudioDriverKit.h>
#include <DriverKit/IOUserServer.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/OSString.h>
#include <DriverKit/IODispatchQueue.h>

constexpr uint32_t k_zero_time_stamp_period = 32768;

struct SimpleAudioDriver_IVars
{
	OSSharedPtr<IODispatchQueue>	m_work_queue;
	OSSharedPtr<SimpleAudioDevice>	m_simple_audio_device;
};

bool SimpleAudioDriver::init()
{
	auto answer = super::init();
	if (!answer)
	{
		return false;
	}
	ivars = new SimpleAudioDriver_IVars();
	if (ivars == nullptr)
	{
		return false;
	}
	
	return true;
}

void SimpleAudioDriver::free()
{
	if (ivars != nullptr)
	{
		ivars->m_work_queue.reset();
		ivars->m_simple_audio_device.reset();
	}
	IOSafeDeleteNULL(ivars, SimpleAudioDriver_IVars, 1);
	super::free();
}

kern_return_t SimpleAudioDriver::Start_Impl(IOService* in_provider)
{
	bool success = false;
	auto device_uid = OSSharedPtr(OSString::withCString(kSimpleAudioDriverDeviceUID), OSNoRetain);
	auto model_uid = OSSharedPtr(OSString::withCString("SimpleAudioDevice-Model"), OSNoRetain);
	auto manufacturer_uid = OSSharedPtr(OSString::withCString("Apple Inc."), OSNoRetain);
	auto device_name = OSSharedPtr(OSString::withCString("SimpleAudioDevice"), OSNoRetain);
	
	kern_return_t error = Start(in_provider, SUPERDISPATCH);
	FailIfError(error, , Failure, "Failed to start Super");
	
    // Get the service's default dispatch queue from the driver object.
	ivars->m_work_queue = GetWorkQueue();
	FailIfError(ivars->m_work_queue.get() == nullptr, error = kIOReturnInvalid, Failure, "failed to get default work queue");
		
    // Allocate and configure audio devices as necessary.
	ivars->m_simple_audio_device = OSSharedPtr(OSTypeAlloc(SimpleAudioDevice), OSNoRetain);
	FailIfNULL(ivars->m_simple_audio_device.get(), error = kIOReturnNoMemory, Failure, "Failed to allocate SimpleAudioDevice");
	
	success = ivars->m_simple_audio_device->init(this, false, device_uid.get(), model_uid.get(), manufacturer_uid.get(), k_zero_time_stamp_period);
	FailIf(success == false, error = kIOReturnNoMemory, Failure, "Failed to init SimpleAudioDevice");
	
	ivars->m_simple_audio_device->SetName(device_name.get());
	
    // Add the device object to the driver.
	AddObject(ivars->m_simple_audio_device.get());
			
    // Register the service.
	error = RegisterService();
	FailIfError(error, , Failure, "failed to register service!");
	
	return kIOReturnSuccess;
	
Failure:
	return error;
}

kern_return_t	SimpleAudioDriver::Stop_Impl(IOService* in_provider)
{
	ivars->m_work_queue.reset();
	ivars->m_simple_audio_device.reset();
	return Stop(in_provider, SUPERDISPATCH);
}

kern_return_t SimpleAudioDriver::NewUserClient_Impl(uint32_t in_type, IOUserClient** out_user_client)
{
	kern_return_t error = kIOReturnSuccess;
	
    // Have the super class create the IOUserAudioDriverUserClient object
    // if the type is kIOUserAudioDriverUserClientType.
	if (in_type == kIOUserAudioDriverUserClientType)
	{
		error = super::NewUserClient(in_type, out_user_client, SUPERDISPATCH);
		FailIfError(error, , Failure, "Failed to create user client");
		FailIfNULL(*out_user_client, error = kIOReturnNoMemory, Failure, "Failed to create user client");
	}
	else
	{
		IOService* user_client_service = nullptr;
		error = Create(this, "SimpleAudioDriverUserClientProperties", &user_client_service);
		FailIfError(error, , Failure, "failed to create the SimpleAudioDriver user-client");
		*out_user_client = OSDynamicCast(IOUserClient, user_client_service);
	}
	
Failure:
	return error;
}

kern_return_t SimpleAudioDriver::StartDevice(IOUserAudioObjectID in_object_id, IOUserAudioStartStopFlags in_flags)
{
	if (in_object_id != ivars->m_simple_audio_device->GetObjectID())
	{
		DebugMsg("SimpleAudioDriver::StartDevice - unknown object id %u", in_object_id);
		return kIOReturnBadArgument;
	}
	
	__block kern_return_t ret;
	ivars->m_work_queue->DispatchSync(^(){
        // Tell the super class to start the device and the update timer
        // to generate timestamps.
		ret = super::StartDevice(in_object_id, in_flags);
	});
	if (ret == kIOReturnSuccess)
	{
        // Enable any custom driver related things here.
	}
	return ret;
}

kern_return_t SimpleAudioDriver::StopDevice(IOUserAudioObjectID in_object_id, IOUserAudioStartStopFlags in_flags)
{
	if (in_object_id != ivars->m_simple_audio_device->GetObjectID())
	{
		DebugMsg("SimpleAudioDriver::StopDevice - unknown object id %u", in_object_id);
		return kIOReturnBadArgument;
	}
	
    // Tell the super class to stop device and stop timestamps.
	__block kern_return_t ret;
	ivars->m_work_queue->DispatchSync(^(){
		ret = super::StopDevice(in_object_id, in_flags);
	});
	
	if (ret == kIOReturnSuccess)
	{
        // Disable any custom driver related things here.
	}
	return ret;
}

kern_return_t SimpleAudioDriver::HandleToggleDataSource()
{
	__block kern_return_t ret = kIOReturnSuccess;
	ivars->m_work_queue->DispatchSync(^(){
		ret = ivars->m_simple_audio_device->ToggleDataSource();
	});
	return ret;
}

kern_return_t SimpleAudioDriver::HandleTestConfigChange()
{
	auto change_info = OSSharedPtr(OSString::withCString("Toggle Sample Rate"), OSNoRetain);
	return ivars->m_simple_audio_device->RequestDeviceConfigurationChange(k_custom_config_change_action, change_info.get());
}
