//
//  Beeping.h
//  Beeping
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BeepingCore.h"

@class Beeping;

@protocol beepingDelegate <NSObject>

@required
- (void) beepIdWith:(NSString *)beep_id  ;
@end

@interface Beeping : NSObject <NSURLConnectionDelegate> {

    // Private properties
    // Beeping object
    BeepingCore *_beepingCore;              

}

    // Public Methods
    // Singleton method
    +(Beeping *) instance;

    // Public methods
    -(void) listen;
    -(void) stop;

    // Public properties
    // Delegate object
    @property (nonatomic, weak) id<beepingDelegate>delegate;

@end
