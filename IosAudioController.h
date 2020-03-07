//
//  IosAudioController.h
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <BeepingCore.h>

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif


@interface IosAudioController : NSObject {
	AudioComponentInstance audioUnit;
	AudioBuffer tempBuffer; // this will hold the latest data from the microphone
  
    
@public
  BeepingCore *mBeepingObject;
  id mObject;
  SEL mSelector;
  
  float *floatBuffer;
  char mStringDecoded[30];
       
}

@property (readonly) AudioComponentInstance audioUnit;
@property (readonly) AudioBuffer tempBuffer;

- (void) start;
- (void) stop;
- (void) processAudio: (AudioBufferList*) bufferList;

- (void) setBeepingObject: (BeepingCore*) beepingObject;
- (void) setListenCallback:(id)object withSelector:(SEL)selector;

@end

// setup a global iosAudio variable, accessible everywhere
extern IosAudioController* iosAudio;
