///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCLabel.h
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface ViewItem : NSObject

+(ViewItem*)item:(UIView*)view url:(NSString*)url frame:(CGRect)rect;

@property(nonatomic, retain) UIView* subView;
@property(nonatomic, copy) NSString* URL;
@property(nonatomic,assign)CGRect frame;

@end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol DCLabelDelegate <NSObject>

@optional

//delegate options
- (void)didSelectLink:(NSString*)link;
- (void)didLongPressLink:(NSString*)link frame:(CGRect)frame;
- (void)didSelectImage:(NSString*)imageURL;
- (void)didLongPressImage:(NSString*)imageURL;

//return your imageView that loads the imgURL
-(UIView*)imageWillLoad:(NSString*)imgURL attributes:(NSDictionary*)attributes;

@end

@interface DCLabel : UILabel
{
    BOOL isDrawing;
    CTFrameRef textFrame;
    NSString* currentHyperLink;
    BOOL isLongPress;
    NSMutableArray* viewItems;
    int viewTag;
}
@property(nonatomic,copy)NSAttributedString* attributedText; //for iOS 5

@property(nonatomic,assign)id<DCLabelDelegate>delegate;

//text shadow properties
@property(nonatomic,strong)UIColor* textShadowColor;
@property(nonatomic,assign)CGSize textShadowOffset;
@property(nonatomic,assign)NSInteger textShadowBlur;

//returns the suggested height for the label based of the text and the width.
+(CGFloat)suggestedHeight:(NSAttributedString*)attributedText width:(int)width;

@end
