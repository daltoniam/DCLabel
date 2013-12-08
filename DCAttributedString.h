///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  NSMutableAttributedString+DCAttributedString.h
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#else
typedef NSColor UIColor;
typedef NSFont UIFont;
#endif

static NSString* const DC_BOLD_TEXT = @"DCBold";
static NSString* const DC_ITALIC_TEXT = @"DCItalic";
static NSString* const DC_UNDERLINE_TEXT = @"DCUnderline";
static NSString* const DC_STRIKE_THROUGH_TEXT = @"DCStrikeOut";
static NSString* const DC_LINK_TEXT = @"DCHyperLink";
static NSString* const DC_IMAGE_LINK = @"DCImageLink";
static NSString* const DC_UNORDERED_LIST = @"DCUnOrderedList";
static NSString* const DC_ORDERED_LIST = @"DCOrderedList";

@interface NSMutableAttributedString (DCAttributedString)

-(void)setFont:(UIFont*)font;
-(void)setFont:(UIFont*)font range:(NSRange)range;
-(void)setFontName:(NSString*)fontName size:(CGFloat)size;
-(void)setFontName:(NSString*)fontName size:(CGFloat)size range:(NSRange)range;

-(void)setTextColor:(UIColor*)color;
-(void)setTextColor:(UIColor*)color range:(NSRange)range;
-(void)setTextIsUnderlined:(BOOL)underlined;
-(void)setTextIsUnderlined:(BOOL)underlined range:(NSRange)range;
-(void)setTextBold:(BOOL)isBold range:(NSRange)range;
-(void)setTextBold:(BOOL)isBold;
-(void)setTextItalic:(BOOL)isItalic range:(NSRange)range;
-(void)setTextItalic:(BOOL)isItalic;
-(void)setTextStrikeOut:(BOOL)strikeout range:(NSRange)range;
-(void)setTextStrikeOut:(BOOL)isStrikeOut;

-(void)setTextIsHyperLink:(NSString*)hyperlink range:(NSRange)range;
-(void)setTextIsHyperLink:(NSString*)hyperlink;

-(void)setTextAlignment:(CTTextAlignment)alignment lineBreakMode:(CTLineBreakMode)lineBreakMode;
-(void)setTextAlignment:(CTTextAlignment)alignment lineBreakMode:(CTLineBreakMode)lineBreakMode range:(NSRange)range;

-(void)setFontFamily:(NSString*)fontFamily size:(CGFloat)size bold:(BOOL)isBold italic:(BOOL)isItalic range:(NSRange)range;
-(void)setFontFamily:(NSString*)fontFamily size:(CGFloat)size bold:(BOOL)isBold italic:(BOOL)isItalic;
-(void)setTextSize:(CGFloat)size;
-(void)setTextSize:(CGFloat)size range:(NSRange)range;

-(void)addImage:(NSString*)link height:(float)height width:(float)width index:(NSInteger)index attributes:(NSDictionary*)attrs;

//add unorder list to the string
-(void)setUnOrderedList:(NSInteger)index;
-(void)setOrderedList:(NSInteger)index number:(NSInteger)number;

@end
