//
//  AppSettings.m
//  qtum wallet
//
//  Created by Vladimir Lebedevich on 24.03.17.
//  Copyright © 2017 PixelPlex. All rights reserved.
//

#import "AppSettings.h"
#import "NSUserDefaults+Settings.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "LanguageManager.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface AppSettings ()

@property (assign, nonatomic) BOOL isMainNet;
@property (assign, nonatomic) BOOL isRPC;

@end

@implementation AppSettings

#pragma mark - init

+ (instancetype)sharedInstance
{
    static AppSettings *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] initUniqueInstance];
    });
    return instance;
}

- (instancetype)initUniqueInstance
{
    self = [super init];
    
    if (self != nil) {
    }
    return self;
}

#pragma mark - Private Methods

-(void)setup{
    [NSUserDefaults saveIsRPCOnSetting:NO];
    [NSUserDefaults saveIsMainnetSetting:NO];
    [PopUpsManager sharedInstance];
    [self setupFabric];
    [self setupFingerpring];
}

-(void)setupFabric{
    [Fabric with:@[[Crashlytics class]]];
}

-(void)setupFingerpring {
    
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    
    
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
 
    }
}

#pragma mark - Accessory methods

-(BOOL)isMainNet{
    return [NSUserDefaults isMainnetSetting];
}

-(BOOL)isRPC{
    return [NSUserDefaults isRPCOnSetting];
}

@end
