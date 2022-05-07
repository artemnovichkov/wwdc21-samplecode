/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the user client, which connects to and
            exercises the driver.
*/

//	Local Include
#include "SimpleAudioDriverUserClient.h"
#include "SimpleAudioDriver.h"
#include "SimpleAudioDriverKeys.h"

//	System Includes
#include <DriverKit/DriverKit.h>
#include <DriverKit/OSSharedPtr.h>
#include <AudioDriverKit/AudioDriverKit.h>

struct SimpleAudioDriverUserClient_IVars
{
	OSSharedPtr<SimpleAudioDriver>	m_provider = nullptr;
};

bool	SimpleAudioDriverUserClient::init()
{
	auto theAnswer = super::init();
	if (!theAnswer)
	{
		return false;
	}
	ivars = IONewZero(SimpleAudioDriverUserClient_IVars, 1);
	if (ivars == nullptr)
	{
		return false;
	}
	
	return true;
}

void	SimpleAudioDriverUserClient::free()
{
	if (ivars != nullptr)
	{
		ivars->m_provider.reset();
	}
	IOSafeDeleteNULL(ivars, SimpleAudioDriverUserClient_IVars, 1);
	super::free();
}

kern_return_t	SimpleAudioDriverUserClient::Start_Impl(IOService* in_provider)
{
	kern_return_t ret = kIOReturnSuccess;
	FailIfNULL(in_provider, ret = kIOReturnBadArgument, Failure, "provider is null!");
	
	ret = Start(in_provider, SUPERDISPATCH);
	FailIfError(ret, , Failure, "Failed to start super!");
	
	ivars->m_provider = OSSharedPtr(OSDynamicCast(SimpleAudioDriver, in_provider), OSRetain);

	return kIOReturnSuccess;
	
Failure:
	ivars->m_provider.reset();
	return ret;
}

kern_return_t	SimpleAudioDriverUserClient::Stop_Impl(IOService* in_provider)
{
	return Stop(in_provider, SUPERDISPATCH);
}

kern_return_t	SimpleAudioDriverUserClient::ExternalMethod(uint64_t in_selector,
															IOUserClientMethodArguments* in_arguments,
															const IOUserClientMethodDispatch* in_dispatch,
															OSObject* in_target,
															void* in_reference)
{
	kern_return_t ret = kIOReturnSuccess;
	
	if (ivars == nullptr)
	{
		return kIOReturnNoResources;
	}
	if (ivars->m_provider.get() == nullptr)
	{
		return kIOReturnNotAttached;
	}
		
	switch(static_cast<SimpleAudioDriverExternalMethod>(in_selector))
	{
		case SimpleAudioDriverExternalMethod_Open:
		{
			ret = kIOReturnSuccess;
			break;
		}

		case SimpleAudioDriverExternalMethod_Close:
		{
			ret = kIOReturnSuccess;
			break;
		}

		case SimpleAudioDriverExternalMethod_ToggleDataSource:
		{
			ret = ivars->m_provider->HandleToggleDataSource();
			break;
		}
			
		case SimpleAudioDriverExternalMethod_TestConfigChange:
		{
			ret = ivars->m_provider->HandleTestConfigChange();
			break;
		}

		default:
			ret = super::ExternalMethod(in_selector, in_arguments, in_dispatch, in_target, in_reference);
	};
	
	return ret;
}
