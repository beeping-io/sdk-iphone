//
//  IosAudioController.m
//

#import "IosAudioController.h"
#import <AudioToolbox/AudioToolbox.h>

#import "BeepingCoreLib_api.h"


#define kOutputBus 0
#define kInputBus 1

IosAudioController* iosAudio;

void checkStatus(int status){
	if (status) {
		printf("Status not 0! %d\n", status);
		exit(1);
	}
}

static OSStatus recordingCallback(void *inRefCon, 
                                  AudioUnitRenderActionFlags *ioActionFlags, 
                                  const AudioTimeStamp *inTimeStamp, 
                                  UInt32 inBusNumber, 
                                  UInt32 inNumberFrames, 
                                  AudioBufferList *ioData) {
	
  if (iosAudio->mBeepingObject->mDecoding == 0)
    return noErr;
  
	// Because of the way our audio format (setup below) is chosen:
	// we only need 1 buffer, since it is mono
	// Samples are 16 bits = 2 bytes.
	// 1 frame includes only 1 sample
  
	AudioBuffer buffer;
	
	buffer.mNumberChannels = 1;
	buffer.mDataByteSize = inNumberFrames * 2;
	buffer.mData = malloc( inNumberFrames * 2 );
	
	// Put buffer in a AudioBufferList
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
	
  // Then:
  // Obtain recorded samples
	
  OSStatus status;
	
  status = AudioUnitRender([iosAudio audioUnit],
                           ioActionFlags,
                           inTimeStamp,
                           inBusNumber,
                           inNumberFrames,
                           &bufferList);
	checkStatus(status);
	
    
  // Now, we have the samples we just read sitting in buffers in bufferList
	// Process the new data
	[iosAudio processAudio:&bufferList];
	
    //Now Decode Audio *******************
    
    //convert from AudioBuffer format to *float buffer
    iosAudio->floatBuffer = (float *)malloc(inNumberFrames * sizeof(float));
    
    //UInt16 *frameBuffer = bufferList.mBuffers[0].mData;
    SInt16 *frameBuffer = bufferList.mBuffers[0].mData;
    for(int j=0;j<inNumberFrames;j++)
    {
        iosAudio->floatBuffer[j] = frameBuffer[j]/32768.0;
    }

    int ret = BEEPING_DecodeAudioBuffer(iosAudio->floatBuffer, inNumberFrames, (void*)iosAudio->mBeepingObject->mBeepingCore);
  
    //public static final int BC_TOKEN_START = 0;
    //public static final int BC_TOKEN_END_OK = 1;
    //public static final int BC_TOKEN_END_BAD = 2;
    //public static final int BC_END_PLAY = 3;
  
    if (ret == -2)
    {
      NSLog(@"BEGIN TOKEN FOUND!");

      [iosAudio->mObject performSelector:iosAudio->mSelector withObject:[NSNumber numberWithInt:0]];
    }
    else if (ret >= 0)
    {
      NSLog(@"Token found! %@",@(ret).stringValue);
    }
    else if (ret == -3)
    {
      int sizeStringDecoded = BEEPING_GetDecodedData(iosAudio->mStringDecoded, (void*)iosAudio->mBeepingObject->mBeepingCore);
      
      NSString *tmpString = [NSString stringWithUTF8String:iosAudio->mStringDecoded];

      iosAudio->mBeepingObject->mDecodedString = [NSString stringWithUTF8String:iosAudio->mStringDecoded];
      
      if (sizeStringDecoded > 0)
      {
        iosAudio->mBeepingObject->mDecodedOK = 1;
        NSLog(@"END DECODING OK! %@ ", tmpString);
        [iosAudio->mObject performSelector:iosAudio->mSelector withObject:[NSNumber numberWithInt:1]];
      }
      else
      {
        iosAudio->mBeepingObject->mDecodedOK = -1;
        NSLog(@"END DECODING BAD! %@ ", tmpString);
        [iosAudio->mObject performSelector:iosAudio->mSelector withObject:[NSNumber numberWithInt:2]];
      }
    }
    else
    {
        //no data found in this buffer
    }

	// release the malloc'ed data in the buffer we created earlier
	free(bufferList.mBuffers[0].mData);
	free(iosAudio->floatBuffer);
    
  return noErr;
}

static OSStatus playbackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) {    
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
  
    for (int i=0; i < ioData->mNumberBuffers; i++)
    { // in practice we will only ever have 1 buffer, since audio format is mono
		AudioBuffer buffer = ioData->mBuffers[i];
		
//		NSLog(@"  Buffer %d has %d channels and wants %d bytes of data.", i, buffer.mNumberChannels, buffer.mDataByteSize);
		    
		// copy temporary buffer data to output buffer
		UInt32 size = min(buffer.mDataByteSize, [iosAudio tempBuffer].mDataByteSize); // dont copy more data than we have, or than fits
		memcpy(buffer.mData, [iosAudio tempBuffer].mData, size);
		buffer.mDataByteSize = size; // indicate how much data we wrote in the buffer
		
		// uncomment to hear random noise
		/*UInt16 *frameBuffer = buffer.mData;
		for (int j = 0; j < inNumberFrames; j++)
          frameBuffer[j] = rand();*/
        
        // Play encoded buffer
        if (iosAudio->mBeepingObject->mEncoding > 0)
        {
            int sizeSamplesRead;
            float audioBuffer[2048];
            sizeSamplesRead = BEEPING_GetEncodedAudioBuffer(audioBuffer, (void*)iosAudio->mBeepingObject->mBeepingCore);
            if (sizeSamplesRead == 0)
                iosAudio->mBeepingObject->mEncoding = 0;
            
            SInt16 *frameBuffer = buffer.mData;
            for(int j=0;j<sizeSamplesRead;j++)
            {
                frameBuffer[j] = audioBuffer[j]*32768.0;
            }
        }
        else
        {
            SInt16 *frameBuffer = buffer.mData;
            for (int j = 0; j < inNumberFrames; j++)
                frameBuffer[j] = 0;
        }

    }
	
    return noErr;
}

@implementation IosAudioController

@synthesize audioUnit, tempBuffer;

- (id) init {
	self = [super init];
	
	OSStatus status;
	
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	checkStatus(status);
	
	// Enable IO for recording
	UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Input, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	checkStatus(status);
	
	// Enable IO for playback
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Output, 
								  kOutputBus,
								  &flag, 
								  sizeof(flag));
	checkStatus(status);
	
	// Describe format
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= 44100.0;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
	
	// Apply format
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	checkStatus(status);
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kOutputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	checkStatus(status);
	
	
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)self;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
	checkStatus(status);
	
	// Set output callback
	callbackStruct.inputProc = playbackCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)self;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Global, 
								  kOutputBus,
								  &callbackStruct, 
								  sizeof(callbackStruct));
	checkStatus(status);
	
	// Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
	flag = 0;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	
	// Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
	// Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
	tempBuffer.mNumberChannels = 1;
  int size = 512;
#if (TARGET_OS_SIMULATOR)
  size = 256; //TODO check this value!! depends on play/record callback buffer size
#else
  size = 512; //TODO check this value!! depends on play/record callback buffer size
#endif
  
  tempBuffer.mDataByteSize = size * 2;
	tempBuffer.mData = malloc( size * 2);
  
  
	
	// Initialise
	status = AudioUnitInitialize(audioUnit);
	checkStatus(status);
	
	return self;
}

- (void) start {
	OSStatus status = AudioOutputUnitStart(audioUnit);
	checkStatus(status);
}

- (void) stop {
	OSStatus status = AudioOutputUnitStop(audioUnit);
	checkStatus(status);
}

- (void) processAudio: (AudioBufferList*) bufferList{
	AudioBuffer sourceBuffer = bufferList->mBuffers[0];
	
	// fix tempBuffer size if it's the wrong size
	if (tempBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
		free(tempBuffer.mData);
		tempBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
		tempBuffer.mData = malloc(sourceBuffer.mDataByteSize);
	}
	
	// copy incoming audio data to temporary buffer
	memcpy(tempBuffer.mData, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);
}

- (void) dealloc {
	
	AudioUnitUninitialize(audioUnit);
	free(tempBuffer.mData);
}

- (void) setBeepingObject: (BeepingCore*) beepingObject
{
    mBeepingObject = beepingObject;
}


- (void) setListenCallback:(id)object withSelector:(SEL)selector
{
    mObject = object;
    mSelector = selector;
}


@end
