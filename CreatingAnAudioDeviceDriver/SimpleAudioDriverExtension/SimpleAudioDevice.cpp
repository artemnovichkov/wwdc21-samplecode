/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of an AudioDriverKit device that generates a
             sine wave.
*/

// Local Includes
#include "SimpleAudioDevice.h"
#include "SimpleAudioDriver.h"
#include "SimpleAudioDriverKeys.h"

// AudioDriverKit Includes
#include <AudioDriverKit/AudioDriverKit.h>

// System Includes
#include <math.h>
#include <DriverKit/DriverKit.h>

#define kSampleRate_1 44100.0
#define kSampleRate_2 48000.0

#define kToneGenerationBufferFrameSize 512

#define kNumInputDataSources 2

struct SimpleAudioDevice_IVars
{
	OSSharedPtr<IOUserAudioDriver>	m_driver;
	OSSharedPtr<IODispatchQueue>	m_work_queue;
	
	uint64_t	m_zts_host_ticks_per_buffer;
	uint64_t	m_tone_host_ticks_per_buffer;
	
	OSSharedPtr<IOUserAudioStream>			m_input_stream;
	OSSharedPtr<IOMemoryMap>				m_input_memory_map;
	
	IOUserAudioStreamBasicDescription		m_input_stream_format;
	OSSharedPtr<IOUserAudioLevelControl>	m_input_volume_control;
	OSSharedPtr<IOUserAudioSelectorControl> m_input_selector_control;
	IOUserAudioSelectorValueDescription 	m_data_sources[kNumInputDataSources];
	
	OSSharedPtr<IOTimerDispatchSource>		m_zts_timer_event_source;
	OSSharedPtr<OSAction>					m_zts_timer_occurred_action;
	
	OSSharedPtr<IOTimerDispatchSource>		m_tone_timer_event_source;
	OSSharedPtr<OSAction>					m_tone_timer_occurred_action;
	
	uint64_t	m_tone_host_time;
	uint64_t	m_tone_sample_index;
};

bool SimpleAudioDevice::init(IOUserAudioDriver* in_driver,
						   bool in_supports_prewarming,
						   OSString* in_device_uid,
						   OSString* in_model_uid,
						   OSString* in_manufacturer_uid,
						   uint32_t in_zero_timestamp_period)
{
	auto success = super::init(in_driver, in_supports_prewarming, in_device_uid, in_model_uid, in_manufacturer_uid, in_zero_timestamp_period);
	if (!success)
	{
		return false;
	}
	ivars = IONewZero(SimpleAudioDevice_IVars, 1);
	if (ivars == nullptr)
	{
		return false;
	}
	
	IOReturn error = kIOReturnSuccess;
	
	ivars->m_driver = OSSharedPtr(in_driver, OSRetain);
	ivars->m_work_queue = GetWorkQueue();
	
	IOTimerDispatchSource* zts_timer_event_source = nullptr;
	OSAction* zts_timer_occurred_action = nullptr;
	
	IOTimerDispatchSource* tone_timer_event_source = nullptr;
	OSAction* tone_timer_occurred_action = nullptr;
	
	OSSharedPtr<OSString> input_stream_name = OSSharedPtr(OSString::withCString("SimpleInputStream"), OSNoRetain);
	OSSharedPtr<OSString> input_volume_control_name = OSSharedPtr(OSString::withCString("SimpleInputVolumeControl"), OSNoRetain);
	OSSharedPtr<OSString> input_data_source_control = OSSharedPtr(OSString::withCString("Input Tone Frequency Control"), OSNoRetain);

	// Custom property information.
	IOUserAudioObjectPropertyAddress prop_addr = {
		kSimpleAudioDriverCustomPropertySelector,
		IOUserAudioObjectPropertyScope::Global,
		IOUserAudioObjectPropertyElementMain };
	OSSharedPtr<IOUserAudioCustomProperty> custom_property = nullptr;
	OSSharedPtr<OSString> qualifier = nullptr;
	OSSharedPtr<OSString> data = nullptr;

	// Configure device and add stream objects.
	auto data_source_0 = OSSharedPtr(OSString::withCString("Sine Tone 440"), OSNoRetain);
	auto data_source_1 = OSSharedPtr(OSString::withCString("Sine Tone 660"), OSNoRetain);
	ivars->m_data_sources[0] = { 440, data_source_0 };
	ivars->m_data_sources[1] = { 660, data_source_1 };
	
    // Setup stream formats and other stream related properties.
	double sample_rates[] = {kSampleRate_1, kSampleRate_2};
	SetAvailableSampleRates(sample_rates, 2);
	SetSampleRate(kSampleRate_1);
	const auto input_channels_per_frame = 1;
	IOUserAudioChannelLabel input_channel_layout[input_channels_per_frame] = { IOUserAudioChannelLabel::Mono };
	
	IOUserAudioStreamBasicDescription input_stream_formats[] =
	{
		{
			kSampleRate_1, IOUserAudioFormatID::LinearPCM,
			static_cast<IOUserAudioFormatFlags>(IOUserAudioFormatFlags::FormatFlagIsSignedInteger | IOUserAudioFormatFlags::FormatFlagsNativeEndian),
			static_cast<uint32_t>(sizeof(int16_t)*input_channels_per_frame),
			1,
			static_cast<uint32_t>(sizeof(int16_t)*input_channels_per_frame),
			static_cast<uint32_t>(input_channels_per_frame),
			16
		},
		{
			kSampleRate_2, IOUserAudioFormatID::LinearPCM,
			static_cast<IOUserAudioFormatFlags>(IOUserAudioFormatFlags::FormatFlagIsSignedInteger | IOUserAudioFormatFlags::FormatFlagsNativeEndian),
			static_cast<uint32_t>(sizeof(int16_t)*input_channels_per_frame),
			1,
			static_cast<uint32_t>(sizeof(int16_t)*input_channels_per_frame),
			static_cast<uint32_t>(input_channels_per_frame),
			16
		},
	};
	
    // Add custom property for the audio driver.
	custom_property = IOUserAudioCustomProperty::Create(in_driver,
														prop_addr,
														true,
														IOUserAudioCustomPropertyDataType::String,
														IOUserAudioCustomPropertyDataType::String);
    // Set the qualifier and data value pair on the custom property.
	qualifier = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyQualifier0), OSNoRetain);
	data = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyDataValue0), OSNoRetain);
	custom_property->SetQualifierAndDataValue(qualifier.get(), data.get());
    
    // Set another qualifier and data value pair on the custom property.
	qualifier = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyQualifier1), OSNoRetain);
	data = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyDataValue1), OSNoRetain);
	custom_property->SetQualifierAndDataValue(qualifier.get(), data.get());
	AddCustomProperty(custom_property.get());

    // Create the IOBufferMemoryDescriptor ring buffer for the input stream.
	OSSharedPtr<IOBufferMemoryDescriptor> io_ring_buffer;
	const auto buffer_size_bytes = static_cast<uint32_t>(in_zero_timestamp_period * sizeof(uint16_t) * input_channels_per_frame);
	error = IOBufferMemoryDescriptor::Create(kIOMemoryDirectionInOut, buffer_size_bytes, 0, io_ring_buffer.attach());
	FailIf(error != kIOReturnSuccess, , Failure, "Failed to create IOBufferMemoryDescriptor");
	
    // Create input stream object and pass in the IO ring buffer memory descriptor.
	ivars->m_input_stream = IOUserAudioStream::Create(in_driver, IOUserAudioStreamDirection::Input, io_ring_buffer.get());
	FailIfNULL(ivars->m_input_stream.get(), error = kIOReturnNoMemory, Failure, "failed to create input stream");
	
	//	Configure stream properties: name, available formats, and current format.
	ivars->m_input_stream->SetName(input_stream_name.get());
	ivars->m_input_stream->SetAvailableStreamFormats(input_stream_formats, 2);
	ivars->m_input_stream_format = input_stream_formats[0];
	ivars->m_input_stream->SetCurrentStreamFormat(&ivars->m_input_stream_format);
	
	// Add stream object to the driver.
	error = AddStream(ivars->m_input_stream.get());
	FailIfError(error, , Failure, "failed to add input stream");
	
    // Create volume control object for the input stream.
	ivars->m_input_volume_control = IOUserAudioLevelControl::Create(in_driver,
																	true,
																	-6.0,
																	{-96.0, 0.0},
																	IOUserAudioObjectPropertyElementMain,
																	IOUserAudioObjectPropertyScope::Input,
																	IOUserAudioClassID::VolumeControl);
	FailIfNULL(ivars->m_input_volume_control.get(), error = kIOReturnNoMemory, Failure, "Failed to create input volume control");
	ivars->m_input_volume_control->SetName(input_volume_control_name.get());
	
    // Add volume control to device object.
	error = AddControl(ivars->m_input_volume_control.get());
	FailIfError(error, , Failure, "failed to add input volume level control");
	
    // Create input data source selector control used to control the sine tone frequency.
	ivars->m_input_selector_control = IOUserAudioSelectorControl::Create(in_driver,
																		 true,
																		 IOUserAudioObjectPropertyElementMain,
																		 IOUserAudioObjectPropertyScope::Input,
																		 IOUserAudioClassID::DataSourceControl);
	FailIfNULL(ivars->m_input_selector_control.get(), error = kIOReturnNoMemory, Failure, "Failed to create input data source control");
	ivars->m_input_selector_control->AddControlValueDescriptions(ivars->m_data_sources, 2);
    // Set data source selector current value to tone with frequency of 440 hz.
	ivars->m_input_selector_control->SetCurrentSelectedValues(&ivars->m_data_sources[0].m_value, 1);
	ivars->m_input_selector_control->SetName(input_data_source_control.get());

    // Add data source selector control to driver.
	error = AddControl(ivars->m_input_selector_control.get());
	FailIfError(error, , Failure, "failed to add input data source control");
	
    // Configure device related information.
	SetPreferredInputChannelLayout(input_channel_layout, input_channels_per_frame);
	SetInputLatency(kToneGenerationBufferFrameSize);
	SetInputSafetyOffset(kToneGenerationBufferFrameSize/2);
	SetTransportType(IOUserAudioTransportType::BuiltIn);
	
    // Initialize the timer that stands in for a real interrupt.
	error = IOTimerDispatchSource::Create(ivars->m_work_queue.get(), &zts_timer_event_source);
	FailIfError(error, , Failure, "failed to create the ZTS timer event source");
	ivars->m_zts_timer_event_source = OSSharedPtr(zts_timer_event_source, OSNoRetain);
	
    // Create timer action to generate timestamps.
	error = CreateActionZtsTimerOccurred(sizeof(void*), &zts_timer_occurred_action);
	FailIfError(error, , Failure, "failed to create the timer event source action");
	ivars->m_zts_timer_occurred_action = OSSharedPtr(zts_timer_occurred_action, OSNoRetain);
	ivars->m_zts_timer_event_source->SetHandler(ivars->m_zts_timer_occurred_action.get());
	
    // Initialize the tone generation timer that stands in for a real interrupt.
	error = IOTimerDispatchSource::Create(ivars->m_work_queue.get(), &tone_timer_event_source);
	FailIfError(error, , Failure, "failed to create the tone timer event source");
	ivars->m_tone_timer_event_source = OSSharedPtr(tone_timer_event_source, OSNoRetain);
	
    // Create timer action to generate tone.
	error = CreateActionToneTimerOccurred(sizeof(void*), &tone_timer_occurred_action);
	FailIfError(error, , Failure, "failed to create the timer event source action");
	ivars->m_tone_timer_occurred_action = OSSharedPtr(tone_timer_occurred_action, OSNoRetain);
	ivars->m_tone_timer_event_source->SetHandler(ivars->m_tone_timer_occurred_action.get());
	return true;
	
Failure:
	ivars->m_driver.reset();
	ivars->m_input_stream.reset();
	ivars->m_input_memory_map.reset();
	ivars->m_input_volume_control.reset();
	ivars->m_zts_timer_event_source.reset();
	ivars->m_zts_timer_occurred_action.reset();
	ivars->m_tone_timer_event_source.reset();
	ivars->m_tone_timer_occurred_action.reset();
	return false;
}

void SimpleAudioDevice::free()
{
	if (ivars != nullptr)
	{
		ivars->m_driver.reset();
		ivars->m_input_stream.reset();
		ivars->m_input_memory_map.reset();
		ivars->m_input_volume_control.reset();
		ivars->m_input_selector_control.reset();
		ivars->m_zts_timer_event_source.reset();
		ivars->m_zts_timer_occurred_action.reset();
		ivars->m_tone_timer_event_source.reset();
		ivars->m_tone_timer_occurred_action.reset();
		ivars->m_work_queue.reset();
	}
	IOSafeDeleteNULL(ivars, SimpleAudioDevice_IVars, 1);
	super::free();
}

kern_return_t SimpleAudioDevice::StartIO(IOUserAudioStartStopFlags in_flags)
{
	DebugMsg("Start IO: device %u", GetObjectID());
	
	__block kern_return_t error = kIOReturnSuccess;
	__block OSSharedPtr<IOMemoryDescriptor> input_iomd;
	
	ivars->m_work_queue->DispatchSync(^(){
		//	Tell IOUserAudioObject base class to start IO for the device.
		error = super::StartIO(in_flags);
		FailIfError(error, , Failure, "Failed to start IO");
		
		input_iomd = ivars->m_input_stream->GetIOMemoryDescriptor();
		FailIfNULL(input_iomd.get(), error = kIOReturnNoMemory, Failure, "Failed to get input stream IOMemoryDescriptor");
		error = input_iomd->CreateMapping(0, 0, 0, 0, 0, ivars->m_input_memory_map.attach());
		FailIf(error != kIOReturnSuccess, , Failure, "Failed to create memory map from input stream IOMemoryDescriptor");

        // Start the timers to send timestamps and generate sine tone on the stream IO buffer.
		StartTimers();
		
	Failure:
		return;
	});

	return error;
}

kern_return_t SimpleAudioDevice::StopIO(IOUserAudioStartStopFlags in_flags)
{
	DebugMsg("Stop IO: device %u", GetObjectID());

    // Tell IOUserAudioObject base class to stop IO for the device.
	__block kern_return_t error;
	
	ivars->m_work_queue->DispatchSync(^(){
		// Stop the timers for timestamps and sine tone generator.
		StopTimers();

		error = super::StopIO(in_flags);
	});


	if (error != kIOReturnSuccess)
   {
	   DebugMsg("Failed to stop IO, error %d", error);
   }

	return error;
}

kern_return_t SimpleAudioDevice::PerformDeviceConfigurationChange(uint64_t change_action, OSObject* in_change_info)
{
	DebugMsg("change action %llu", change_action);
	kern_return_t ret = kIOReturnSuccess;
	switch (change_action) {
			// Add custom config change handlers
		case k_custom_config_change_action:
		{
			if (in_change_info)
			{
				auto change_info_string = OSDynamicCast(OSString, in_change_info);
				DebugMsg("%s", change_info_string->getCStringNoCopy());
			}
			
            // Toggle the sample rate of the device.
			double rate_to_set = static_cast<uint64_t>(GetSampleRate()) != static_cast<uint64_t>(kSampleRate_1) ? kSampleRate_1 : kSampleRate_2;
			ret = SetSampleRate(rate_to_set);
			if (ret == kIOReturnSuccess)
			{
                // Update stream formats with the new rate.
				ret = ivars->m_input_stream->DeviceSampleRateChanged(rate_to_set);
			}
		}
			break;
			
		default:
			ret = super::PerformDeviceConfigurationChange(change_action, in_change_info);
			break;
	}
	
	// Update the cached format.
	ivars->m_input_stream_format = ivars->m_input_stream->GetCurrentStreamFormat();
	
	return ret;
}

kern_return_t SimpleAudioDevice::AbortDeviceConfigurationChange(uint64_t change_action, OSObject* in_change_info)
{
	// Handle aborted configuration changes as necessary.
	return super::AbortDeviceConfigurationChange(change_action, in_change_info);
}

kern_return_t SimpleAudioDevice::HandleChangeSampleRate(double in_sample_rate)
{
	// This method runs when the HAL changes the sample rate of the device.
	// Add custom operations here to configure hardware and return success
	// to continue with the sample rate change.
	return SetSampleRate(in_sample_rate);
}

inline int16_t SimpleAudioDevice::FloatToInt16(float in_sample)
{
	if (in_sample > 1.0f)
	{
		in_sample = 1.0f;
	}
	else if (in_sample < -1.0f)
	{
		in_sample = -1.0f;
	}
	return static_cast<int16_t>(in_sample * 0x7fff);
}

kern_return_t SimpleAudioDevice::StartTimers()
{
	kern_return_t error = kIOReturnSuccess;
	
	UpdateTimers();
	
	if(ivars->m_zts_timer_event_source.get() != nullptr &&
	   ivars->m_tone_timer_event_source.get() != nullptr)
	{
        // Clear the device's timestamps.
		UpdateCurrentZeroTimestamp(0, 0);
		auto current_time = mach_absolute_time();
		
		{
            // Start the timer. The first time stamp is taken when it goes off.
			ivars->m_zts_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime, current_time + ivars->m_zts_host_ticks_per_buffer, 0);
			ivars->m_zts_timer_event_source->SetEnable(true);
		}
		
		{
			ivars->m_tone_sample_index = 0;
			ivars->m_tone_host_time = 0;
			
            // Now run the timer.
			ivars->m_tone_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime, current_time, 0);
			ivars->m_tone_timer_event_source->SetEnable(true);
		}
	}
	else
	{
		error = kIOReturnNoResources;
	}
	
	return error;
}

void	SimpleAudioDevice::StopTimers()
{
	if(ivars->m_zts_timer_event_source.get() != nullptr &&
	   ivars->m_tone_timer_event_source.get() != nullptr)
	{
		ivars->m_zts_timer_event_source->SetEnable(false);
		ivars->m_tone_timer_event_source->SetEnable(false);
	}
}

void	SimpleAudioDevice::UpdateTimers()
{
	struct mach_timebase_info timebase_info;
	mach_timebase_info(&timebase_info);
	
	double sample_rate = ivars->m_input_stream_format.mSampleRate;
	{
		double host_ticks_per_buffer = static_cast<double>(GetZeroTimestampPeriod() * NSEC_PER_SEC) / sample_rate;
		host_ticks_per_buffer = (host_ticks_per_buffer * static_cast<double>(timebase_info.denom)) / static_cast<double>(timebase_info.numer);
		ivars->m_zts_host_ticks_per_buffer = static_cast<uint64_t>(host_ticks_per_buffer);
	}
	
	{
		double host_ticks_per_buffer = static_cast<double>(kToneGenerationBufferFrameSize * NSEC_PER_SEC) / sample_rate;
		host_ticks_per_buffer = (host_ticks_per_buffer * static_cast<double>(timebase_info.denom)) / static_cast<double>(timebase_info.numer);
		ivars->m_tone_host_ticks_per_buffer = static_cast<uint64_t>(host_ticks_per_buffer);
	}
}

void	SimpleAudioDevice::ZtsTimerOccurred_Impl(OSAction* action, uint64_t time)
{
    // Get the current time.
	auto current_time = time;
	
    // Increment the time stamps...
	uint64_t current_sample_time = 0;
	uint64_t current_host_time = 0;
	GetCurrentZeroTimestamp(&current_sample_time, &current_host_time);
	
	auto host_ticks_per_buffer = ivars->m_zts_host_ticks_per_buffer;
	
	if(current_host_time != 0)
	{
		current_sample_time += GetZeroTimestampPeriod();
		current_host_time += host_ticks_per_buffer;
	}
	else
	{
        // ...but not if it's the first one.
		current_sample_time = 0;
		current_host_time = current_time;
	}
	
	// Update the device with the current timestamp.
	UpdateCurrentZeroTimestamp(current_sample_time, current_host_time);
	
    // Set the timer to go off in one buffer.
	ivars->m_zts_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime,
												current_host_time + host_ticks_per_buffer, 0);
}

void	SimpleAudioDevice::ToneTimerOccurred_Impl(OSAction* action, uint64_t time)
{
    // Increment the tone's host time...
    if (ivars->m_tone_host_time != 0)
	{
		ivars->m_tone_host_time += ivars->m_tone_host_ticks_per_buffer;
	}
	else
	{
		// ...but not if it's the first one.
		ivars->m_tone_sample_index = 0;
		ivars->m_tone_host_time = time;
	}
	
	// Update the device with the current timestamp.
	GenerateToneForInput(kToneGenerationBufferFrameSize);
	
	// Set the timer to go off in one buffer.
	ivars->m_tone_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime,
												 ivars->m_tone_host_time + ivars->m_tone_host_ticks_per_buffer, 0);
}

void SimpleAudioDevice::GenerateToneForInput(size_t in_frame_size)
{
	// Fill out the input buffer with a sine tone.
	if (ivars->m_input_memory_map)
	{
        // Get the pointer to the I/O buffer and use stream format information
        // to get the buffer length.
		const auto& format = ivars->m_input_stream_format;
		auto buffer_length = ivars->m_input_memory_map->GetLength() / (format.mBytesPerFrame / format.mChannelsPerFrame);
		auto num_samples = in_frame_size;
		auto buffer = reinterpret_cast<int16_t*>(ivars->m_input_memory_map->GetAddress() + ivars->m_input_memory_map->GetOffset());

        // Get volume control dB value to apply gain to the tone.
		auto input_volume_level = ivars->m_input_volume_control->GetScalarValue();
		
        // Get the frequency of the tone from the data source selector control.
		IOUserAudioSelectorValue tone_selector_value = 0;
		ivars->m_input_selector_control->GetCurrentSelectedValues(&tone_selector_value, 1);
		double frequency = static_cast<double>(tone_selector_value);
		
		for(size_t i = 0; i < num_samples; i++)
		{
			float float_value = input_volume_level * sin(2.0 * M_PI * frequency * static_cast<double>(ivars->m_tone_sample_index) / format.mSampleRate);
			int16_t integer_value = FloatToInt16(float_value);
			for (auto channel_index = 0; channel_index < format.mChannelsPerFrame; channel_index++)
			{
				auto buffer_index = (format.mChannelsPerFrame * (ivars->m_tone_sample_index) + channel_index) % buffer_length;
				buffer[buffer_index] = integer_value;
			}
			ivars->m_tone_sample_index += 1;
		}
	}
}

kern_return_t SimpleAudioDevice::ToggleDataSource()
{
	__block kern_return_t ret = kIOReturnSuccess;
	GetWorkQueue()->DispatchSync(^(){
		IOUserAudioSelectorValue current_data_source_value;
		ivars->m_input_selector_control->GetCurrentSelectedValues(&current_data_source_value, 1);
		IOUserAudioSelectorValue data_source_value_to_set =
			(current_data_source_value == ivars->m_data_sources[0].m_value) ?
				ivars->m_data_sources[1].m_value : ivars->m_data_sources[0].m_value;
		ret = ivars->m_input_selector_control->SetCurrentSelectedValues(&data_source_value_to_set, 1);
	});
	return ret;
}
