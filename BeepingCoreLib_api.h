/*--------------------------------------------------------------------------------
 BeepingCoreLib_api.h
 version 0.9.7[31052017]
 
 --------------------------------------------------------------------------------*/

// This file contains all the prototypes needed for using
// the BeepingCoreLib Library for transmitting numeric data through sound 


#ifndef __BEEPINGCORELIB_API__
#define __BEEPINGCORELIB_API__

#ifndef __APPLE__
  #ifdef BEEPING_AS_DLL
    #define BEEPING_DLLEXPORT __declspec(dllexport)
  #else
    #define BEEPING_DLLEXPORT
  #endif

#else
  #define BEEPING_DLLEXPORT __attribute__((visibility("default")))
#endif

#include "stdint.h"



#ifdef __cplusplus
extern "C" {
#endif //__cplusplus

  //Use only modes >=2, 0 & 1 are deprecated
  enum BEEPING_MODE { BEEPING_MODE_AUDIBLEOLD=0, BEEPING_MODE_NONAUDIBLEOLD=1, BEEPING_MODE_AUDIBLE=2, BEEPING_MODE_NONAUDIBLE=3, BEEPING_MODE_HIDDEN=4, BEEPING_MODE_ALL=5, BEEPING_MODE_CUSTOM=6 };

  ///////////////////////////////////////////
  ///// CREATE / DESTROY
  ///////////////////////////////////////////
    
  //Create BeepingCore Object, the returned object will be passed as parameter to all API functions
  BEEPING_DLLEXPORT void *BEEPING_Create();
  
  //Destroy BeepingCore Object
  BEEPING_DLLEXPORT void BEEPING_Destroy(void *beepingObject);

  ///////////////////////////////////////////
  ///// VERSIONING //////////////////////////
  ///////////////////////////////////////////
  //Return string with version information
  BEEPING_DLLEXPORT const char* BEEPING_GetVersion();

  //Return string with version information
  BEEPING_DLLEXPORT int32_t BEEPING_GetVersionInfo(char * versioninfo);

  ///////////////////////////////////////////
  ///// CONFIGURE
  ///////////////////////////////////////////

  //BEEPING_Configure function, call this function to configure parameters of the BeepingCore Library
  //* Parameters:
  //    mode: mode (2 for audible, 3 for non-audible, don’t use other modes, 0 and 1 are old modes)
  //    samplingRate: sampling rate in Hz
  //    nChannels: number of channels of the input audio
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()
  //* Returns: 0=ok, <0=fail
  BEEPING_DLLEXPORT int32_t BEEPING_Configure(int mode, float samplingRate, int32_t bufferSize, void *beepingObject);
 
  //BEEPING_SetAudioSignature function, call this function to set a personalized audio beep that will be played 
  // simultaneously during beeping playback on top of non-audible, audible or hidden beeps
  //* Parameters:
  //    samplesSize: number of samples in samples buffer (maximum size is 2 seconds= 44100*2)
  //    samples: array with samples (44Khz, 16bits, mono)
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()
  //* Returns: 0=ok, <0=fail
  BEEPING_DLLEXPORT int32_t BEEPING_SetAudioSignature(int32_t samplesSize, const float *samplesBuffer, void *beepingObject);
 
  //BEEPING_EncodeDataToAudioBuffer function
  //* Parameters:
  //    stringToEncode: string containing the characters to encode
  //    size: number of characters in string characters to encode
  //    type: 0 for encoding only tones, 1 for encoding tones + R2D2 sounds, 2 for encoding melody
  //    melodyString: string containing characters to synthesize melody over the tones (null if type parameter is 0 or 1)
  //    melodySize: size of melody in number of notes (0 if type parameter is 0 or 1)
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()
  //* Returns: number of samples in encoded audio buffer
  BEEPING_DLLEXPORT int32_t BEEPING_EncodeDataToAudioBuffer(const char *stringToEncode, int32_t size, int32_t type, const char *melodyString, int32_t melodySize, void *beepingObject);
 

  //BEEPING_GetEncodedAudioBuffer function
  //* Parameters:
  //    audioBuffer: float array of bufferSize size to fill with encoded audio data
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()  
  //* Returns: number of samples read, maximum will be configured bufferSize, 0 or < bufferSize means that end has been reached
  BEEPING_DLLEXPORT int32_t BEEPING_GetEncodedAudioBuffer(float *audioBuffer, void *beepingObject);

  //BEEPING_CreateAudioBufferFromData function, resets the read index on the internal buffer that has the encoded string
  //* Parameters:
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()  
  //* Returns: 0=ok, <0=fail
  BEEPING_DLLEXPORT int32_t BEEPING_ResetEncodedAudioBuffer(void *beepingObject);


  //BEEPING_DecodeAudioBuffer function, receives an audiobuffer of specified size and outputs if encoded data is found
  //* Parameters:
  //    audioBuffer: float array of bufferSize size with audio data to be decoded
  //    size: size of audioBuffer
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()  
  //* Returns: -1 if no decoded data is found, -2 if start token is found, -3 if complete word has been decoded, positive number if character is decoded (number is the token idx)
  BEEPING_DLLEXPORT int32_t BEEPING_DecodeAudioBuffer(float *audioBuffer, int size, void *beepingObject);


  //BEEPING_GetDecodedData function, retrieves the last decoded data found
  //* Parameters:
  //    stringDecoded: string containing decoded characters
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()
  //* Returns: 0 if no decoded data is available, >0 if data is available and it's ok, <0 if data is available but it's wrong, for the last two cases the return value magnitude contains number of characters in string decoded
  BEEPING_DLLEXPORT int32_t BEEPING_GetDecodedData(char *stringDecoded, void *beepingObject);
  //we should include maxsize?? int32_t maxsize

  //BEEPING_GetConfidence function, outputs Reception Quality Measure to give confidence about the received beep. 
  // A Reception Quality value of 1.0 will mean that the reception conditions are ideal, a lower value will mean that 
  // listener is in a noisy environment, the listener should be closer to the transmitter, etc.
  //* Parameters:
  //    beepingObject: BEEPING object instance, created in BEEPING_Create()
  //* Returns: confidence value from 0.0 o 1.0
  BEEPING_DLLEXPORT float BEEPING_GetConfidence(void *beepingObject); //Get global confidence (combination of the other confidence values)
  BEEPING_DLLEXPORT float BEEPING_GetConfidenceError(void *beepingObject); //Get confidence due to tokens corrected by correction algorithm
  BEEPING_DLLEXPORT float BEEPING_GetConfidenceNoise(void *beepingObject); //Get confidence due to signal to noise ratio in received beeps

  BEEPING_DLLEXPORT float BEEPING_GetReceivedBeepsVolume(void *beepingObject); // Get average received volume of last beeps transmission in DB

  //BEEPING_GetDecodedMode function, outputs an integer representation of the decoded mode found from all 
  // available decoding modes, it only makes sense when decoder is configured with the ALL mode, for other modes
  // decoded mode will be always the same as the decoding mode.
  //* Parameters:
  //    none
  //* Returns: decoded mode found ( AUDIBLE = 0, NONAUDIBLE = 1, HIDDEN = 2 )
  BEEPING_DLLEXPORT int32_t BEEPING_GetDecodedMode(void *beepingObject);

  /////////////////////////////////////////////////////////////////////////////
  // FOR CUSTOM MODE //////////////////////////////////////////////////////////

  BEEPING_DLLEXPORT int32_t BEEPING_SetCustomBaseFreq(float baseFreq, int beepsSeparation, void *beepingObject);

  /////////////////////////////////////////////////////////////////////////////
  // Functions to get decoding frequency range (begin range frequency and end range frequency)
  BEEPING_DLLEXPORT float BEEPING_GetDecodingBeginFreq(void *beepingObject);
  BEEPING_DLLEXPORT float BEEPING_GetDecodingEndFreq(void *beepingObject);

  /////////////////////////////////////////////////////////////////////////////
  // FOR SYNTH MODE //////////////////////////////////////////////////////////

  BEEPING_DLLEXPORT int32_t BEEPING_SetSynthMode(int synthMode, void *beepingObject);
  BEEPING_DLLEXPORT int32_t BEEPING_SetSynthVolume(float synthVolume, void *beepingObject);


  //Not used
  BEEPING_DLLEXPORT int32_t BEEPING_GetSpectrum(float *spectrumBuffer, void *beepingObject);
  

#ifdef __cplusplus
}
#endif //__cplusplus

#endif //__BEEPINGCORELIB_API__
