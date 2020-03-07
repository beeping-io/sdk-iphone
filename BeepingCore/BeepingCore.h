//
//  BeepingCore.h
//  BeepingCore
//
//  BeepingCore.framework version 1.0.4 [20012017]
//

#import <UIKit/UIKit.h>

// Enum for modes passed to configure function
typedef NS_ENUM(NSInteger, EnumBeepingMode) {
  MODE_AUDIBLE = 0,
  MODE_NONAUDIBLE = 1,
  MODE_HIDDEN = 2,
  MODE_ALL = 3,
  MODE_CUSTOM = 4,
    
    BEEP_TOKEN_START = 0,
    BEEP_TOKEN_END_OK = 1,
    BEEP_TOKEN_END_BAD = 2,
    BEEP_END_PLAY = 3
    

};

// Project version number for BeepingCore.
FOUNDATION_EXPORT double BeepingCoreVersionNumber;

// Project version string for BeepingCore.
FOUNDATION_EXPORT const unsigned char BeepingCoreVersionString[];

// In this header, you should import all the public headers of your framework
// using statements like #import <BeepingCore/PublicHeader.h>

@interface BeepingCore : NSObject
{
  @public
    void *mBeepingCore;
    float mSampleRate;
    int mBufferSize;
    
    int mEncoding;
    int mDecoding;
    
    float *mAudioBuffer; //nchannels = 1
    
    int mDecodedOK;
    
    NSString *mDecodedString;

    SEL mBeepingCallback;
}

/* init function: Initializes BeepingCore framework
     Parameters:
       selector: selector function that will be called everytime that
                 BeepingCore decodes a new message
     Returns: id, a BeepingCore object of type id */
- (id)init:(SEL)selector;

/* configure function: configures framework with one mode from EnumBeepingMode
     Parameters:
       object: BeepingCore object of type id returned at init function
       mode: decoder mode from EnumBeepingMode available ones (see above)
     Returns: void */
- (void)configure:(id)object withMode:(EnumBeepingMode)mode;

/* setCustomBaseFreq function: This function allows to configure custom mode
   with a custom decoding frequency range. When setting the custom frequency
   range make sure you don't go beyond the decoding limits (100Hz to 22050Hz).
   To check the configured range you can call the below functions
   getDecodingBeginFreq and getDecodingEndFreq.
     Parameters:
       baseFreq: starting frequency in Hz (e.g: 15000.0)
       beepsSeparation: separation of beeps (use numbers between 1 and 10) and
                        check the configured range limits to avoid going beyond
                        upper freq (22050Hz)
     Returns: 0 ok, -1 error */
- (int)setCustomBaseFreq:(float)baseFreq withBeepsSeparation:(int)beepsSeparation;

/* getDecodingFreq functions:
     Parameters:
       none
     Returns: decoding range start or end frequency in Hz */
-(float)getDecodingBeginFreq; // For Begin Frequency
-(float)getDecodingEndFreq; // For End Frequency

/* setAudioSignature function: Sets audio for playback together with beeping
   messages sent
     Parameters:
       urlAudioFile: url of type CFURLRef that links to audio file (use max 3
                     seconds files)
     Returns: 0 ok, -1 error opening file */
- (int)setAudioSignature:(CFURLRef)urlAudioFile;

/* startBeepingListen function: puts the framework in listening mode (decoding)
     Parameters:
       none
     Returns: void */
- (void)startBeepingListen;

/* stopBeepingListen function: puts the framework in non listening mode (not
   decoding)
     Parameters:
       none
     Returns: void */
- (void)stopBeepingListen;

/* playBeeping function: plays a user defined beeping message
     Parameters:
       code: 9 digits code to send of type NSString). Available digits are
             {0-9},{a-v}
     Returns: void */
- (void)playBeeping:(NSString *) code;

/* getDecodedString function: get decoded raw message after BeepingCore has
   found a new message and the selector function specified in the configure
   function has been triggered
     Parameters:
       none
     Returns: 9 digits decoded code of type NSString */
- (NSString *)getDecodedString;

/* getDecodedKey function: get decoded key message (second screen) after
   BeepingCore has found a new message and the selector function specified in
   the configure function has been triggered
     Parameters:
       none
     Returns: 5 digits decoded key of type NSString */
- (NSString *)getDecodedKey;

/* getDecodedTimeStamp function: get decoded timestamp message (second screen)
   after BeepingCore has found a new message and the selector function specified
   in the configure function has been triggered
     Parameters:
       none
     Returns: integer number with a timestamp in seconds associated to decoded
              message */
- (int)getDecodedTimeStamp;

/* getVersionCoreLib function: get version of internal BeepingCore library
     Parameters:
       none
     Returns: string of type NSString with version information */
- (NSString *)getVersionCoreLib;

/* getVersionCoreLib function: get version of BeepingCore framework
     Parameters:
       none
     Returns: string of type NSString with version information */
- (NSString *)getVersionCoreFramework;


/* getConfidence function: outputs Reception Quality Measure to give confidence
   about the received beep.
    Parameters:
      none
    Returns: a floating point number between 0.0 and 1.0. Reception Quality
             value of 1.0 will mean that the reception conditions are ideal, a
             lower value will mean that listener is in a noisy environment, the
             listener should be closer to the transmitter, etc. */
- (float)getConfidence; //global confidence (combination of the other confidence values)
- (float)getConfidenceError; //confidence due to tokens corrected by correction algorithm
- (float)getConfidenceNoise; //confidence due to signal to noise ratio in received beeps

/* getReceivedBeepsVolume function: outputs
    Parameters:
      none
    Returns: a floating point number between 0.0 and -inf. Reception volume of
             beeps in dB. The more the value is closer to means that the
             received volume is higher. When received volume is lower than -90dB
             it is likely that the beeps are not decoded properly */
- (float)getReceivedBeepsVolume;


/* getDecodedMode function: get decoding mode from message decoded after
   BeepingCore has found a new message and the selector function specified in
   the configure function has been triggered. This function is important when
   framework is configured in the mode MODE_ALL. For other configured modes it
   will be always the same as the configured mode.
     Parameters:
       none
     Returns: integer number with decoded mode found
              ( AUDIBLE = 0, NONAUDIBLE = 1, HIDDEN = 2 ) */
- (int)getDecodedMode;

@end
