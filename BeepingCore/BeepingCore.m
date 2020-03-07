//
//  BeepingCore.m
//
//  BeepingCore.framework version 1.0.4 [20012017]
//

#import "BeepingCore.h"
#import "BeepingCoreLib_api.h"

#import "IosAudioController.h"

#import <AudioToolbox/AudioToolbox.h>

@implementation BeepingCore

- (id)init:(SEL)selector
{
  mBeepingCore = BEEPING_Create();

  NSLog(@"%s",BEEPING_GetVersion());
  
  mEncoding = 0;
  mDecoding = 0;

  mBeepingCallback = selector;
  
  iosAudio = nil;
  
  return self;
}

- (int)setAudioSignature:(CFURLRef)urlAudioFile
{
  //int nChannels = 2;
  
  if (urlAudioFile == NULL)
  {
    NSLog(@"setting audio no NONE");
    BEEPING_SetAudioSignature(0, NULL, mBeepingCore);
    
    return 0;
  }
  
  ExtAudioFileRef mAudioFile_eaf;
  
  OSStatus err = ExtAudioFileOpenURL((CFURLRef)urlAudioFile, &mAudioFile_eaf);
  if (noErr != err)
  {
    NSLog(@"error opening audio file");
    NSLog(@"setting audio no NONE");
    BEEPING_SetAudioSignature(0, NULL, mBeepingCore);
    return -1;
  }
  
  AudioStreamBasicDescription formatAudioFile;
  formatAudioFile.mSampleRate       = mSampleRate;
  formatAudioFile.mFormatID         = kAudioFormatLinearPCM;
  //formatAudioFile.mFormatFlags      = kAudioFormatFlagIsFloat; //for float32
  //formatAudioFile.mBitsPerChannel   = 32; //for float32
  //formatAudioFile.mFormatFlags      = kAudioFormatFlagIsPacked; //for int16??
  formatAudioFile.mFormatFlags = kAudioFormatFlagIsSignedInteger; //for int16
  formatAudioFile.mBitsPerChannel   = 16; //for int16
  
  //format.mFormatFlags = kAudioFormatFlagIsBigEndian;
  
  //formatAudioFile.mChannelsPerFrame = nChannels;
  formatAudioFile.mFramesPerPacket  = 1;
  
  formatAudioFile.mBytesPerFrame    = (formatAudioFile.mBitsPerChannel / 8) * formatAudioFile.mChannelsPerFrame;
  formatAudioFile.mBytesPerPacket   = formatAudioFile.mFramesPerPacket * formatAudioFile.mBytesPerFrame;
  formatAudioFile.mReserved         = 0;
  
  
  err = ExtAudioFileSetProperty(mAudioFile_eaf, kExtAudioFileProperty_ClientDataFormat, sizeof(formatAudioFile), &formatAudioFile);
  
  /* Read the file contents using ExtAudioFileRead */
  SInt64 numFramesInputVoice = 0;
  UInt32 dataSizeInputVoice = sizeof(numFramesInputVoice);
  err = ExtAudioFileGetProperty(mAudioFile_eaf, kExtAudioFileProperty_FileLengthFrames, &dataSizeInputVoice, &numFramesInputVoice);
  
  
  //Read input file to memory buffer (all file to memory)
  
  UInt32 nFramesAudioFile = (SInt32)numFramesInputVoice;
  UInt32 nChannelsAudioFile = formatAudioFile.mChannelsPerFrame;
  UInt32 nSamplesAudioFile = nFramesAudioFile * nChannelsAudioFile;
  
  SInt16 *mAudioFileBufferInMemory;
  mAudioFileBufferInMemory = (SInt16 *)malloc(nSamplesAudioFile * sizeof(SInt16));
  
  AudioBufferList mAudioFileBufferList;
  mAudioFileBufferList.mNumberBuffers = 1;
  mAudioFileBufferList.mBuffers[0].mNumberChannels = formatAudioFile.mChannelsPerFrame;
  mAudioFileBufferList.mBuffers[0].mDataByteSize = nSamplesAudioFile * sizeof(SInt16);
  mAudioFileBufferList.mBuffers[0].mData = mAudioFileBufferInMemory;
  
  err = ExtAudioFileRead(mAudioFile_eaf, &nSamplesAudioFile, &mAudioFileBufferList);
  if (noErr != err)
  {
    NSLog(@"error reading audio file");
    NSLog(@"setting audio no NONE");
    BEEPING_SetAudioSignature(0, NULL, mBeepingCore);
  }
  
  SInt16 *samplesBufferInt;
  samplesBufferInt = (SInt16 *)(mAudioFileBufferList.mBuffers[0].mData); //for int16
  
  float *samplesBufferFloat = (float *)malloc(nSamplesAudioFile * sizeof(float));;
  for (int i=0;i<nSamplesAudioFile;i++)
    samplesBufferFloat[i] = samplesBufferInt[i] / 32767.f;
  
  BEEPING_SetAudioSignature(nSamplesAudioFile, (float*)samplesBufferFloat, mBeepingCore);
  
  ExtAudioFileDispose(mAudioFile_eaf);
  
  free(mAudioFileBufferInMemory);
  
  free(samplesBufferFloat);
  
  return 0;
}


- (void)configure:(id)object withMode:(EnumBeepingMode)mode
{
  if (iosAudio != nil)
  {
    [NSThread sleepForTimeInterval:0.5];
    [iosAudio stop];
    
    iosAudio = nil;
  }
  
  mSampleRate = 44100.f;
  //mBufferSize = 2048;
  //mBufferSize = 256; //TODO check this value!! depends on play/record callback buffer size
  
  #if (TARGET_OS_SIMULATOR)
  mBufferSize = 512; //TODO check this value!! depends on play/record callback buffer size
  #else
  mBufferSize = 1024; //TODO check this value!! depends on play/record callback buffer size
  #endif
  
  
  //Configuration
  if (mode==MODE_AUDIBLE)
  {
    NSLog(@"Configuration AUDIBLE");
    BEEPING_Configure(BEEPING_MODE_AUDIBLE,mSampleRate,mBufferSize,mBeepingCore);
  }
  else if (mode==MODE_NONAUDIBLE)
  {
    NSLog(@"Configuration NONAUDIBLE");
    BEEPING_Configure(BEEPING_MODE_NONAUDIBLE,mSampleRate,mBufferSize,mBeepingCore);
  }
  else if (mode==MODE_HIDDEN)
  {
    NSLog(@"Configuration HIDDEN");
    BEEPING_Configure(BEEPING_MODE_HIDDEN,mSampleRate,mBufferSize,mBeepingCore);
  }
  else if (mode==MODE_ALL)
  {
    NSLog(@"Configuration ALL");
    BEEPING_Configure(BEEPING_MODE_ALL,mSampleRate,mBufferSize,mBeepingCore);
  }
  else if (mode==MODE_CUSTOM)
  {
    NSLog(@"Configuration CUSTOM");
    BEEPING_Configure(BEEPING_MODE_CUSTOM,mSampleRate,mBufferSize,mBeepingCore);
  }
  else //error defaulting to decode ALL
  {
    //maybe we want to include also ald modes from BeepingCoreLib_api?
    //enum BEEPINGCORE_MODE { AUDIBLEOLD=0, NONAUDIBLEOLD=1, AUDIBLE=2, NONAUDIBLE=3, HIDDEN=4, ALL=5 };
    NSLog(@"Wrong configuration mode, defaulting to ALL");
    BEEPING_Configure(BEEPING_MODE_ALL,mSampleRate,mBufferSize,mBeepingCore);
  }
  
  mEncoding = 0;
  mDecoding = 0;
  
  /*if (iosAudio != nil)
  {
    [NSThread sleepForTimeInterval:0.5];
    [iosAudio stop];
    
    iosAudio = nil;
  }*/
  
  iosAudio = [[IosAudioController alloc] init];
    
  [iosAudio setBeepingObject:self];
  
  //NSLog(@"Setting callback");
  
  //callback set in init:(SEL)selector
  [iosAudio setListenCallback:object withSelector:mBeepingCallback];
    
  //NSLog(@"Callback set");
    
}

- (int)setCustomBaseFreq:(float)baseFreq withBeepsSeparation:(int)beepsSeparation
{
  
  return BEEPING_SetCustomBaseFreq(baseFreq, beepsSeparation, mBeepingCore);
  
}

- (void)startBeepingListen
{
  if (mDecoding == 1)
    return;
  
  [iosAudio start];
  
  mDecoding = 1;
  /* do lots of stuff */
      
  //[object performSelector:selector withObject:self];
}

- (void)stopBeepingListen
{
  mDecoding = 0;
  [iosAudio stop];
}

- (void)playBeeping:(NSString *) code
{
  //const char *stringToEncode = [_StringToEncodeTextField.text UTF8String];
  const char *stringToEncode = [code UTF8String];
    
  int type = 0;
//    if (_MelodySwitch.isOn)
//    {
//        type = 1;
//    }
    
  BEEPING_EncodeDataToAudioBuffer(stringToEncode, (int)strlen(stringToEncode), type, 0, 0, mBeepingCore);
    
  mEncoding = 1;

  NSLog(@"Starting audio");
  
  [iosAudio start];
    
  NSLog(@"Audio Started");
    
}

- (NSString *)getDecodedString
{
  //NSString *decodedStr = self->mDecodedString;
  //return decodedStr;
  return self->mDecodedString;
  
}

- (NSString *)getDecodedKey
{
  //NSString *keyStr = [self->mDecodedString substringToIndex:5];
  //return keyStr;
  return [self->mDecodedString substringToIndex:5];
}

//BEGIN For decoding time SECOND SCREEN
+ (int)charToVal:(char)curChar
{
  char convArray[] =
  {'0','1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v' };
  for(int i=0;i<32; ++i)
  {
    if(curChar==convArray[i])
    {
      return i;
    }
  }
  return -1;
}

+ (int)fromBaseToDec:(const char *)number withLength:(int)length withBase:(int)rad
{
  int decimal = 0;
  int factor = 1;
  for (int i=length-1; i >=0; --i)
  {
    int curVal = [BeepingCore charToVal:number[i]];
    decimal += factor*curVal;
    factor*=rad;
  }
  return decimal;
}

- (int)getDecodedTimeStamp
{
  NSString *timestampStr = [self->mDecodedString substringFromIndex:5];
  const char* cstring = [timestampStr UTF8String];
  int num = [BeepingCore fromBaseToDec:cstring withLength:4 withBase:32];

  return num;
}
//END For decoding time SECOND SCREEN

- (NSString *)getVersionCoreLib
{
  return [NSString stringWithUTF8String:BEEPING_GetVersion()];
}


- (NSString *)getVersionCoreFramework
{
  //"BeepingCoreLib version 0.9.1 [04042016]"
  return @"BeepingCore.framework version 1.0.4 [20012017]";
}

- (float)getConfidence
{
  return BEEPING_GetConfidence(mBeepingCore);
}

- (float)getConfidenceError
{
  return BEEPING_GetConfidenceError(mBeepingCore);
}

- (float)getConfidenceNoise
{
  return BEEPING_GetConfidenceNoise(mBeepingCore);
}

- (float)getReceivedBeepsVolume
{
  return BEEPING_GetReceivedBeepsVolume(mBeepingCore); // Get average received volume of last beeps transmission in DB
}

-(float)getDecodingBeginFreq
{
  return BEEPING_GetDecodingBeginFreq(mBeepingCore);
}

-(float)getDecodingEndFreq
{
  return BEEPING_GetDecodingEndFreq(mBeepingCore);

}


- (int)getDecodedMode
{
  return BEEPING_GetDecodedMode(mBeepingCore);
}


- (void)dealloc
{
  [iosAudio stop];
    
  BEEPING_Destroy(mBeepingCore);
}

@end

