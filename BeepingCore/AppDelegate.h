//
//  AppDelegate.h
//  IosBeepingCoreLibTest
//
//  Created by Oscar Mayor (oscar.mayor@voctrolabs.com) on 08/07/14.
//  Copyright (c) 2014 Voctro Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BeepingCore.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BeepingCore *myBeepingCore;

@end
