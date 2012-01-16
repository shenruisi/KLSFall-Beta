//
//  KLSView.m
//  KSLFallDemo
//
//  Created by Jerry Wang on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KLSView.h"

@implementation KLSView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
    [super dealloc];
}

@end
