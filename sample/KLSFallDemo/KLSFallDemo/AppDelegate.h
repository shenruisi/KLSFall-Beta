//
//  AppDelegate.h
//  KLSFallDemo
//
//  Created by Jerry Wang on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KLSFallView.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    KLSFallView *myFallView;
    
    NSMutableArray *dataSource;
}

@property (retain) IBOutlet UIButton *editBtn;
@property (retain) IBOutlet UIButton *addBtn;
@property (retain, nonatomic) IBOutlet UIWindow *window;

- (IBAction)editBtn:(id)sender;
- (IBAction)addBtn:(id)sender;
@end
