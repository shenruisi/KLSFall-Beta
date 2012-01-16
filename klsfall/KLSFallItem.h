//
//  KLSFallItem.h
//  KSLFallDemo
//
//  Created by shen yin on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KLSObject.h"
#import "KLSView.h"

#define nFall_SHOULD_DELETE_ITEM @"noteFallshoulddeleteitem"

#ifdef KLSFall_NetworkDL
#error Should Not be define ahead 
#endif
#define KLSFall_NetworkDL 0


//must be define larger than 1
#define kKLSFallItemRealScale 1.3

@interface KLSFallItemBean : 
#ifdef kKLSViewALive 
KLSObject
#else
NSObject
#endif 
{
    NSString *title;
    NSString *uuid;
    
    NSMutableArray *subItems;
    
    NSString *icon;
    
#if KLSFall_NetworkDL
    BOOL downloadComplete;
#endif 
}

@property (retain) NSString *title;
@property (retain) NSString *uuid;
@property (retain) NSMutableArray *subItems;


@property (retain) NSString *icon;

#if KLSFall_NetworkDL
@property (assign) BOOL downloadComplete;
#endif 

- (BOOL)hasSubItems;

@end

@protocol KLSFallItemCircleDelegate
- (void)KLSFallCircleDidClick;
@end


@interface KLSFallItemCircle : 
#ifdef kKLSViewALive 
KLSView
#else
UIView
#endif
{
    id<KLSFallItemCircleDelegate> _itemDelegate;
}

- (void)setItemDelegate:(id<KLSFallItemCircleDelegate>)itemdelegate;
@end


@interface KLSFallItem : KLSView <
 KLSFallItemCircleDelegate
>{
    KLSFallItemBean *bean;
    
    
    @private
    KLSFallItemCircle *_circle;
#ifdef kKLSViewALive 
    KLSView *_content;
#else
    UIView *_content;
#endif
    
    id _target;
	SEL _selector;
    BOOL useSettingSize;
    
}
@property (retain) KLSFallItemBean *bean;

- (id)initWithSettingSize;
- (void)addTarget:(id)tar selector:(SEL)sel;

- (void)showDeleteButton;
- (void)hiddenDeleteButton;

- (void)becomeGroup;
- (void)becomeSingle;

@end
