//
//  TKCheckCell.m
//  inOrder
//
//  Created by Taras Kalapun on 27.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "TKCheckCell.h"


@implementation TKCheckCell

- (void)setObjectValue:(id)object {
    
    //hideCheckbox = [[object valueForKey:@"hideCheckbox"] boolValue];
    
    [super setObjectValue:[object valueForKey:@"state"]];
    
    [self setTitle:[object valueForKey:@"title"]];
    
}

/*
-(void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    if(!hideCheckbox)
        [super drawWithFrame:frame inView:view];
}
*/

@end
