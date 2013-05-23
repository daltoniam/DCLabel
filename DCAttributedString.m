///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  NSMutableAttributedString+DCAttributedString.m
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCAttributedString.h"
#import <CoreText/CoreText.h>

@implementation NSMutableAttributedString (DCAttributedString)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set font.
-(void)setFont:(UIFont*)font
{
	[self setFontName:font.fontName size:font.pointSize];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set font with range
-(void)setFont:(UIFont*)font range:(NSRange)range
{
	[self setFontName:font.fontName size:font.pointSize range:range];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set font with size.
-(void)setFontName:(NSString*)fontName size:(CGFloat)size
{
	[self setFontName:fontName size:size range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set font name with size and range, logic for other font setting
-(void)setFontName:(NSString*)fontName size:(CGFloat)size range:(NSRange)range
{
	//CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)fontName, size, NULL);
    UIFont* font = [UIFont fontWithName:fontName size:size];
	if (!font)
        return;
	[self removeAttribute:(NSString*)kCTFontAttributeName range:range]; // remove then add for apple leak.
    [self addAttribute:(NSString*)kCTFontAttributeName value:font range:range];
	//[self addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)font range:range];
	//CFRelease(font);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set Text color
-(void)setTextColor:(UIColor*)color
{
	[self setTextColor:color range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set text color with a range
-(void)setTextColor:(UIColor*)color range:(NSRange)range
{
    [self removeAttribute:NSForegroundColorAttributeName range:range];
    [self addAttribute:NSForegroundColorAttributeName value:color range:range];
	//[self removeAttribute:(NSString*)kCTForegroundColorAttributeName range:range]; // remove then add for apple leak.
	//[self addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)color.CGColor range:range];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set text underlined
-(void)setTextIsUnderlined:(BOOL)underlined
{
	[self setTextIsUnderlined:underlined range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set text underlined with a range.
-(void)setTextIsUnderlined:(BOOL)underlined range:(NSRange)range
{
	int32_t style = underlined ? (kCTUnderlineStyleSingle|kCTUnderlinePatternSolid) : kCTUnderlineStyleNone;
    [self removeAttribute:(NSString*)kCTUnderlineStyleAttributeName range:range]; // Work around for Apple leak
	[self addAttribute:(NSString*)kCTUnderlineStyleAttributeName value:[NSNumber numberWithInt:style] range:range];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text bold
-(void)setTextBold:(BOOL)isBold
{
    [self setTextBold:isBold range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set text strikeout with a range.
-(void)setTextStrikeOut:(BOOL)strikeout range:(NSRange)range
{
    [self removeAttribute:NSStrikethroughStyleAttributeName range:range]; // Work around for Apple leak
	[self addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithBool:strikeout] range:range];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text strikeout
-(void)setTextStrikeOut:(BOOL)isStrikeOut
{
    [self setTextStrikeOut:isStrikeOut range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text hyperlink
-(void)setTextIsHyperLink:(NSString*)hyperlink range:(NSRange)range
{
    [self removeAttribute:DC_LINK_TEXT range:range]; // Work around for Apple leak
	[self addAttribute:DC_LINK_TEXT value:hyperlink range:range];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text a hyperlink
-(void)setTextIsHyperLink:(NSString*)hyperlink
{
    [self setTextIsHyperLink:hyperlink range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text is bold with a range
-(void)setTextBold:(BOOL)isBold range:(NSRange)range
{
	NSUInteger startPoint = range.location;
	NSRange effectiveRange;
	do {
		// Get font at startPoint
		CTFontRef currentFont = (__bridge CTFontRef)[self attribute:(NSString*)kCTFontAttributeName atIndex:startPoint effectiveRange:&effectiveRange];
		// The range for which this font is effective
		NSRange fontRange = NSIntersectionRange(range, effectiveRange);
		// Create bold/unbold font variant for this font and apply
		CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(currentFont, 0.0, NULL, (isBold?kCTFontBoldTrait:0), kCTFontBoldTrait);
		if (newFont)
        {
            NSString *fontName = (__bridge NSString *)CTFontCopyName(newFont, kCTFontPostScriptNameKey);
            CGFloat fontSize = CTFontGetSize(newFont);
            UIFont *font = [UIFont fontWithName:fontName size:fontSize];
			[self removeAttribute:(NSString*)kCTFontAttributeName range:fontRange]; // Work around for Apple leak
            [self addAttribute:(NSString*)kCTFontAttributeName value:font range:fontRange];
			//[self addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)newFont range:fontRange];
			CFRelease(newFont);
		}
        
		// If the fontRange was not covering the whole range, continue with next run
		startPoint = NSMaxRange(effectiveRange);
	} while(startPoint<NSMaxRange(range));
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text bold
-(void)setTextItalic:(BOOL)isItalic
{
    [self setTextItalic:isItalic range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set if text is italic with a range
-(void)setTextItalic:(BOOL)isItalic range:(NSRange)range
{
	NSUInteger startPoint = range.location;
	NSRange effectiveRange;
	do {
		// Get font at startPoint
		CTFontRef currentFont = (__bridge CTFontRef)[self attribute:(NSString*)kCTFontAttributeName atIndex:startPoint effectiveRange:&effectiveRange];
		// The range for which this font is effective
		NSRange fontRange = NSIntersectionRange(range, effectiveRange);
		// Create bold/unbold font variant for this font and apply
		CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(currentFont, 0.0, NULL, (isItalic?kCTFontItalicTrait:0), kCTFontItalicTrait);
		if (newFont)
        {
            NSString *fontName = (__bridge NSString *)CTFontCopyName(newFont, kCTFontPostScriptNameKey);
            CGFloat fontSize = CTFontGetSize(newFont);
            UIFont *font = [UIFont fontWithName:fontName size:fontSize];
			[self removeAttribute:(NSString*)kCTFontAttributeName range:fontRange]; // Work around for Apple leak
            [self addAttribute:(NSString*)kCTFontAttributeName value:font range:fontRange];
			//[self addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)newFont range:fontRange];
			CFRelease(newFont);
		}
        
		// If the fontRange was not covering the whole range, continue with next run
		startPoint = NSMaxRange(effectiveRange);
	} while(startPoint<NSMaxRange(range));
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set the text alignment.
-(void)setTextAlignment:(CTTextAlignment)alignment lineBreakMode:(CTLineBreakMode)lineBreakMode
{
	[self setTextAlignment:alignment lineBreakMode:lineBreakMode range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set the text alignment of the text with a range.
-(void)setTextAlignment:(CTTextAlignment)alignment lineBreakMode:(CTLineBreakMode)linebreakmode range:(NSRange)range
{
    
    //{.spec = kCTParagraphStyleSpecifierParagraphSpacing, .valueSize = sizeof(CGFloat), .value = (const void*)12},
	CTParagraphStyleSetting parastyles[2] = {
		{.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = (const void*)&alignment},
		{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void*)&linebreakmode},};
    
	CTParagraphStyleRef style = CTParagraphStyleCreate(parastyles, 2);
	[self removeAttribute:(NSString*)kCTParagraphStyleAttributeName range:range];
	[self addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(__bridge id)style range:range];
	CFRelease(style);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setFontFamily:(NSString*)fontFamily size:(CGFloat)size bold:(BOOL)isBold italic:(BOOL)isItalic
{
    [self setFontFamily:fontFamily size:size bold:isBold italic:isItalic range:NSMakeRange(0,[self length])];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setFontFamily:(NSString*)fontFamily size:(CGFloat)size bold:(BOOL)isBold italic:(BOOL)isItalic range:(NSRange)range
{
    if(fontFamily)
    {
        //CTFontSymbolicTraits symTrait = (isBold?kCTFontBoldTrait:0) | (isItalic?kCTFontItalicTrait:0);
        //NSDictionary* trait = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:symTrait] forKey:(NSString*)kCTFontSymbolicTrait];
        NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                              fontFamily,kCTFontFamilyNameAttribute,nil];
        //                          trait,kCTFontTraitsAttribute,
        
        CTFontDescriptorRef desc = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)attr);
        if (!desc)
            return;
        CTFontRef aFont = CTFontCreateWithFontDescriptor(desc, size, NULL);
        CFRelease(desc);
        if (!aFont)
            return;
        
        NSString *fontName = (__bridge NSString *)CTFontCopyName(aFont, kCTFontPostScriptNameKey);
        CGFloat fontSize = CTFontGetSize(aFont);
        UIFont *font = [UIFont fontWithName:fontName size:fontSize];
        [self removeAttribute:(NSString*)kCTFontAttributeName range:range]; // remove then add for apple leak.
        [self addAttribute:(NSString*)kCTFontAttributeName value:font range:range];
        //[self addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)aFont range:range];
        CFRelease(aFont);
    }
    [self setTextBold:isBold range:range];
    [self setTextItalic:isItalic range:range];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addImage:(NSString*)link height:(float)height width:(float)width index:(int)index attributes:(NSDictionary*)attrs
{
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:@" "];
    NSRange range = NSMakeRange(0, 1); 
    [string addRunDelegate:range height:height width:width];
    [string addAttribute:DC_IMAGE_LINK value:link range:range];
    [string addAttributes:attrs range:range];
    [self insertAttributedString:string atIndex:index];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//private stuff
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addRunDelegate:(NSRange)range height:(float)height width:(float)width
{
    NSString* h = [NSString stringWithFormat:@"%f",height];
    NSString* w = [NSString stringWithFormat:@"%f",width];
    NSDictionary* attribs = [NSDictionary dictionaryWithObjectsAndKeys:h,@"height",w,@"width", nil];
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = deallocationCallback;
    callbacks.getAscent = getAscentCallback;
    callbacks.getDescent = getDescentCallback;
    callbacks.getWidth = getWidthCallback;
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks,(void *)CFBridgingRetain(attribs));
    [self removeAttribute:(NSString*)kCTRunDelegateAttributeName range:range]; // remove then add for apple leak.
    [self addAttribute:(NSString*)kCTRunDelegateAttributeName value:(__bridge id)delegate range:range];
    CFRelease(delegate);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void deallocationCallback( void* ref )
{
    CFBridgingRelease(ref);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//height of object
CGFloat getAscentCallback( void *ref )
{
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"height"] floatValue];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
CGFloat getDescentCallback( void *ref)
{
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] floatValue];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//width of object
CGFloat getWidthCallback( void* ref )
{
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] floatValue];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end
