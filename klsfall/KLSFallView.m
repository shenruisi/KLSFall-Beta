//
//  KLSFall.m
//  KLS
//
//  Created by shen yin on 8/25/11.
//  Copyright 2011 Kalos. All rights reserved.
//

#import "KLSFallView.h"


#define kKLSFall_MovingRange 20
#define kKLSFall_HighlightedMulti 1.2
#define kKLSFall_AnimationDuration 0.25f
#define kKLSFall_GroupingSeconds 1
#define kKLSFall_HighlightedSeconds 0.1
#define kKLSGroupView_Inner_Offset_Y 0


@implementation KLSGroupView 

- (id)initWithFrame:(CGRect)frame{
	if (self = [super initWithFrame:frame]) {
		_rects = [[NSMutableArray alloc] init];
		_views = [[NSMutableArray alloc] init];
		self.scrollEnabled = YES;
		self.pagingEnabled = YES;
	}
	return self;
}

- (void)dealloc{
	[_rects release],_rects = nil;
	[_views release],_views = nil;
	[super dealloc];
}

- (CGRect)nextSit{
	int count = [self.subviews count];
	//if has bg should be
	count--;
	CGRect rFrame;
	
	if (count==0) {
		
		rFrame = CGRectMake(_colSpace, 
                            (self.frame.size.height-_size.height)/2+kKLSGroupView_Inner_Offset_Y, 
                            _size.width,
                            _size.height);		
	}
	else {
		
		rFrame = CGRectMake(_size.width*count+_colSpace*(count+1),
                            (self.frame.size.height-_size.height)/2+kKLSGroupView_Inner_Offset_Y,  
                            _size.width, 
                            _size.height);
	}
    
	return rFrame;
}	

- (void)addSubview:(UIView *)view{
	[super addSubview:view];
	
	//touch event will add uiimageview?
	if ([view isKindOfClass:[KLSFallItem class]]) {
		[_rects addObject:[NSValue valueWithCGRect:view.frame]];	
		[_views addObject:view];
		int count = [_rects count];
		[self setContentSize:CGSizeMake(_size.width*count + _colSpace*(count+1), self.bounds.size.height)];
	}
}

- (void)setItemSize:(CGSize)size{

	_size = size;
}

- (void)setColSpace:(double)space{
	_colSpace = space;
}

- (void)setOutItemSelector:(SEL)sel target:(id)tar{
	_outItemSel = sel;
	_tar = tar;
}

- (void)setTouchMoveSelector:(SEL)sel target:(id)tar{
	_touchMoveSel = sel;
	_touchMoveTar = tar;
}

- (void)setTouchEndSelector:(SEL)sel target:(id)tar{
	_touchEndSel = sel;
	_touchEndTar = tar;
}

- (void)setSelectItemSelector:(SEL)sel target:(id)tar{
	_selectItemSel = sel;
	_selectTar = tar;
}

- (KLSFallItem *)itemAtIndex:(int)index{
    return [_views objectAtIndex:index];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	
	UITouch *touch = [touches anyObject];
	
	_beginPoint = [touch locationInView:self];
	
	for (int i = 0; i < [_rects count]; ++i) {
		//找到point所在的rect
		CGRect itemRect;
		NSValue *value = [_rects objectAtIndex:i];
		[value getValue:&itemRect];
		if(CGRectContainsPoint(itemRect, _beginPoint)){
			_handleId = i;


			_handleV = [_views objectAtIndex:_handleId];

			[_handleV setHidden:YES];
			
			if (self.isShaking) {
				if ([_tar respondsToSelector:_outItemSel]) {
					[_tar performSelector:_outItemSel withObject:_handleV];
				}
			}
			else {
				if ([_selectTar respondsToSelector:_selectItemSel]) {
					
					[_handleV setHidden:NO];
					[_selectTar performSelector:_selectItemSel withObject:[NSString stringWithFormat:@"%d",_handleId]];
				}
			}
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	if (!self.isShaking) {
		return;
	}
	
	UITouch *touch = [touches anyObject];
	
	CGPoint point = [touch locationInView:self];
	
	if (_handleId!=-1) {
		
		if (point.x-_lastPoint.x <=0) {
			isLeftMovingTrend = YES;
			
		}
		else if (point.x-_lastPoint.x>0){
			isLeftMovingTrend = NO;
        
		}
		
		_lastPoint = point;
		
		if ([_touchMoveTar respondsToSelector:_touchMoveSel]) {
			[_touchMoveTar performSelector:_touchMoveSel withObject:[NSValue valueWithCGPoint:point]];
		}
        
	}
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if (!self.isShaking) {
		return;
	}
	
	_handleId=-1;
	UITouch *touch = [touches anyObject];
	
	CGPoint point = [touch locationInView:self];
	
	if ([_touchEndTar respondsToSelector:_touchEndSel]) {
		[_touchEndTar performSelector:_touchEndSel withObject:[NSValue valueWithCGPoint:point]];
	}
}

@synthesize isShaking;
@synthesize isLeftMovingTrend;
@end


#pragma mark -
#pragma mark Private Methods
@interface KLSFallView ()

- (void)_overallOpSetAlpha:(double)aAlpha;
- (void)_overallOpSetTransform:(CGAffineTransform)aTansform;

/*
 *分组操作*/
- (void)_showGroupingBanner;
//分组人物 用于协调是否开始分组任务
- (void)_showGroupingBannerTask;
- (void)_addToGrouping;
- (void)_dismissGroupingBanner;


/*
 *分组操作时需要冻结其他操作*/
- (void)_shouldFrozenFall:(BOOL)flag;

/*
 *重置操作*/
- (void)_reset;

/*
 *换页时重置页面资源*/
- (void)_adaptPageRes;

- (void)_startGroupShake;
- (void)_stopGroupShake;

/*
 *得到即将加入fall的位置坐标*/
- (CGRect)_nextSit;

- (void)_cleanSubviews;


- (void)_setAsSingleViewIfNeeded;

- (void)_deleteItemAtIndex:(int)index;

- (void)_innerRender;

- (BOOL)_isShaking;
- (void)_startShake;
- (void)_stopShaking;
- (BOOL)_isGrouping;
- (void)_endGrouping;
- (void)_rearranged;


@end


@implementation KLSFallView

/*
 *该文件中的静态变量，部分用于静态函数*/
bool _is_grouping = false;
bool _is_up_moving_trend = false;
bool _is_left_moving_trend = false;

CFAbsoluteTime _paging_t;
CFAbsoluteTime _grouping_t;
CFAbsoluteTime _highlighted_t;

#pragma mark Static methods declare
static BOOL compareArea(CGRect rect1,CGRect rect2);
static CGRect compareIntersection(CGRect rect1,CGRect rect2);
static bool CGCRectNearEqualCGRect(CGRect rect1,CGRect rect2);
static bool CGPointNearPoint(CGPoint point1,CGPoint point2,double distance);

#pragma mark -
#pragma mark Notifications
- (void)_addNotifications{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noteFallShouldDeleteItem:)
                                                 name:nFall_SHOULD_DELETE_ITEM
                                               object:nil];
}

- (void)_removeNotifications{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:nFall_SHOULD_DELETE_ITEM 
                                                  object:nil];
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        _items = [[NSMutableArray alloc] init];
        _rects = [[NSMutableArray alloc] init];
        
        struct s_flags tmp_flags = {.fallFrozen=0,
            .inGroupingTask=0,
            .fallOperation=0,
            .ignoreTouchByFallFrozen=0,
            .groupingOpFinished=0,
            .isEditing=0,
            .groupingAbility=1};
        
        _fallViewFlags = tmp_flags;
        
        struct s_constants tmp_constants = {.col=0,
            .rowSpace=0,
            .colSpace=-1,
            .highlightedAlpha=0.5,
            .marginTop=0,
            .marginLeft=0,
            .shakeAngle=-1,
            .groupShakeAngle=-1,
            .tElapse=kKLSFall_HighlightedSeconds,
            .maxItemPerPage=16
        };
        
        _fallViewConstants = tmp_constants;
        
        
        _handleId = -1;
        _highlightedSize = CGSizeZero;
        
       
        _grouping_t = CFAbsoluteTimeGetCurrent();
        _paging_t = CFAbsoluteTimeGetCurrent();
        
        pageIndex = 0;
        
        /*scrollview 基本设置*/
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.scrollsToTop = NO;
        self.delegate = self;
        
        [self _addNotifications];
    }
    return self;
}

- (void)dealloc {
	[_items release], _items = nil;
	[_rects release],_rects = nil;
	[self _removeNotifications];
	[super dealloc];
}

- (void)noteFallShouldDeleteItem:(NSNotification *)note{
	
	
	KLSFallItem *file = (KLSFallItem *)[note object];
	int handleId = KLSFallItemIdInvaildId;
	
	NSLog(@"%d -> %@",_handleId, file.bean.uuid);
	
    handleId = [_pageItems indexOfObject:file];
    if (handleId==LONG_MAX) {//delete group item
        
        KLSFallItem *groupFile = [_pageItems objectAtIndex:_moveId];
        
        int removeGroupId = -1;
        
        for (int i = 0;i<[groupFile.bean.subItems count];++i){
            KLSFallItemBean *tempStruct = [groupFile.bean.subItems objectAtIndex:i];
            if([((KLSFallItem *)file).bean.uuid isEqualToString:tempStruct.uuid]){
                removeGroupId = i;
                break;
            }
        }
        
        [_target fallView:self willDeleteGroupItemAtIndex:removeGroupId];
    }
    else{ //delete item in fall view
       [_target fallView:self willDeleteItemAtIndex:handleId]; 
    }
	
}

- (void)deleteGroupItemAtIndex:(int)index{

    KLSFallItem *item = [_groupingV itemAtIndex:index];
    [item removeFromSuperview];
    
    KLSFallItem *groupFile = [_pageItems objectAtIndex:_moveId];
    
    [groupFile.bean.subItems removeObjectAtIndex:index];
    
    if ([groupFile.bean hasSubItems]) {
        [groupFile becomeGroup];
    }
    else{
        [groupFile becomeSingle];
    }
    
    
    
    if (![groupFile.bean hasSubItems]) {
//        handleId = _moveId;
        goto NONE_GROUP_LOOP;
    }
    else {
        return;
    }
    
NONE_GROUP_LOOP: if ([self _isGrouping]) {
                    [self _shouldFrozenFall:NO];
                    [self _dismissGroupingBanner];
    }
}

- (void)deleteItemAtIndex:(int)index{

    int handleId = index;
	
//    if ([self _isGrouping]) {
//        [self _shouldFrozenFall:NO];
//        [self _dismissGroupingBanner];
//   } 
    
	for (int i = handleId; i < [_pageItems count]-1; ++i) {
		[_pageItems exchangeObjectAtIndex:i withObjectAtIndex:i+1];
		UIView *view = [_pageItems objectAtIndex:i];
		CGRect itemRect;
		NSValue *value = [_pageRects objectAtIndex:i];
		[value getValue:&itemRect];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:kKLSFall_AnimationDuration];
		[view setFrame:itemRect];
		[UIView commitAnimations];
	}
	
	
	[self _deleteItemAtIndex:[_pageItems count]-1];
	[self _rearranged];
    
}

#pragma mark -
#pragma mark UIScrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)sender {
	CGPoint didScrollPoint = sender.contentOffset;
	int x = (int)(didScrollPoint.x);
	int y = (int)(self.bounds.size.width);
	
	if (x%y==0) {
		pageIndex = x/y;
		
		if (_handleId==-1) {
			[self _adaptPageRes];
			[self _shouldFrozenFall:NO];
		}
	}
}

#pragma mark -
#pragma mark Fall touch methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	_beginPoint = [touch locationInView:self];
    NSLog(@"touch begin %@", NSStringFromCGPoint(_beginPoint));
	
	//记录下当前选中item的id，以便在拖动的时候对其frame进行重置
	
	for (int i = 0; i < [_pageRects count]; ++i) {
		CGRect itemRect;
		NSValue *value = [_pageRects objectAtIndex:i];
		[value getValue:&itemRect];
		if(CGRectContainsPoint(itemRect, _beginPoint)){
			/*
			 *当确认handle id 时将moveId置为-1不影响操作
			 *并记录下lastTouch 当长按超过指定时间时激发
			 */
			int tarId;
			if ([self _isShaking]) {
				tarId = _moveId;
			}
			else {
				tarId = _handleId;
			}
			
			if (_fallViewFlags.fallFrozen && i!=tarId) {  //点击进入分组显示，Fall中其他元素操作冻结
                _fallViewFlags.ignoreTouchByFallFrozen = 1;
				break;
			}
			else if (_fallViewFlags.fallFrozen && i==tarId){
				_fallViewFlags.ignoreTouchByFallFrozen = 0;
				break;
			}
			
			else{
				if (_fallViewFlags.fallOperation) {
					_highlighted_t = CFAbsoluteTimeGetCurrent();
					NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:i],@"HANDLE_ID",
                                              [NSValue valueWithCGPoint:_beginPoint],@"LAST_POINT",nil];
					
					//shaking 点击grouping 未进入高亮阶段 应该显示grouping banner 
					
					NSLog(@"oh here is the point %d",i);
					
					KLSFallItem *file = [_pageItems objectAtIndex:i];
					if ([file.bean hasSubItems]) {
						_moveId = i;
						//_handleId置为-2，保证可以进入touchEnd
						_handleId = -2;
					}
					else {
						_handleId = -1;
					}
					
					NSLog(@"should perform delay fuc _highlightedHandleView:");
					[self performSelector:@selector(_highlightedHandleView:) 
                               withObject:userInfo 
                               afterDelay:0.5];
				}
				else {
                    _handleId = i;
				}
			}
			
			break;
		}
	}	
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
	NSLog(@"enter touchesMoved %d",_handleId);
    //self.userInteractionEnabled = NO;
	
	UITouch *touch = [touches anyObject];
	
	
	CGPoint point = [touch locationInView:self];
    
	
	if (_fallViewFlags.fallFrozen==0
        &&_fallViewFlags.fallOperation) {
		//没有选择任何handle view 不做任何操作
		if (_handleId == -1||_handleId==-2) {
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			
			return;
		}
		
		KLSFallItem *handleV = [_pageItems objectAtIndex:_handleId];
		
		[self bringSubviewToFront:handleV];
		
		[handleV setCenter:point];
		
		if (handleV.frame.origin.y+handleV.frame.size.height >= self.bounds.size.height
            && handleV.frame.origin.y+handleV.frame.size.height <= self.contentSize.height) {
			[self scrollRectToVisible:CGRectMake(0, 
                                                 handleV.frame.origin.y+handleV.frame.size.height, 
                                                 _size.width,
                                                 _size.height) 
                             animated:YES];
		}
		else if (handleV.frame.origin.y<=self.contentOffset.y){
			[self scrollRectToVisible:CGRectMake(0, 
                                                 handleV.frame.origin.y-handleV.frame.size.height, 
                                                 _size.width,
                                                 _size.height) 
                             animated:YES];
		}
		
		
		if (point.x-_lastTouch.x <=0) {
			_is_left_moving_trend = true;
		}
		else if (point.x-_lastTouch.x>0){
			_is_left_moving_trend = false;
		}
		else if (point.y-_lastTouch.y<=0){
			_is_up_moving_trend = true;
		}
		else if (point.y-_lastTouch.y>0){
			_is_up_moving_trend = false;
		}
		
		
		
		_lastTouch =  point;
		//找到KLSFall中所有与当前handle view中有重叠的，
		//并计算出面积最大的，得到其id，最后moveid与handleid相等
		CGRect largestIntersection = CGRectZero;
		
		//与rects数组比较
		for (int i = 0; i < [_pageRects count]; ++i) {
			
			if (i==_handleId) {
                
				continue;
			}
			
			//NSLog(@"move handle id :%d",_handleId);
        
			CGRect itemRect;
			NSValue *value = [_pageRects objectAtIndex:i];
			[value getValue:&itemRect];
//                CGRect handleR = handleV.frame;
			//当交集不为空时
			CGRect tmpIntersection = compareIntersection(handleV.frame, itemRect);
			
			if(!CGRectEqualToRect(tmpIntersection, CGRectZero)){
				
				if(compareArea(tmpIntersection, largestIntersection)){
					largestIntersection = tmpIntersection;
					_moveId = i;
					NSLog(@"move id %d",_moveId);
				}
				
			}
		}
		
		if (_is_grouping
            &&![handleV.bean hasSubItems]
#if KLSFall_NetworkDL
            &&handleV.bean.downloadComplete
            &&((KLSFallItem *)[_pageItems objectAtIndex:_moveId]).bean.downloadComplete
#endif
            &&_fallViewFlags.groupingAbility
            ) {
			
			[self _showGroupingBannerTask];
			return;
		}
		
		_grouping_t = CFAbsoluteTimeGetCurrent();
		[self _dismissGroupingBanner];
		
		//处理移动效果
		//[*,*,move->handle,*]
		if (_handleId > _moveId && _moveId!=-1 && _is_left_moving_trend) { //向handle view移动
			NSLog(@"move->handle");
			[NSObject cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(_showGroupingBanner) 
                                                       object:nil];
			while (_handleId!=_moveId) {
				
				[_pageItems exchangeObjectAtIndex:_handleId withObjectAtIndex:_handleId-1];
				UIView *view = [_pageItems objectAtIndex:_handleId];
				CGRect itemRect;
				NSValue *value = [_pageRects objectAtIndex:_handleId];
				[value getValue:&itemRect];
				[UIView beginAnimations:nil context:nil];
				[UIView setAnimationDuration:kKLSFall_AnimationDuration];
				[view setFrame:itemRect];
				[UIView commitAnimations];
				_handleId--;
			}
			
			
		}
		//[*,*,handle<-move,*]
		else if (_handleId < _moveId && _moveId!=-1 && !_is_left_moving_trend){
			[NSObject cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(_showGroupingBanner) 
                                                       object:nil];
			
			while (_handleId!=_moveId) {
				[_pageItems exchangeObjectAtIndex:_handleId withObjectAtIndex:_handleId+1];
				UIView *view = [_pageItems objectAtIndex:_handleId];
				CGRect itemRect;
				NSValue *value = [_pageRects objectAtIndex:_handleId];
				[value getValue:&itemRect];
				[UIView beginAnimations:nil context:nil];
				[UIView setAnimationDuration:kKLSFall_AnimationDuration];
				[view setFrame:itemRect];
				[UIView commitAnimations];
				_handleId++;
			}
		}
		else{
			_grouping_t = CFAbsoluteTimeGetCurrent();
			[self _dismissGroupingBanner];

			if (point.x > self.bounds.size.width*(pageIndex+1) - _size.width/2.0
                &&!_is_left_moving_trend
                &&(CFAbsoluteTimeGetCurrent()-_paging_t>1)) {
				
				_paging_t = CFAbsoluteTimeGetCurrent();
				if (pageIndex+1<[_items count]) {
					NSLog(@"i see point should begin move right%.2f",point.x);
					
					//调整上一页
					for (int i = _handleId; i < [_pageItems count]-1; ++i) {
						[_pageItems exchangeObjectAtIndex:i withObjectAtIndex:i+1];
						UIView *view = [_pageItems objectAtIndex:i];
						CGRect itemRect;
						NSValue *value = [_pageRects objectAtIndex:i];
						[value getValue:&itemRect];
						[UIView beginAnimations:nil context:nil];
						[UIView setAnimationDuration:kKLSFall_AnimationDuration];
						[view setFrame:itemRect];
						[UIView commitAnimations];
					}
					
					_lastPageItems = _pageItems;
					_lastPageRects = _pageRects;
					NSValue *lastRect = [[_lastPageRects objectAtIndex:[_lastPageRects count]-1] retain];
					
					
					pageIndex +=1;
					
					KLSFallItem *removeV = [_pageItems objectAtIndex:[_pageItems count]-1];
					//[removeV removeFromSuperview];
					[_pageItems removeObjectAtIndex:[_pageItems count]-1];
					[_pageRects removeObjectAtIndex:[_pageRects count]-1];
					
					[self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
					[self _adaptPageRes];
					
					_handleId = [_pageItems count];
					
					
					if (_handleId == _fallViewConstants.maxItemPerPage) {
						//如果目标页满了 将目标页最后元素添加至发起页
						UIView *tarPageView = [_pageItems objectAtIndex:[_pageItems count]-1];
						[_lastPageItems addObject:tarPageView];
						[_lastPageRects addObject:lastRect];
						[UIView beginAnimations:nil context:nil];
						[UIView setAnimationDuration:0.3f];
						CGRect itemRect;
						[lastRect getValue:&itemRect];
						
						tarPageView.frame = itemRect;
						
						[UIView commitAnimations];
                        
						[_pageItems replaceObjectAtIndex:[_pageItems count]-1 withObject:removeV];
						_handleId = [_pageItems count]-1;
					}
					else {
						[_pageRects addObject:[NSValue valueWithCGRect:[self _nextSit]]];
						[_pageItems addObject:removeV];
						//fix memory 20111205
						[lastRect release];
					}
                    
					
					NSLog(@"%@",NSStringFromCGRect(removeV.frame));
					//[addV release];
					[self addSubview:removeV];
				}	
			}
			else if (point.x < self.bounds.size.width*pageIndex+ _size.width/2.0
                     &&_is_left_moving_trend
                     &&(CFAbsoluteTimeGetCurrent()-_paging_t>1)){
				
				_paging_t = CFAbsoluteTimeGetCurrent();
				if (pageIndex-1>=0) {
					NSLog(@"i see point should begin move left%.2f",point.x);
					pageIndex -=1;
					
					for (int i = _handleId; i < [_pageItems count]-1; ++i) {
						[_pageItems exchangeObjectAtIndex:i withObjectAtIndex:i+1];
						UIView *view = [_pageItems objectAtIndex:i];
						CGRect itemRect;
						NSValue *value = [_pageRects objectAtIndex:i];
						[value getValue:&itemRect];
						[UIView beginAnimations:nil context:nil];
						[UIView setAnimationDuration:kKLSFall_AnimationDuration];
						[view setFrame:itemRect];
						[UIView commitAnimations];
					}
					
					_lastPageItems = _pageItems;
					_lastPageRects = _pageRects;
					NSValue *lastRect = [[_lastPageRects objectAtIndex:[_lastPageRects count]-1] retain];
					
					KLSFallItem *removeV = [_pageItems objectAtIndex:[_pageItems count]-1];
					
					[_pageItems removeObjectAtIndex:[_pageItems count]-1];
					[_pageRects removeObjectAtIndex:[_pageRects count]-1];
					
					[self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
					[self _adaptPageRes];
					
					_handleId = [_pageItems count];
					
					if (_handleId == _fallViewConstants.maxItemPerPage) {
						//如果目标页满了 将目标页最后元素添加至发起页
						UIView *tarPageView = [_pageItems objectAtIndex:[_pageItems count]-1];
						[_lastPageItems addObject:tarPageView];
						[_lastPageRects addObject:lastRect];
						[UIView beginAnimations:nil context:nil];
						[UIView setAnimationDuration:0.3f];
						CGRect itemRect;
						[lastRect getValue:&itemRect];
						
						tarPageView.frame = itemRect;
						
						[UIView commitAnimations];
						
						[_pageItems replaceObjectAtIndex:[_pageItems count]-1 withObject:removeV];
						_handleId = [_pageItems count]-1;
					}
					else {
						[_pageRects addObject:[NSValue valueWithCGRect:[self _nextSit]]];
						[_pageItems addObject:removeV];
						//fix memory 20111205
						[lastRect release];
					}
					
					
					NSLog(@"%@",NSStringFromCGRect(removeV.frame));
					//[addV release];
					[self addSubview:removeV];
				}
			}
			
		}
	}
	else if(_fallViewFlags.fallFrozen==0
            &&_fallViewFlags.fallOperation==0){ //addional function
		
		if (_beginPoint.y - point.y >= _yLength) {
			if (_target&&_didVerticalMoveSelector) {
				[_target performSelector:_didVerticalMoveSelector withObject:@"up"];
			}
		}
		else if (point.y - _beginPoint.y >= _yLength){
			if (_target&&_didVerticalMoveSelector) {
				[_target performSelector:_didVerticalMoveSelector withObject:@"down"];
			}
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	NSLog(@"enter touchesEnded: %d, %d", _handleId, _fallViewFlags.fallOperation);
    
	/*
	 *自动调整放开后的rect
	 */
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	
	if (_handleId==-1) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		
		return;
	}
	
	if (_fallViewFlags.fallOperation) {
		
		if (_handleId == -2) {
			
			if (_fallViewFlags.ignoreTouchByFallFrozen==0) {
				KLSFallItem *handleV = [_pageItems objectAtIndex:_moveId];
				if (handleV.bean.hasSubItems) {
					
					if ([self _isGrouping]) {
						if(handleV.alpha != 0.5){//还未进入高亮阶段
							[NSObject cancelPreviousPerformRequestsWithTarget:self];
							[self _shouldFrozenFall:NO];
							[self _dismissGroupingBanner];
						} 
					}
					else {
						if(handleV.alpha != 0.5){//还未进入高亮阶段
							[NSObject cancelPreviousPerformRequestsWithTarget:self];
							[self _shouldFrozenFall:YES];
							[self _showGroupingBanner];
							
						} 
					}
				}
			}
		}
		else {
			if (_fallViewFlags.inGroupingTask) {
				[self _addToGrouping];
			}
			else {
				
				KLSFallItem *handleV;
				
				handleV = [_pageItems objectAtIndex:_handleId];
				handleV.transform = CGAffineTransformMakeScale(1, 1);
				CGRect itemRect;
				NSValue *value = [_pageRects objectAtIndex:_handleId];
				[value getValue:&itemRect];
				
				[UIView beginAnimations:nil context:nil];
				[UIView setAnimationDuration:kKLSFall_AnimationDuration];
				[handleV setFrame:itemRect];
				handleV.alpha = 1;
				[UIView commitAnimations];
				
				[self _dismissGroupingBanner];
				[self _reset];
				
			}
		}
	}
	else{
		if (_handleId!=-1 
            &&CGPointNearPoint(_beginPoint, point,10)
            &&_fallViewFlags.ignoreTouchByFallFrozen==0) {
			KLSFallItem *item;
			if ([self _isShaking]) {
				//item = [_items objectAtIndex:_moveId];
				[self _stopShaking];
				[self _stopGroupShake];
				[self setFallOperation:NO];
				[self _endGrouping];
//				if ([_target respondsToSelector:_didEndGroupSelector]) {
//					[_target performSelector:_didEndGroupSelector];
//				}
			}
			else {
				item = [_pageItems objectAtIndex:_handleId];
				if (item.bean.hasSubItems
                    ) {  
					[self _showGroupingBanner];
				}
				else{
                    if ([_target respondsToSelector:@selector(fallView:didSelectItemAtIndex:)]) {
                        [_target fallView:self didSelectItemAtIndex:_handleId];
                    }
					_handleId = -1;
				}
			}
		}
	}
}


#pragma mark -
#pragma mark Public methods
- (void)setHighlightedLapse:(float)t
{
    _fallViewConstants.tElapse = t;
}

- (void)setHighlightedSize:(CGSize)size{
	_highlightedSize = size;
}

- (void)setHighlightedAlpha:(float)alpha{
    _fallViewConstants.highlightedAlpha = alpha;
}

- (void)setItemSize:(CGSize)size{
    int sizeWidth = size.width*kKLSFallItemRealScale;
    int sizeHeight = size.height*kKLSFallItemRealScale;
	_size = CGSizeMake(sizeWidth, sizeHeight);
	//如果highlightedSize没有设置，将在setItemSize中默认设置
	_highlightedSize = CGSizeMake(_size.width*kKLSFall_HighlightedMulti,
								  _size.height*kKLSFall_HighlightedMulti);
}

- (void)setRowSpace:(float)space{
    _fallViewConstants.rowSpace = space;
}

- (void)setColSpace:(float)space{
    _fallViewConstants.colSpace = space;
}

- (void)setFallOperation:(BOOL)operation{
	_fallViewFlags.fallOperation = operation?1:0;
}

- (void)setGroupingAbility:(BOOL)ability{
    _fallViewFlags.groupingAbility = ability?1:0;
}


- (void)setVerticalMove:(float)length selector:(SEL)sel{
	_didVerticalMoveSelector = sel;
	_yLength = length;
}


- (void)setHorizontalMove:(float)length selector:(SEL)sel{
	_didHorizontalMoveSelector = sel;
	_xLength = length;
}

- (void)setMaxItemCountPerPage:(int)count{
	_fallViewConstants.maxItemPerPage = count;
}

- (void)setMarginLeft:(float)value{
    _fallViewConstants.marginLeft = value;
}

- (void)setMarginTop:(float)value{
    _fallViewConstants.marginTop = value;
}

- (void)setFallDelegate:(id)tar{
	_target = tar;
}

- (void)setFallDataSource:(id)datasource{
    _dataSource = datasource;
}

- (BOOL)isEditing{
    BOOL ret;
    ret = _fallViewFlags.isEditing==1?YES:NO;
    return ret;
}


- (void)addItem:(id)item animation:(BOOL)animation{
	
	if ([[_items lastObject] count]>= _fallViewConstants.maxItemPerPage
        ||[_items count]==0) {
		NSMutableArray *newPageItems = [[NSMutableArray alloc] init];
		[newPageItems addObject:item];
		[_items addObject:newPageItems];
		[newPageItems release];
        
        NSMutableArray *newPageRects = [[NSMutableArray alloc] init];
		
        double pageOffset = self.bounds.size.width*([_items count]-1);
        
        int j = [newPageItems count]-1;
        
        CGRect itemRect = CGRectMake(_fallViewConstants.marginLeft+pageOffset+j%_fallViewConstants.col*(_size.width+_fallViewConstants.colSpace),
                                      _fallViewConstants.marginTop+j/_fallViewConstants.col*(_size.height+_fallViewConstants.rowSpace),
                                      _size.width,
                                      _size.height);
        [item setFrame:itemRect];
         
         
        [newPageRects addObject:[NSValue valueWithCGRect:itemRect]];
        
        [_rects addObject:newPageRects];
        [newPageRects release];

         
	}
	else {
		[[_items lastObject] addObject:item];
        
        double pageOffset = self.bounds.size.width*([_items count]-1);
        
        int j = [[_items lastObject] count]-1;
        
        CGRect itemRect = CGRectMake(_fallViewConstants.marginLeft+pageOffset+j%_fallViewConstants.col*(_size.width+_fallViewConstants.colSpace),
                                     _fallViewConstants.marginTop+j/_fallViewConstants.col*(_size.height+_fallViewConstants.rowSpace),
                                     _size.width,
                                     _size.height);
        
        [item setFrame:itemRect];
        
        [[_rects lastObject] addObject:[NSValue valueWithCGRect:itemRect]];
	}
	
	
    if (animation) {
        pageIndex = [_items count]-1;
        [self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
    }
}

- (int)_totalItemsCount{
    
    int totalCount = 0;
    
    for (int i = 0; i < [_items count]; ++i) {
        NSMutableArray *itemsInPage = [_items objectAtIndex:i];
        totalCount += [itemsInPage count];
    }
    
    return totalCount;
}

- (void)render{
    [self _cleanSubviews];
	[_rects removeAllObjects];
    [_items removeAllObjects];
    
    _fallViewConstants.col = [_dataSource numberOfColsInFallView:self];
    
    if (_fallViewConstants.col == 1) 
		_fallViewConstants.colSpace = 0;
	else if (_fallViewConstants.colSpace==-1){
		_fallViewConstants.colSpace = (self.bounds.size.width - _fallViewConstants.marginLeft*2-_fallViewConstants.col*_size.width)/(_fallViewConstants.col-1);
	}
    
    int count = 0;
    if ([_dataSource respondsToSelector:@selector(numberOfItemsInFallView:)]) {
        count = [_dataSource numberOfItemsInFallView:self];
    }
    
    if (![_target respondsToSelector:@selector(fallView:eachItemAtIndex:)]) {
        count = 0;
    }
    
    for (int i = 0; i < count; ++i) {
        
        KLSFallItem *item = [_target fallView:self eachItemAtIndex:i];
        
        [self addItem:item animation:NO];
    }
    
    [self _innerRender];
}

- (void)_reloadItemAtIndex:(int)index{
    KLSFallItem *item = [_target fallView:self eachItemAtIndex:index];
    [self addItem:item animation:YES];
    
    [self addSubview:item];
    
    [self setContentSize:CGSizeMake(self.bounds.size.width*[_items count],
                                    self.bounds.size.height)];
}

- (void)reloadNewItems{
    
    int totalCount = [self _totalItemsCount];
    
    int newTotalCount = [_dataSource numberOfItemsInFallView:self];
    
    //新加入的item数
    while (totalCount<newTotalCount) {
        [self _reloadItemAtIndex:totalCount];
        totalCount++;
    }
}

- (void)reload{
    [self render];
}

- (void)_innerRender{
    
	for (int i = 0; i < [_items count]; ++i) {
		NSMutableArray *tempPageItems = [_items objectAtIndex:i];
//		NSMutableArray *pageRects = [_rects objectAtIndex:i];
		
		for (int j = 0; j < [tempPageItems count]; ++j) {
			KLSFallItem *item = [tempPageItems objectAtIndex:j];
            
//            NSValue *rectValue = [pageRects objectAtIndex:j];
//            CGRect rect;
//            [rectValue getValue:&rect];
			
//			double pageOffset = self.bounds.size.width*i;
//			
//			CGRect itemRect = CGRectMake(marginLeft+pageOffset+j%_col*(_size.width+_colSpace),
//                                         marginTop+j/_col*(_size.height+_rowSpace),
//                                         _size.width,
//                                         _size.height);
            
            
//			[item setFrame:rect];
			
//			[pageRects addObject:[NSValue valueWithCGRect:itemRect]];
			
            
			if ([item.bean hasSubItems]&&_fallViewFlags.groupingAbility) {
                [item becomeGroup];
            }
			
			[self addSubview:item];
		}
		
//		[_rects addObject:pageRects];
//		[pageRects release];
	}
	[self _adaptPageRes];
	
	[self setContentSize:CGSizeMake(self.bounds.size.width*[_items count],
                                    self.bounds.size.height)];
}

- (void)_stopShaking{
	[_shakeTask invalidate],_shakeTask = nil;
	//[self _overallOpSetAlpha:1];
	[self _stopGroupShake];
	[self _overallOpSetTransform:CGAffineTransformIdentity];
}

- (void)_startShake{
	//[self _overallOpSetAlpha:0.5];
    
	[self setFallOperation:YES];
    
    
    _shakeTask = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                  target:self 
                                                selector:@selector(_shakeByInterval) 
                                                userInfo:nil 
                                                 repeats:YES];
    
    
	
	
	if ([self _isGrouping]) {
		[self _startGroupShake];
		_moveId = _handleId;
		_handleId = -2;
	}
}

- (CGRect)_nextSit{
	int count = [_pageItems count];
	
	CGRect rFrame;
	double pageOffset = self.bounds.size.width*pageIndex;
	if (count==0) {
		rFrame = CGRectMake(_fallViewConstants.marginLeft+pageOffset,
                            _fallViewConstants.marginTop,
                            _size.width,
                            _size.height);
	}
	else {
		rFrame = CGRectMake(_fallViewConstants.marginLeft+pageOffset+count%_fallViewConstants.col*(_size.width+_fallViewConstants.colSpace),
                            _fallViewConstants.marginTop+count/_fallViewConstants.col*(_size.height+_fallViewConstants.rowSpace),
                            _size.width,
                            _size.height);
	}
	
	return rFrame;
}

- (BOOL)_isShaking{
	BOOL temp;
	return temp = _shakeTask==nil?NO:YES;
}

- (void)_rearranged{
//	NSMutableArray *newItems = [[NSMutableArray alloc] initWithCapacity:[_items count]];
//	
//	for (int i = 0; i < [_items count]; ++i) {
//		NSMutableArray *tempPageItems = [_items objectAtIndex:i];
//		
//		if ([tempPageItems count]>0) {
//			[newItems addObject:tempPageItems];
//		}
//	}
//	
//	
//	
//	_items = newItems;
//	[newItems release];
//	pageIndex = 0;
	[self _innerRender];
}

#pragma mark -
#pragma mark Private methods
- (void)_cleanSubviews{
	for (int i = 0; i < [self.subviews count]; ++i) {
		
		UIView *view = [self.subviews objectAtIndex:i];
		
		if (![view isKindOfClass:[KLSGroupView class]]) {
			//group view should be removed
			[view removeFromSuperview];
		}
	}
}

- (void)_adaptPageRes{
	
	if ([_items count]==0) {
		_pageItems = nil;
		_pageRects = nil;
		return;
	}
	
	_pageItems = [_items objectAtIndex:pageIndex];
	_pageRects = [_rects objectAtIndex:pageIndex];
	_handleId = -1;
	_moveId = -1;
}

- (void)_startGroupShake{
	_groupShakeTask = [NSTimer scheduledTimerWithTimeInterval:0.1 
                                                       target:self 
                                                     selector:@selector(_groupShakeByInterval) 
                                                     userInfo:nil 
                                                      repeats:YES];
	_groupingV.isShaking = YES;
}

- (void)_overallOpSetAlpha:(double)aAlpha{
	for (int i = 0; i < [_pageItems count]; ++i) {
		UIView *view = [_pageItems objectAtIndex:i];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3f];
		view.alpha = aAlpha;
		[UIView commitAnimations];
	}
} 

- (void)_overallOpSetTransform:(CGAffineTransform)aTansform{
	
	for (int i = 0; i < [_items count]; ++i) {
		NSMutableArray *tempPageItems = [_items objectAtIndex:i];
		for (int i = 0; i < [tempPageItems count]; ++i) {
			KLSFallItem *view = [tempPageItems objectAtIndex:i];
			[view hiddenDeleteButton];
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:0.3f];
			view.transform = aTansform;
			[UIView commitAnimations];
		}
	}
} 

- (void)_stopGroupShake{
	[_groupShakeTask invalidate],_groupShakeTask = nil;
	_groupingV.isShaking = NO;
}

- (BOOL)_isGroupShaking{
	BOOL temp;
	return temp = _groupShakeTask==nil?NO:YES;
}

- (void)_groupShakeByInterval{
    _fallViewConstants.groupShakeAngle = _fallViewConstants.groupShakeAngle==-1?1:-1;
	for (id item in _groupingV.subviews) {
		
		if ([item isKindOfClass:[KLSFallItem class]]) {
			[UIView beginAnimations:nil context:nil];
			KLSFallItem *file = (KLSFallItem *)item;
			[file showDeleteButton];
			file.transform = CGAffineTransformIdentity;
			CGAffineTransform newTransform;
			
			newTransform = CGAffineTransformMakeRotation((CGFloat)(_fallViewConstants.groupShakeAngle * M_PI / 180.0));
			file.transform = newTransform;
			[UIView commitAnimations];
		}
	}
}

- (void)_shakeByInterval{
    //fix 晃动速率不齐
	_fallViewConstants.shakeAngle = _fallViewConstants.shakeAngle==-1?1:-1;
	for (int i = 0; i < [_items count]; ++i) {
		NSMutableArray *tempPageItems = [_items objectAtIndex:i];
		for (int j = 0; j < [tempPageItems count]; ++j) {
			
			KLSFallItem *view = [tempPageItems objectAtIndex:j];
			[UIView beginAnimations:nil context:nil];
			
			if (j==_handleId) {
				continue;
			}
			//[UIView setAnimationDuration:0.1f];
			[view showDeleteButton];
			view.transform = CGAffineTransformIdentity;
			CGAffineTransform newTransform;
			
			newTransform = CGAffineTransformMakeRotation((CGFloat)(_fallViewConstants.shakeAngle * M_PI / 180.0));
			view.transform = newTransform;
			[UIView commitAnimations];
		}
	}
}

#pragma mark -
#pragma mark Private methods-Highlighted handle view
- (void)_highlightedHandleView:(NSDictionary *)userInfo{
	
	NSDictionary *myUserInfo = [userInfo retain];
	int handleId = [[myUserInfo objectForKey:@"HANDLE_ID"] intValue];
	NSValue *value = [myUserInfo objectForKey:@"LAST_POINT"];
	CGPoint lastPoint;
	[value getValue:&lastPoint];
	
	[UIView beginAnimations:nil context:nil];
	
	UIView *item = [_pageItems objectAtIndex:handleId];
	
	item.transform = CGAffineTransformMakeScale(1.25, 1.25);
	
	item.alpha = _fallViewConstants.highlightedAlpha;
	
	[UIView commitAnimations];
	
	_handleId = handleId;
	_moveId = -1;
	_lastTouch = lastPoint;
	
	[self setScrollEnabled:NO];
}


- (void)_reset{
	_handleId = -1;
	_moveId = -1;
	_fallViewFlags.fallFrozen = 0;
	_is_grouping = false;
	[self setScrollEnabled:YES];
}


#pragma mark -
#pragma mark Private methods - Grouping task
- (void)_setAsGroupView:(UIView *)view{
	KLSFallItem *groupFile = (KLSFallItem *)view;
	if ([groupFile.bean hasSubItems]) {
		for (int i = 0; i < [groupFile.bean.subItems count]; ++i) {
			KLSFallItemBean *addedFileStruct = [groupFile.bean.subItems objectAtIndex:i];
			KLSFallItem *file = [[KLSFallItem alloc] initWithFrame:[_groupingV nextSit]];
			file.bean = addedFileStruct;
			[_groupingV addSubview:file];
			[file release];
            
            [groupFile becomeGroup];
		}		
	}
	else {
		groupFile.bean.subItems = [[NSMutableArray alloc] init];
		
		KLSFallItem *file1 = [[KLSFallItem alloc] initWithFrame:[_groupingV nextSit]];
        
        CGRect rect = [_groupingV nextSit];
        NSLog(@"the grouping rect %@",NSStringFromCGRect(rect));
        
		file1.bean = groupFile.bean;
        
		[groupFile.bean.subItems addObject:file1.bean];
		[_groupingV addSubview:file1];
		[file1 release];
        
        [groupFile becomeGroup];
	}
}

- (void)_addHandleViewToGroup:(UIView *)groupV{
	KLSFallItem *groupFile = (KLSFallItem *)groupV;
	KLSFallItem *addFile = [_pageItems objectAtIndex:_handleId];
	
    CGRect rect = [_groupingV nextSit];
	KLSFallItem *file = [[KLSFallItem alloc] initWithFrame:rect];
	
	file.bean = addFile.bean;
	[groupFile.bean.subItems addObject:file.bean];
	[_groupingV addSubview:file];
	
	[file release];
	
    [groupFile becomeGroup];
	
	[self setFallOperation:NO];
	[self _shouldFrozenFall:YES];
}

- (void)_deleteItemAtIndex:(int)index{
	UIView *view = [_pageItems objectAtIndex:index];
	[view removeFromSuperview];
	
	[_pageItems removeObjectAtIndex:index];
	[_pageRects removeObjectAtIndex:index];
}

- (void)_showGroupingBannerTask{
	
	CFAbsoluteTime cur_t = CFAbsoluteTimeGetCurrent();
	double diff_t = cur_t - _grouping_t;
	NSLog(@"diff time %.5f",diff_t);
	if (diff_t > kKLSFall_GroupingSeconds) {
		NSLog(@"is grouping");
		[self _showGroupingBanner];
	}
	else {
		NSLog(@"enter watting time");
		//如果没有移动，计算到达停留时间后激发grouping banner
		[NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(_showGroupingBanner) 
                                                   object:nil];
		
		[self performSelector:@selector(_showGroupingBanner) 
                   withObject:nil
                   afterDelay:(kKLSFall_GroupingSeconds-diff_t)];
		//NSLog(@"%.5f",kKLSFall_GroupingSeconds-diff_t);
	}	
}

- (void)_outItemFromGroupingView:(UIView *)view{
	KLSFallItem *file = (KLSFallItem *)view;
	
	_tempVInGroup = file;
	
	CGRect frame = file.frame;
	frame.origin.y += _groupingV.frame.origin.y+kKLSGroupView_Inner_Offset_Y;
	frame.origin.x -= _groupingV.contentOffset.x;
	
	KLSFallItem *newFile = [[KLSFallItem alloc] initWithFrame:frame];
	//newFile.backgroundColor = [UIColor blackColor];
	newFile.bean = file.bean;
	
	[UIView beginAnimations:nil context:nil];
	
	newFile.transform = CGAffineTransformMakeScale(1.25, 1.25);
	
	newFile.alpha = _fallViewConstants.highlightedAlpha;
	
	[UIView commitAnimations];
	
	[self addSubview:newFile];
	[newFile release];
    
	//从grouping view中取出 新加view
	_tempV = newFile;
	
	self.scrollEnabled =  NO;
	_groupingV.scrollEnabled = NO;
    //	_handleId = -2;
}

- (void)_touchMoveInGroupingView:(NSValue *)pointValue{
	CGPoint point;
	[pointValue getValue:&point];
	NSLog(@"point in grouping view x=%.2f,y=%.2f",point.x,point.y);
	
	point.y += _groupingV.frame.origin.y;
	point.x -= _groupingV.contentOffset.x;
    
	
	NSLog(@"point in Fall view x=%.2f,y=%.2f",point.x,point.y);
	[_tempV setCenter:point];
	
	if (point.x > self.bounds.size.width*(pageIndex+1) - _size.width/2.0
        &&!_groupingV.isLeftMovingTrend){
		if (pageIndex+1<[_items count]) {
			NSLog(@"i see point should begin move right%.2f",point.x);
			
            
			pageIndex +=1;
			
			_lastPageItems = _pageItems;
			_lastPageRects = _pageRects;
			if (_handleId==-2) {
				_lastHandleId = _handleId;
				_lastMoveId = _moveId;
			}
			else {
				_lastHandleId = _handleId;
			}
            
			
			
			int removeGroupId = -1;
			KLSFallItem *groupFile = [_pageItems objectAtIndex:_moveId];
            _selectedGroup = groupFile;
			for (int i = 0;i<[groupFile.bean.subItems count];++i){
				KLSFallItemBean *tempStruct = [groupFile.bean.subItems objectAtIndex:i];
				if([((KLSFallItem *)_tempV).bean.uuid isEqualToString:tempStruct.uuid]){
					removeGroupId = i;
					break;
				}
			}
			
			[groupFile.bean.subItems removeObjectAtIndex:removeGroupId];
			
			if ([groupFile.bean.subItems count]==0) {
				groupFile.bean.subItems = NO;
				
				groupFile.bean = ((KLSFallItem *)_tempV).bean;
				[groupFile removeFromSuperview];
				//[self _setAsSingleViewIfNeeded];
				
				_addedViewFromGroup = nil;
			}
			
			_fallViewFlags.groupingOpFinished = 1; //换页时 pageItems已经更改，groupingViewy已经操作
			
			
			[self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
			[self _adaptPageRes];
			
			_handleId = [_pageItems count];
			[_pageRects addObject:[NSValue valueWithCGRect:[self _nextSit]]];
			[_pageItems addObject:_tempV];
			
			
			//[self addSubview:_tempV];
			
			//[self _dismissGroupingBanner];
		}
	}
	else if (point.x < self.bounds.size.width*pageIndex+ _size.width/2.0
             &&_groupingV.isLeftMovingTrend){
		if (pageIndex-1>=0) {
			NSLog(@"i see point should begin move right%.2f",point.x);
			
			
			pageIndex -=1;
			
			_lastPageItems = _pageItems;
			_lastPageRects = _pageRects;
			if (_handleId==-2) {
				_lastHandleId = _handleId;
				_lastMoveId = _moveId;
			}
			else {
				_lastHandleId = _handleId;
			}
			
			
			
			int removeGroupId = -1;
			KLSFallItem *groupFile = [_pageItems objectAtIndex:_moveId];
			for (int i = 0;i<[groupFile.bean.subItems count];++i){
				KLSFallItemBean *tempStruct = [groupFile.bean.subItems objectAtIndex:i];
				if([((KLSFallItem *)_tempV).bean.uuid isEqualToString:tempStruct.uuid]){
					removeGroupId = i;
					break;
				}
			}
			
			[groupFile.bean.subItems removeObjectAtIndex:removeGroupId];
			
			if ([groupFile.bean.subItems count]==0) {
				
				groupFile.bean = ((KLSFallItem *)_tempV).bean;
				[groupFile removeFromSuperview];
				
				_addedViewFromGroup = nil;
			}
			
			_fallViewFlags.groupingOpFinished = 1; //换页时 pageItems已经更改，groupingViewy已经操作
			
			
			[self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
			[self _adaptPageRes];
			
			_handleId = [_pageItems count];
			[_pageRects addObject:[NSValue valueWithCGRect:[self _nextSit]]];
			[_pageItems addObject:_tempV];
		}
	}
}

- (void)_touchEndInGroupingView:(NSValue *)pointValue{
	
	NSLog(@"oh the handleId is %d",_handleId);
	
	CGPoint point;
	[pointValue getValue:&point];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kKLSFall_AnimationDuration];
	
	//判断是否在grouping view中 如果在还是归于原位，不会加入_items中
	if (point.x >=0&&point.x<=_groupingV.frame.size.width&&point.y>=0&&point.y<=_groupingV.frame.size.height) {
		CGRect rect = _tempVInGroup.frame;
		rect.origin.y += _groupingV.frame.origin.y;
		
		[_tempV setFrame:rect];
		
		[_tempV removeFromSuperview];
		
		[_tempVInGroup setHidden:NO];
	}
	else {
		if (_handleId ==-1 || _handleId == -2) {
			
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(_removeTempView)];
			
			
			int removeGroupId = -1;
			KLSFallItem *groupFile = [_pageItems objectAtIndex:_moveId];
            _selectedGroup = groupFile;
			for (int i = 0;i<[groupFile.bean.subItems count];++i){
				KLSFallItemBean *tempStruct = [groupFile.bean.subItems objectAtIndex:i];
				if([((KLSFallItem *)_tempV).bean.uuid isEqualToString:tempStruct.uuid]){
					removeGroupId = i;
					break;
				}
			}
			
			[groupFile.bean.subItems removeObjectAtIndex:removeGroupId];
			
			if ([groupFile.bean.subItems count]==0) {
//				groupFile.bean.hasSubItems = NO;
				
				groupFile.bean = ((KLSFallItem *)_tempV).bean;
				
				_addedViewFromGroup = nil;
			}
			
			if ([_pageItems count]<_fallViewConstants.maxItemPerPage) {
				if ([groupFile.bean.subItems count]>0) {
					[_tempV setFrame:[self _nextSit]];
					KLSFallItem *addedFile = [[KLSFallItem alloc] initWithFrame:_tempV.frame];
					addedFile.bean = ((KLSFallItem *)_tempV).bean;
					
					[_pageItems addObject:addedFile];
					[addedFile release];
					
					[_pageRects addObject:[NSValue valueWithCGRect:addedFile.frame]];
					
					_addedViewFromGroup = addedFile;
				}
			}
			else {
				//TODO:paging operation
				while (pageIndex < [_items count]-1) {
					pageIndex+=1;
					
					if ([[_items objectAtIndex:pageIndex] count]>=_fallViewConstants.maxItemPerPage) {
						continue;
					}
					else {
						[self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
						[self _adaptPageRes];	
						
						if ([groupFile.bean.subItems count]>0) {
							[_tempV setFrame:[self _nextSit]];
							KLSFallItem *addedFile = [[KLSFallItem alloc] initWithFrame:_tempV.frame];
							addedFile.bean = ((KLSFallItem *)_tempV).bean;
							
							[_pageItems addObject:addedFile];
							[addedFile release];
							
							[_pageRects addObject:[NSValue valueWithCGRect:addedFile.frame]];
							
							_addedViewFromGroup = addedFile;
						}
					}
				}
				
				if (pageIndex == [_items count]-1&&!_addedViewFromGroup) {
					NSMutableArray *newPageItems = [[NSMutableArray alloc] init];
					[_items addObject:newPageItems];
					[newPageItems release];
					pageIndex+=1;
					
					NSMutableArray *newRectItems = [[NSMutableArray alloc] init];
					[_rects addObject:newRectItems];
					[newRectItems release];
					
					[self setContentOffset:CGPointMake(self.bounds.size.width*pageIndex,0) animated:YES];
					[self _adaptPageRes];
					
					if ([groupFile.bean.subItems count]>0) {
						[_tempV setFrame:[self _nextSit]];
						KLSFallItem *addedFile = [[KLSFallItem alloc] initWithFrame:_tempV.frame];
						addedFile.bean = ((KLSFallItem *)_tempV).bean;
						
						[_pageItems addObject:addedFile];
						[addedFile release];
						
						[_pageRects addObject:[NSValue valueWithCGRect:addedFile.frame]];
						
						_addedViewFromGroup = addedFile;
					}
				}
			}
            
		}
		else {
			CGRect itemRect;
			[[_pageRects objectAtIndex:_handleId] getValue:&itemRect];
			[_tempV setFrame:itemRect];
			
			_tempV.alpha = 1;
			
			if (_fallViewFlags.groupingOpFinished==0) {
				[_pageItems replaceObjectAtIndex:_handleId withObject:_tempV];
				//[handleFile release];
				
				
				//处理grouping
				int removeGroupId = -1;
				KLSFallItem *groupFile = [_pageItems objectAtIndex:_moveId];
				for (int i = 0;i<[groupFile.bean.subItems count];++i){
					KLSFallItemBean *tempStruct = [groupFile.bean.subItems objectAtIndex:i];
					if([((KLSFallItem *)_tempV).bean.uuid isEqualToString:tempStruct.uuid]){
						removeGroupId = i;
						break;
					}
				}
				
				[groupFile.bean.subItems removeObjectAtIndex:removeGroupId];
			}
			else {
				//handleId == -2(编辑确认后再次展开) 或 !=-2 (拖入group后直接拖动至其他页)
				BOOL shouldRearranged = YES;
				if (_lastHandleId == -2) {
					_lastHandleId = _lastMoveId;
					KLSFallItem *lastPageGroupView = [_lastPageItems objectAtIndex:_lastHandleId];
					if (lastPageGroupView.bean.hasSubItems) {
						shouldRearranged = NO;
					}
				}
				
				if (shouldRearranged) {
					for (int i = _lastHandleId; i < [_lastPageItems count]-1; ++i) {
						[_lastPageItems exchangeObjectAtIndex:i withObjectAtIndex:i+1];
						UIView *view = [_lastPageItems objectAtIndex:i];
						CGRect itemRect;
						NSValue *value = [_lastPageRects objectAtIndex:i];
						[value getValue:&itemRect];
						[UIView beginAnimations:nil context:nil];
						[UIView setAnimationDuration:kKLSFall_AnimationDuration];
						[view setFrame:itemRect];
						[UIView commitAnimations];
					}
				}
				
				
				
				if (shouldRearranged) {
					[_lastPageItems removeObjectAtIndex:[_lastPageItems count]-1];
					
					[_lastPageRects removeObjectAtIndex:[_lastPageRects count]-1];
				}
				
				_fallViewFlags.groupingOpFinished = 0;
				[self _dismissGroupingBanner];
				[self _shouldFrozenFall:NO];
				[self setFallOperation:YES];
				[self _reset];
				return;
			}	
		}
        
		[UIView commitAnimations];
		
		[self _dismissGroupingBanner];
		[self _shouldFrozenFall:NO];
		//_handleId = -1;
		[self _reset];
		[self setFallOperation:YES];
	}
    
}

- (void)_selectInGroupingView:(NSString *)index{
	
//	[_target performSelector:_didSelectItemSelector withObject:viewInGroup];
	[_target fallView:self didSelectGroupItemAtIndex:[index intValue]];
	_handleId = -1;
}

- (void)_removeTempView{
	NSLog(@"should enter remove temp view %d",_moveId);
	//YABookFile *groupFile = [_pageItems objectAtIndex:_moveId];
	[self _setAsSingleViewIfNeeded];
	if (_addedViewFromGroup) {
		[self addSubview:_addedViewFromGroup];
	}
    //	[_tempV setHidden:YES];
	[_tempV removeFromSuperview];
}

- (void)_showGroupingBanner{
	int tarId;
	
	if (_fallViewFlags.fallOperation) { //拖动进入tar，主动点击
		if (nil != _groupingV) {
			return;
		}
		tarId = _moveId;
	}
	else {
		/*
		 *点击直接出现group效果*/
		
		if ([self _isGrouping]) {
			[self _dismissGroupingBanner];
			[self _shouldFrozenFall:NO];
			return;
		}
		tarId = _handleId;
	}
	
	
	if (tarId==-1) { //任何被至为－1 忽略
		return;
	}
	
	_fallViewFlags.inGroupingTask = 1;
	
	int row = tarId/_fallViewConstants.col+1;
	
	float top;
	//特殊处理
	if (row==3) {
		top = _fallViewConstants.marginTop+(_size.height);
	}
	else {
		top = _fallViewConstants.marginTop+row*(_size.height)+(row-1)*_fallViewConstants.rowSpace;
	}
	
	
	_groupingV = [[KLSGroupView alloc] initWithFrame:CGRectMake(self.bounds.size.width*pageIndex,
                                                                top, 
                                                                self.bounds.size.width,
                                                                0)];
	//add image
	UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, _size.height+_fallViewConstants.rowSpace)];
	[bg setImage:[UIImage imageNamed:@""]];
	[_groupingV addSubview:bg];
	[bg release];
	
	[_groupingV setOutItemSelector:@selector(_outItemFromGroupingView:) target:self];
	[_groupingV setTouchMoveSelector:@selector(_touchMoveInGroupingView:) target:self];
	[_groupingV setTouchEndSelector:@selector(_touchEndInGroupingView:) target:self];
	[_groupingV setSelectItemSelector:@selector(_selectInGroupingView:) target:self];
	
	[_groupingV setItemSize:_size];
	[_groupingV setColSpace:10];
    _groupingV.backgroundColor = [UIColor purpleColor];
	
	
	[self addSubview:_groupingV];
	[_groupingV release];
	
	[self bringSubviewToFront:_groupingV];
	
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kKLSFall_AnimationDuration];
	[_groupingV setFrame:CGRectMake(self.bounds.size.width*pageIndex, 
                                    top, 
                                    self.bounds.size.width, 
                                    _size.height+_fallViewConstants.rowSpace)];
	[UIView commitAnimations];
	

	if (_fallViewFlags.fallOperation) {
		NSLog(@"oh tar id %d.......................",tarId);
		[self _setAsGroupView:[_pageItems objectAtIndex:tarId]];
		
	}
	else {
		NSLog(@"oh tar id !_FallOperation %d.......................",tarId);
		KLSFallItem *tarBook = [_pageItems objectAtIndex:tarId];
		for (int i = 0; i<[tarBook.bean.subItems count]; ++i) {
			KLSFallItemBean *bean = [tarBook.bean.subItems objectAtIndex:i];
            //why the hasSubFiles will YES
            //            bookStruct.hasSubFiles = NO;
            NSLog(@"the subfiles %d",bean.hasSubItems);
            
			KLSFallItem *file = [[KLSFallItem alloc] initWithFrame:[_groupingV nextSit]];
			file.bean = bean;
			[_groupingV addSubview:file];
			[file release]; 
		}
		[self _shouldFrozenFall:YES];
	}
	
	if ([self _isShaking]) {
		[self _startGroupShake];
	}
	[self setScrollEnabled:NO];
}

- (void)_shouldFrozenFall:(BOOL)flag{
	for (int i = 0; i < [_pageItems count]; ++i) {
		if (flag) {
			if ([self _isShaking] ) {
				if (i==_moveId) {
					continue;
				}
			}
			else {
				if (i==_handleId) {
					continue;
				}
			}
		}
		
		KLSFallItem *file = [_pageItems objectAtIndex:i];
		//file.userInteractionEnabled = NO;
		if (flag) {
			file.alpha = 0.5;
		}
		else {
			file.alpha = 1;
		}
        
	}
	
	_fallViewFlags.fallFrozen = flag?1:0;
}

- (void)_setAsSingleViewIfNeeded{
    
    KLSFallItem *file = (KLSFallItem *)_selectedGroup;

    	
    if (![file.bean hasSubItems]) {
        //file.backgroundColor = [UIColor blackColor];
        [file becomeSingle];
        [file.bean.subItems removeAllObjects];
    }
    else{
        [file becomeGroup];
    }
}

- (void)_dismissGroupingBanner{
	if (nil == _groupingV) {
		return;
	}
	
	_fallViewFlags.inGroupingTask = 0;
	
	if ([self _isShaking]) {
		[self _stopGroupShake];
	}
	
	[self _setAsSingleViewIfNeeded];
	
	CGRect groupingRect = _groupingV.frame;
	groupingRect.size.height = 0;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kKLSFall_AnimationDuration];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(_removeGroupingView)];
	[_groupingV setFrame:groupingRect];
	[UIView commitAnimations];
	
    //add _handleId = -1 点击出现banner后 再收起 点击的不抖动
//    _handleId = -1;
    //	[self _reset];
    
	_is_grouping = false;
	
}

- (void)_removeGroupingView{
	//if ([_groupingV respondsToSelector:@selector(removeFromSuperview)]) {
    [_groupingV removeFromSuperview],_groupingV = nil;
	//}
}

- (void)_hideHandleViewAndCreateInGroupView{
	[[_pageItems objectAtIndex:_handleId] setHidden:YES];
	[self _addHandleViewToGroup:[_pageItems objectAtIndex:_moveId]];
    
    
}


- (void)_addToGrouping{
	
	_fallViewFlags.fallFrozen = 1;
	//int row = _moveId/_col+1;
	//将handle view移入group
	UIView *view = [_pageItems objectAtIndex:_handleId];
      
    //	[view setHidden:YES];
	[self bringSubviewToFront:view];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(_hideHandleViewAndCreateInGroupView)];
	
    NSLog(@"added group rect %@",NSStringFromCGRect([_groupingV nextSit]));
    
	[view setFrame:CGRectMake([_groupingV nextSit].origin.x+self.bounds.size.width*pageIndex,
                              _groupingV.frame.origin.y+(_groupingV.frame.size.height-_size.height)/2,
                              _size.width,
                              _size.height)];
	
	[UIView commitAnimations];	
}

- (void)_endGrouping{
	for (int i = _handleId; i < [_pageItems count]-1; ++i) {
		[_pageItems exchangeObjectAtIndex:i withObjectAtIndex:i+1];
		UIView *view = [_pageItems objectAtIndex:i];
		CGRect itemRect;
		NSValue *value = [_pageRects objectAtIndex:i];
		[value getValue:&itemRect];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:kKLSFall_AnimationDuration];
		[view setFrame:itemRect];
		[UIView commitAnimations];
	}
	
	[self _dismissGroupingBanner];
	
	if (_handleId != -2) {
		[self _deleteItemAtIndex:[_pageItems count]-1];
	}
	
	[self _shouldFrozenFall:NO];
	[self _reset];
    _fallViewFlags.isEditing = 0;
}

- (BOOL)_isGrouping{
	if (_groupingV) {
		return YES;
	}
	else {
		return NO;
	}
    
}

- (void)_simpleFrameAnimation:(CGRect)frame 
                       target:(UIView *)tar{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kKLSFall_AnimationDuration];
	[tar setFrame:frame];
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Static Methods
static BOOL compareArea(CGRect rect1,CGRect rect2){
	float area1 = rect1.size.width * rect1.size.height;
	float area2 = rect2.size.width * rect2.size.height;
	
	if (area1 >= area2) return YES;
	else return NO;
}

static CGRect compareIntersection(CGRect handleRect,CGRect otherRect){
	CGRect tmpIntersection = CGRectIntersection(handleRect, otherRect);
    
	if (CGRectIsNull(tmpIntersection)) {
		return CGRectZero;
	}
	else {
		_is_grouping = false;
		
		if (tmpIntersection.size.width*tmpIntersection.size.height<otherRect.size.width*otherRect.size.height*1/2) {
			return CGRectZero;
		}
		
		if (_is_left_moving_trend) {
			/*当handle view 完全包含other view，并且当向左移动时handle view
			 *的最右边界没有超越other view的最右边界，此时判定为grouping模式
			 */
            
//            NSLog(@"intersction %@ otherRect %@ tw %f,ow %f",NSStringFromCGRect(tmpIntersection),NSStringFromCGRect(tmpIntersection),tmpIntersection.size.width,otherRect.size.width);
//            float a = handleRect.origin.x+handleRect.size.width;
//            float b = otherRect.origin.x+otherRect.size.width;
//            NSLog(@"handle %.2f",a);
//            NSLog(@"other %.2f",b);
            
			if (CGCRectNearEqualCGRect(tmpIntersection, otherRect) 
                && (handleRect.origin.x+handleRect.size.width>=otherRect.origin.x+otherRect.size.width)) {
				_is_grouping = true;
				return tmpIntersection;
			}
			else if (handleRect.origin.x+handleRect.size.width<otherRect.origin.x+otherRect.size.width-kKLSFall_MovingRange){
				return tmpIntersection;
			}
			else {
				return CGRectZero;
			}
		}
		else {
			
			if (CGCRectNearEqualCGRect(tmpIntersection, otherRect)
                && handleRect.origin.x<=otherRect.origin.x) {
				_is_grouping = true;
				return tmpIntersection;
			}
			else if (handleRect.origin.x > otherRect.origin.x+kKLSFall_MovingRange){
				
				return tmpIntersection;
			}
			else {
				return CGRectZero;
			}
		}
	}
}

static bool CGPointNearPoint(CGPoint point1,CGPoint point2,double distance){
	if (fabs(point1.x - point2.x) < distance
        &&fabs(point1.y - point2.y) < distance) {
		return true;
	}
	else {
		return false;
	}
}

static bool CGCRectNearEqualCGRect(CGRect rect1,CGRect rect2){
	return rect1.origin.x==rect2.origin.x
    &&rect1.origin.y==rect2.origin.y
    &&(fabs(rect1.size.width-rect2.size.width)<1e-2)
    &&(fabs(rect1.size.height-rect2.size.height)<1e-2);
}

- (void)beginEidt{
    [self _startShake];
    _fallViewFlags.isEditing = 1;
}

- (void)endEidt{
    if ([self _isShaking]) {
        [self _stopShaking];
        [self setFallOperation:NO];
        
        if ([self _isGrouping]) {
            [self _endGrouping];		
        }
        
        [self _rearranged];
        _fallViewFlags.isEditing = 0;
    }
}

- (KLSFallItem *)fallItemAtIndex:(int)index{
    return [_pageItems objectAtIndex:index];
}

- (KLSFallItem *)fallGroupItemAtIndex:(int)index{
    return [_groupingV itemAtIndex:index]; 
}


@synthesize pageIndex;
@synthesize isEditing;
@end

