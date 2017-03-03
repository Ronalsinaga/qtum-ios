//
//  SubscribeTokenViewController.h
//  qtum wallet
//
//  Created by Никита Федоренко on 03.03.17.
//  Copyright © 2017 Designsters. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SubscribeTokenCoordinatorDelegate;

@interface SubscribeTokenViewController : UIViewController

@property (weak,nonatomic) id <SubscribeTokenCoordinatorDelegate> delegate;

@end
