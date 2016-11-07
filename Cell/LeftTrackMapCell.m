//
//  LeftTrackMapCell.m
//  trackmap
//
//  Created by Goldwind on 16/5/17.
//  Copyright © 2016年 Goldwind. All rights reserved.
//

#import "LeftTrackMapCell.h"

@implementation LeftTrackMapCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setContentUI];
    }
    return self;
}

-(void)setContentUI{
    self.leftImageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 20, 20, 20)];
    [self addSubview:self.leftImageView];
    
    self.label = [[UILabel alloc]initWithFrame:CGRectMake(60, 18, 80, 25)];
    self.label.textColor = [UIColor whiteColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.numberOfLines = 1;
    self.label.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.label];
    
    self.arrowView = [[UIImageView alloc]initWithFrame:CGRectMake(260, 20, 12, 18)];
    [self addSubview:self.arrowView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
