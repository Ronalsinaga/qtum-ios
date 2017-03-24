//
//  NSUserDefaults+Settings.m
//  qtum wallet
//
//  Created by Никита Федоренко on 24.03.17.
//  Copyright © 2017 Designsters. All rights reserved.
//

#import "NSUserDefaults+Settings.h"

static NSString * const kSettingIsMainnet           = @"kSettingExtraMessages";
static NSString * const kSettingIsRPCOn             = @"kSettingLongMessage";

@implementation NSUserDefaults (Settings)

+ (void)saveIsMainnetSetting:(BOOL)value{
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:kSettingIsMainnet];
}

+ (BOOL)isMainnetSetting{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSettingIsMainnet];
}

+ (void)saveIsRPCOnSetting:(BOOL)value{
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:kSettingIsRPCOn];
}

+ (BOOL)isRPCOnSetting{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSettingIsRPCOn];
}

@end
