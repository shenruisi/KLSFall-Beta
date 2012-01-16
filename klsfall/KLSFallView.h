//
//  KLSFall.h
//  KLS
//
//  Created by shen yin on 8/25/11.
//  Copyright 2011 Kalos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KLSFallItem.h"
#include <QuartzCore/QuartzCore.h>

@interface KLSGroupView : UIScrollView{
    BOOL isShaking;
    BOOL isLeftMovingTrend;
@private
	CGSize _size;
    
	double _colSpace;

	CGPoint _beginPoint;
	CGPoint _lastPoint;
	
	NSMutableArray *_rects;
	NSMutableArray *_views;
	
	UIView *_handleV;
	
	int _handleId;
	
	SEL _outItemSel;
	id _tar;
	
	SEL _selectItemSel;
	id _selectTar;
	
	SEL _touchMoveSel;
	id _touchMoveTar;
	
	SEL _touchEndSel;
	id _touchEndTar;
}
@property (assign) BOOL isShaking;
@property (assign) BOOL isLeftMovingTrend;

- (CGRect)nextSit;
- (void)setItemSize:(CGSize)size;
- (KLSFallItem *)itemAtIndex:(int)index;
- (void)setColSpace:(double)space;

/*delegate for fall view so the fall view can contorl the view in the group
 */
- (void)setOutItemSelector:(SEL)sel target:(id)tar;
- (void)setTouchMoveSelector:(SEL)sel target:(id)tar;
- (void)setTouchEndSelector:(SEL)sel target:(id)tar;
- (void)setSelectItemSelector:(SEL)sel target:(id)tar;

@end

typedef enum  {
	KLSFallItemIdInvaildId = -3
}KLSFallItemId;


@protocol KLSFallViewDelegate;
@protocol KLSFallViewDataSource;

@interface KLSFallView : UIScrollView <
 UIScrollViewDelegate
>{
    int pageIndex;
    
@private
	KLSGroupView *_groupingV;
    
	struct s_constants{
        int col;
        float rowSpace;
        float colSpace;
        float highlightedAlpha;
        float marginTop;
        float marginLeft;
        float shakeAngle;
        float groupShakeAngle;
        float tElapse;
        int maxItemPerPage;
    }_fallViewConstants;
    
    struct s_flags{
        unsigned int fallFrozen:1; //当grouping时冻结其他操作
        unsigned int inGroupingTask:1;
        unsigned int fallOperation:1;
        unsigned int ignoreTouchByFallFrozen:1;
        unsigned int groupingOpFinished:1;
        unsigned int isEditing:1;
        unsigned int groupingAbility:1;
    }_fallViewFlags;
    
    CGSize _size;
	CGSize _highlightedSize;
    
	int _moveId;
	int _handleId;
	int _lastMoveId;
	int _lastHandleId;
	
	CGPoint _lastTouch;
	CGPoint _beginPoint;
    
    float _xLength;
	float _yLength;
	SEL _didVerticalMoveSelector;
	SEL _didHorizontalMoveSelector;

	
	NSTimer *_shakeTask;
	NSTimer *_groupShakeTask;
	
	UIView *_tempV;
	UIView *_tempVInGroup;
	
	UIView *_addedViewFromGroup;
    UIView *_selectedGroup;
	
    NSMutableArray *_rects;
    NSMutableArray *_items;
	NSMutableArray *_pageItems;
	NSMutableArray *_pageRects;
	NSMutableArray *_lastPageItems;
	NSMutableArray *_lastPageRects;
	
    //KLSFallViewDelegate&KLSFallViewDataSource
    id _target;
    id _dataSource;
}

@property (assign,readonly) int pageIndex;
@property (assign,readonly) BOOL isEditing;

/*Methods Belong To KLSFallView
 */
- (void)setHighlightedLapse:(float)t; //default 0.1 and can be change the default value via kKLSFall_HighlightedSeconds. 
- (void)setHighlightedSize:(CGSize)size; //default X1.2 and can be changed the default value via kKLSFall_HighlightedMulti.
- (void)setHighlightedAlpha:(float)alpha; //default 0.5.

- (void)setFallDelegate:(id)tar;
- (void)setFallDataSource:(id)datasource;

- (void)setFallOperation:(BOOL)operation; //set the fall operation so the fall view can ingore the touch event default NO.

- (void)setGroupingAbility:(BOOL)ability; //set the group ability if set NO the fall view will lose the group function default YES

- (void)setRowSpace:(float)space; //default 0.
- (void)setColSpace:(float)space; //default -1. will part via the items.

- (void)setItemSize:(CGSize)size; //default CGSizeZero.

- (void)endEidt; //change the fall to normal mode.
- (void)beginEidt; //change the fall view to edit mode.

- (void)setMaxItemCountPerPage:(int)count; //default 16

- (void)setMarginLeft:(float)value; //default 0
- (void)setMarginTop:(float)value; //default 0

- (void)deleteItemAtIndex:(int)index; //should get the index from the delegate fallView:willDeleteItemAtIndex:
- (void)deleteGroupItemAtIndex:(int)index; //should get the index from the delegate fallView:willDeleteGroupItemAtIndex:

- (void)reload; //will reload all items on the fall view.
- (void)reloadNewItems; //will just reload the new items in the fall view,you should call it when you just add some new items but won't reload all items,it is high performance.

- (void)render; //show the fall view in the view which you added it,should be called when you need prepare to render the fall view.

- (void)setVerticalMove:(float)length selector:(SEL)sel; //verical move a certain length operation, unimportant.
- (void)setHorizontalMove:(float)length selector:(SEL)sel; //horizontal move a certain length operation, unimportant.

@end


@protocol KLSFallViewDelegate <NSObject>

@optional
- (void)fallView:(KLSFallView *)fallView didSelectItemAtIndex:(int)index; //called when you select an item on the fall view
- (void)fallView:(KLSFallView *)fallView didSelectGroupItemAtIndex:(int)index; 
- (void)fallView:(KLSFallView *)fallView willDeleteItemAtIndex:(int)index; //called when you will delete an item on the fall view, you may add a confirm view before you delete it immediately.
- (void)fallView:(KLSFallView *)fallView willDeleteGroupItemAtIndex:(int)index; 
 

@required
- (KLSFallItem *)fallView:(KLSFallView *)fallView eachItemAtIndex:(int)index; //called after you call the [fallview render] you should set some data or custom the item ui in this callback function.

@end

@protocol KLSFallViewDataSource <NSObject>

@required
- (NSInteger)numberOfColsInFallView:(KLSFallView *)fallView; //called after you call the [fallview render] return the item count each row.
- (NSInteger)numberOfItemsInFallView:(KLSFallView *)fallView; //called after you call the [fallview render] return the number of items in the fall view.

@end
