//
//  AppDelegate.m
//  KLSFallDemo
//
//  Created by Jerry Wang on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "KLsFallView.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    // Override point for customization after application launch.
//    self.window.backgroundColor = [UIColor whiteColor];
//    [self.window makeKeyAndVisible];
    
    dataSource = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (int i = 0; i < 10; ++i) {
        KLSFallItemBean *bean = [[KLSFallItemBean alloc] init];
        bean.title = @"sample";
        [dataSource addObject:bean];
        [bean release];
    }
    
    
    myFallView = [[KLSFallView alloc] initWithFrame:CGRectMake(0, 20, 320, 410)];
    [myFallView setItemSize:CGSizeMake(50, 50)];
    [myFallView setFallOperation:NO];
    [myFallView setMaxItemCountPerPage:18];
    [myFallView setGroupingAbility:YES];
    [myFallView setRowSpace:10];
    [myFallView setFallDelegate:self];
    [myFallView setFallDataSource:self];
    [myFallView setMarginLeft:10];
    [myFallView setMarginTop:20];
    
    [self.window addSubview:myFallView];
    [myFallView release];
    [myFallView render];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    
	[self.window makeKeyAndVisible];
    return YES;
}

- (void)fallView:(KLSFallView *)fallView didSelectItemAtIndex:(int)index{
    
}

- (void)fallView:(KLSGroupView *)fallView didSelectGroupItemAtIndex:(int)index{
    
}

- (void)fallView:(KLSFallView *)fallView willDeleteGroupItemAtIndex:(int)index{
    [fallView deleteGroupItemAtIndex:index];
}

- (void)fallView:(KLSFallView *)fallView willDeleteItemAtIndex:(int)index{
    [fallView deleteItemAtIndex:index];
}


- (KLSFallItem *)fallView:(KLSFallView *)fallView eachItemAtIndex:(int)index{
    KLSFallItem *item = [[[KLSFallItem alloc] initWithSettingSize] autorelease];
    
    item.bean = [dataSource objectAtIndex:index];
    
    if (1==index) {
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        item.bean.subItems = temp;
        [temp release];
        for (int i = 0; i < 3; i++) {
            
            KLSFallItemBean *bean = [[KLSFallItemBean alloc] init];
            [item.bean.subItems addObject:bean];
            [bean release];
        }
        
    }
    
    return item;
}

- (NSInteger)numberOfColsInFallView:(KLSFallView *)fallView{
    return 4;
}

- (NSInteger)numberOfItemsInFallView:(KLSFallView *)fallView{
    return [dataSource count];
}

- (IBAction)editBtn:(id)sender{
    if (myFallView.isEditing) {
        [myFallView endEidt];
    }
    else{
        [myFallView beginEidt];
    }
}

- (IBAction)addBtn:(id)sender{
    KLSFallItemBean *bean = [[KLSFallItemBean alloc] init];
    bean.title = @"new";
    [dataSource addObject:bean];
    [bean release];
    
    
    [myFallView reloadNewItems];
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc{
    [dataSource release],dataSource = nil;
    [myFallView release],myFallView = nil;
    [super dealloc];
}

@synthesize editBtn;
@synthesize addBtn;

@end
