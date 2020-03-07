//
//  Beeping.m
//  Beeping
//

#import "Beeping.h"

@interface Beeping ()

@end

@implementation Beeping

//
// @method init
//

+(Beeping*) instance
{
    // Declaración de variables
    static Beeping *beepingManager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        beepingManager = [[self alloc] init];
    });

    // Se devuelve la instancia
    return beepingManager;

}

//
// @method init
//


- (id) init {
    
    SEL beepingHandler = @selector(onBeep:);

    // Set callback that will be triggered when a beep is decoded/found
    _beepingCore = [[BeepingCore alloc] init:beepingHandler];

    // Set encoder/decoder mode, valid modes are defined in: BeepingCore.framework/Headers/BeepingCore.h
    // MODE_AUDIBLE | MODE_NONAUDIBLE | MODE_HIDDEN | MODE_ALL
    [_beepingCore configure:self withMode:MODE_NONAUDIBLE];
    
    //Show version of framework and audio library in log
    NSLog(@"%@", [NSString stringWithFormat:@"%@", [_beepingCore getVersionCoreFramework]]);
    
    // Tag SDK
    // NSLog(@"Nombre de la aplicación: %@", [NSString stringWithUTF8String:getprogname()]);
        
    return self;
}

//
// @method listen
//

-(void) listen {

    NSLog(@"[Beeping [info]] Listening ...");

    // Empieza la escucha de beeps
    // Se pedirá acceso al micrófono en el caso de que no lo haya
    [_beepingCore startBeepingListen];

}

//
// @method stop
//

-(void) stop {

    NSLog(@"[Beeping [info]] Stopped");

    // Empieza la escucha de beeps
    // Se pedirá acceso al micrófono en el caso de que no lo haya
    [_beepingCore stopBeepingListen];
}

//
// @method onBeep
//

- (void) onBeep:( NSNumber * ) value {

    // Se ha recibido un segmento de sonido
    int _value = [value intValue];
    
    NSString *_beepId;

    NSString *decodedmodeStr = @"MODE_NONAUDIBLE";

    NSString *decodedError ;
    NSString *confidenceError ;

    // Evaluación del segmento que está llegando
    switch (_value) {

        case BEEP_TOKEN_START:

            NSLog(@"[Beeping [info]] BEEP_TOKEN_END_OK");

            break;

        case BEEP_TOKEN_END_OK:

            NSLog(@"[Beeping [info]] BEEP_TOKEN_END_OK");

            // Get beepId
            _beepId = [_beepingCore getDecodedKey];

            // Se llama al delegate
            [_delegate beepIdWith:_beepId] ;

            break;

        case BEEP_TOKEN_END_BAD:

            // Decodificando el error
            decodedError = [NSString stringWithFormat:@"%@%@%@%@%@", @"BEEP_TOKEN_END_BAD ", [_beepingCore getDecodedString], @" [", decodedmodeStr, @"]"];

            confidenceError = [NSString stringWithFormat:@"%@%.1f%%%@%.2f", @"conf:", [_beepingCore getConfidence]*100.f, @" e:", [_beepingCore getConfidenceError]];

            NSLog(@"[Beeping [info]] BEEP_TOKEN_END_OK");

            break;
            
        default:
            
            NSLog(@"[Beeping [info]] Event not captured");
            
            break;

    }

}

- (void) dealloc {}

@end
