//
//  KLSFallItem.m
//  KSLFallDemo
//
//  Created by shen yin on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KLSFallItem.h"

#define kKLSFallItem_SubScale 6
#define kKLSFallItem_SubRowCol 3
#define kKLSFallItem_Margin 5
#define kKLSFallItem_X 0.7

@class KLSFallView;
@implementation KLSFallItemBean

- (id)init{
    self = [super init];
    if (self) {
        double time = CFAbsoluteTimeGetCurrent();
        self.uuid = [NSString stringWithFormat:@"%f",time];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    KLSFallItemBean *copy = [[[self class] allocWithZone:zone] init];
    copy->title = [title copy];
	copy->uuid = [uuid copy];
    copy->icon = [icon copy];
    copy->subItems = [subItems mutableCopy];
    
    #if KLSFall_NetworkDL
        copy->downloadComplete = downloadComplete;
    #endif
    
    return copy;
}

- (BOOL)hasSubItems{
    if (self.subItems) {
        if ([subItems count]>0) {
            return YES;
        }
    }
    return NO;
}

- (void)dealloc{
    self.title = nil;
    self.uuid = nil;
    self.subItems = nil;
    self.icon = nil;
    
    [super dealloc];
}

@synthesize title;
@synthesize uuid;
@synthesize subItems;
@synthesize icon;
#if KLSFall_NetworkDL
    @synthesize downloadComplete;
#endif

@end

@implementation KLSFallItemCircle

- (id)initWithFrame:(CGRect)frame{
	if (self = [super initWithFrame:frame]) {
		 self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)setItemDelegate:(id<KLSFallItemCircleDelegate>)itemdelegate{
	_itemDelegate = itemdelegate;
}

-(void)drawCircleAtPoint:(CGPoint)center 
                diameter:(float)diameter 
               fillColor:(UIColor *)fillColor 
             stockeColor:(UIColor *)stockeColor
                 context:(CGContextRef)context
{	
	float radius = diameter * 0.5;
	CGRect oval = {center.x - radius,center.y - radius,diameter,diameter};
	[fillColor setFill];
	CGContextAddEllipseInRect(context, oval);
	CGContextFillPath(context);
	CGContextAddArc(context,center.x,center.y,radius,0,2*M_PI,1);
	CGContextSetLineWidth(context, 2);
	[stockeColor setStroke];
	CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)rect{
   
	CGContextRef context = UIGraphicsGetCurrentContext();
    if (context) {
        [self drawCircleAtPoint:self.center
                       diameter:self.frame.size.width/1.2
                      fillColor:[UIColor blackColor]
                    stockeColor:[UIColor whiteColor]
                        context:context];
        
        CGContextSetLineWidth(context,2);
        
        //X
        CGContextMoveToPoint(context,(1-kKLSFallItem_X)*rect.size.width,(1-kKLSFallItem_X)*rect.size.height);
        CGContextAddLineToPoint(context,kKLSFallItem_X*rect.size.width,kKLSFallItem_X*rect.size.height);
        CGContextDrawPath(context, kCGPathStroke);
        
        CGContextMoveToPoint(context,kKLSFallItem_X*rect.size.width,(1-kKLSFallItem_X)*rect.size.height);
        CGContextAddLineToPoint(context,(1-kKLSFallItem_X)*rect.size.width,kKLSFallItem_X*rect.size.height);
        CGContextDrawPath(context, kCGPathStroke);
    }
	
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
//    CGRect touchRect = CGRectMake(5, 5, 25, 25);
//    
//    UITouch *touch = [touches anyObject];
    
//    CGPoint point = [touch locationInView:self];
    
//    if (CGRectContainsPoint(touchRect, point)) {
        [_itemDelegate KLSFallCircleDidClick];
//    }
}


@end

@interface KLSFallItem () 

- (void)_memberInit;
- (void)_createCircle;
- (void)_createContent;

@end

@implementation KLSFallItem

- (id)initWithFrame:(CGRect)frame{
    
	self = [super initWithFrame:frame];
    
    if (self) {
        [self _createContent];
        [self _createCircle];
        [self _memberInit];
       
//        self.backgroundColor = [UIColor yellowColor];
    }
    
    return self;
}


- (void)_createContent{
    CGRect bounds = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    bounds.size.width /=kKLSFallItemRealScale;
    bounds.size.height /=kKLSFallItemRealScale;
    
    bounds.origin.x += (self.bounds.size.width-bounds.size.width)/2;
    bounds.origin.y += (self.bounds.size.height-bounds.size.height)/2;
    
    _content = [[UIView alloc] initWithFrame:bounds];
    
    _content.backgroundColor = [UIColor blackColor];
    
    [self addSubview:_content];
    [_content release];
    
}

- (id)initWithSettingSize{
    [self initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    return self;
}

- (void)setFrame:(CGRect)frame{
    CGRect rect = frame;
    
    CGRect bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
    
    CGRect circle = CGRectMake(0, 
                               0,
                               (float)rect.size.width/3.5, 
                               (float)rect.size.height/3.5);

    
    bounds.size.width /=kKLSFallItemRealScale;
    bounds.size.height /=kKLSFallItemRealScale;
    
    bounds.origin.x += (rect.size.width-bounds.size.width)/2;
    bounds.origin.y += (rect.size.height-bounds.size.height)/2;
    
    [super setFrame:rect];
    [_content setFrame:bounds];
    
    [_circle setFrame:circle];
    
//    [_circle setCenter:CGPointMake(bounds.origin.x, bounds.origin.y)];
    
    [_circle drawRect:_circle.bounds];
}


- (void)setBean:(KLSFallItemBean*)aBean{
    [bean release];
    bean = [aBean copy];
}

- (void)_createCircle{
    
    CGRect circle = CGRectMake(0, 
                               0,
                               (float)self.bounds.size.width/3.5, 
                               (float)self.bounds.size.height/3.5);
    
    _circle = [[KLSFallItemCircle alloc] initWithFrame:circle];
	[_circle setItemDelegate:self];
	[self addSubview:_circle];
	[_circle release];
    
    [self hiddenDeleteButton];
}

- (void)addTarget:(id)tar selector:(SEL)sel{
	_target = tar;
	_selector = sel;
}

- (void)becomeGroup{
    
    for (id item in _content.subviews){
        [item removeFromSuperview];
    }
    
    float width = _content.bounds.size.width/kKLSFallItem_SubScale;
    float height = _content.bounds.size.height/kKLSFallItem_SubScale;
    
    float widthSpace = (_content.bounds.size.width - kKLSFallItem_Margin*2-kKLSFallItem_SubRowCol*width)/(kKLSFallItem_SubRowCol-1);

    float heightSpace = (_content.bounds.size.height - kKLSFallItem_Margin*2-kKLSFallItem_SubRowCol*height)/(kKLSFallItem_SubRowCol-1);

    
    for (int i = 0; i < [self.bean.subItems count]; i++) {
        
        
        KLSFallItemBean *subBean = [self.bean.subItems objectAtIndex:i];
        
        CGRect itemRect = CGRectMake(kKLSFallItem_Margin+i%kKLSFallItem_SubRowCol*(width+widthSpace),
                                     kKLSFallItem_Margin+i/kKLSFallItem_SubRowCol*(height+heightSpace),
                                     width,
                                     height);
        
        KLSFallItem *item = [[KLSFallItem alloc] initWithFrame:itemRect];
        item.bean = subBean;
        
        [_content addSubview:item];
//        [item release];
        _content.backgroundColor = [UIColor grayColor];
    }
}

- (void)becomeSingle{
    
    for (id item in _content.subviews)
    {
        [item removeFromSuperview];
    }
    
    [self.bean.subItems removeAllObjects];
    
    _content.backgroundColor = [UIColor blackColor]; 
}

- (void)showDeleteButton{
	[_circle setHidden:NO];
}

- (void)hiddenDeleteButton{
	[_circle setHidden:YES];
}

- (void)_memberInit{
    self.bean = [[KLSFallItemBean alloc] init];
}

- (void)KLSFallCircleDidClick{
    [[NSNotificationCenter defaultCenter] postNotificationName:nFall_SHOULD_DELETE_ITEM
                                                        object:self 
                                                      userInfo:nil];

}

- (void)dealloc{
    self.bean = nil;
    [super dealloc];
}

@synthesize bean;
@end
