///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCLabel.m
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCLabel.h"
#import "DCAttributedString.h"

@implementation DCLabel

#define LONG_PRESS_THRESHOLD 0.75

@synthesize delegate,textShadowBlur,textShadowColor,textShadowOffset;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        viewItems = [NSMutableArray array];
    }
    return self;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if(!isDrawing)
    {
        isDrawing = YES;
        for(ViewItem* entry in viewItems)
        {
            [entry.subView removeFromSuperview];
            entry.subView.frame = entry.frame;
            [self addSubview:entry.subView];
            [self bringSubviewToFront:entry.subView];
        }
        isDrawing = NO;
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawTextInRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if(self.textShadowColor)
    {
        CGContextSetShadow(ctx, self.textShadowOffset, self.textShadowBlur);
        CGContextSetShadowWithColor(ctx, self.textShadowOffset, self.textShadowBlur, self.textShadowColor.CGColor);
    }
    /*if(self.text && !self.attributedText)
    {
        [super drawTextInRect:rect];
        return;
    }*/
    if(!isDrawing)
    {
        isDrawing = YES;
        if (self.attributedText)
        {
            // flipping the context to draw core text
            // no need to flip our typographical bounds from now on
            CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
            CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
            CGContextScaleCTM(ctx, 1.0, -1.0);
            
            if (textFrame == NULL)
            {
                CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedText);
                CGRect frame = self.bounds;
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathAddRect(path, NULL, frame);
                textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
                CGPathRelease(path);
                CFRelease(framesetter);
            }
            CTFrameDraw(textFrame, ctx);
            CFArrayRef leftLines = CTFrameGetLines(textFrame); //textFrame
            int lineCount = [(__bridge NSArray *)leftLines count];
            CGPoint *origins = malloc(sizeof(CGPoint)*lineCount);
            CTFrameGetLineOrigins(textFrame,CFRangeMake(0, 0), origins);
            NSInteger lineIndex = 0;
            
            for (id oneLine in (__bridge NSArray *)leftLines)
            {
                CFArrayRef runs = CTLineGetGlyphRuns((__bridge CTLineRef)oneLine);
                for (id oneRun in (__bridge NSArray *)runs)
                {
                    CGFloat ascent = 0;
                    CGFloat descent = 0;
                    CGFloat width = CTRunGetTypographicBounds((__bridge CTRunRef) oneRun,CFRangeMake(0, 0),&ascent,&descent, NULL);
                    CGFloat height = ascent + descent;
                    CGFloat xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)oneLine, CTRunGetStringRange((__bridge CTRunRef)oneRun).location, NULL);
                    
                    NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes((__bridge CTRunRef) oneRun);
                    //CTFontRef font = (__bridge CTFontRef)[attributes objectForKey:(NSString*)kCTFontAttributeName];
                    //CGFloat fontSize = CTFontGetSize(font);
                    //int fontOffset = (fontSize*2);
                    
                    NSString* hyperlink = [attributes objectForKey:DC_LINK_TEXT];
                    if(hyperlink)
                    {
                        CGRect runRect = CGRectMake(origins[lineIndex].x + xOffset,origins[lineIndex].y + self.frame.origin.y,width,height );
                        runRect.origin.y -= descent;
                        CGPathRef pathRef = CTFrameGetPath(textFrame);
                        CGRect colRect = CGPathGetBoundingBox(pathRef);
                        
                        runRect = CGRectOffset(runRect, colRect.origin.x, colRect.origin.y - self.frame.origin.y);
                        runRect = CGRectIntegral(runRect);
                        runRect = CGRectInset(runRect, -1, -1);
                        
                        UIColor* highlight = [UIColor clearColor];
                        if(hyperlink && [hyperlink isEqualToString:currentHyperLink])
                            highlight = [UIColor colorWithWhite:0.4 alpha:0.3];
                        CGContextSaveGState(ctx);
                        CGContextSetFillColorWithColor(ctx,highlight.CGColor);
                        CGContextFillRect(ctx,runRect);
                        CGContextRestoreGState(ctx);
                    }
                    NSString* imgURL = [attributes objectForKey:DC_IMAGE_LINK];
                    if(imgURL && [self.delegate respondsToSelector:@selector(imageWillLoad:attributes:)]) //&& ![self didLoadURL:imgURL]
                    {
                        ViewItem* viewItem = [self viewItemForTag:viewTag];
                        if(!viewItem)
                        {
                            UIView* view = [self.delegate imageWillLoad:imgURL attributes:attributes];
                            viewItem = [ViewItem item:view url:imgURL frame:CGRectZero];
                            [viewItems addObject:viewItem];
                        }
                        if(viewItem)
                        {
                            CGRect runBounds;
                            runBounds.size.width = width;
                            runBounds.size.height = height;
                            runBounds.origin.x = origins[lineIndex].x + xOffset;
                            runBounds.origin.y = self.frame.size.height - (origins[lineIndex].y + height);
                            viewItem.frame = runBounds;
                        }
                    }
                }
                lineIndex++;
            }
            free(origins);
        }
        else
            [super drawTextInRect:rect];
        isDrawing = NO;
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    isLongPress = NO;
    UITouch* touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    CFIndex idx = [self characterIndexAtPoint:pt];
    if(idx != NSNotFound && idx < [self.attributedText length])
    {
        NSDictionary* attribs = [self.attributedText attributesAtIndex:idx effectiveRange:NULL];
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:attribs];
        [dict setValue:[NSValue valueWithCGPoint:pt] forKey:@"point"];
        
        [self performSelector:@selector(fireLongPress:)
                   withObject:dict
                   afterDelay:LONG_PRESS_THRESHOLD];
        NSString* hyperlink = [attribs objectForKey:DC_LINK_TEXT];
        if(hyperlink)
        {
            currentHyperLink = hyperlink;
            [self setNeedsDisplay];
        }
    }
    [self.nextResponder touchesBegan:touches withEvent:event];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(currentHyperLink)
    {
        currentHyperLink = nil;
        [self setNeedsDisplay];
    }
    [self.nextResponder touchesEnded:touches withEvent:event];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//handles hyperlink clicking
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(isLongPress)
    {
        isLongPress = NO;
        [self.nextResponder touchesEnded:touches withEvent:event];
        return;
    }
    if(currentHyperLink)
    {
        currentHyperLink = nil;
        [self setNeedsDisplay];
    }
	UITouch* touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    CFIndex idx = [self characterIndexAtPoint:pt];
    if(idx != NSNotFound && idx < [self.attributedText length])
    {
        NSDictionary* attribs = [self.attributedText attributesAtIndex:idx effectiveRange:NULL];
        NSString* hyperlink = [attribs objectForKey:DC_LINK_TEXT];
        NSString* imageURL = [attribs objectForKey:DC_IMAGE_LINK];
        if([self.delegate respondsToSelector:@selector(didSelectLink:)] && hyperlink)
        {
            [self.delegate didSelectLink:hyperlink];
            return;
        }
        if(imageURL)
        {
            if([self.delegate respondsToSelector:@selector(didSelectImage:)] && imageURL)
            {
                [self.delegate didSelectImage:imageURL];
                return;
            }
        }
}
    [self.nextResponder touchesEnded:touches withEvent:event];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fireLongPress:(NSDictionary*)attribs
{
    isLongPress = YES;
    currentHyperLink = nil;
    [self setNeedsDisplay];
    NSString* hyperlink = [attribs objectForKey:DC_LINK_TEXT];
    NSString* imageURL = [attribs objectForKey:DC_LINK_TEXT];
    if([self.delegate respondsToSelector:@selector(didLongPressLink:frame:)] && hyperlink)
    {
        CGPoint pt = [[attribs objectForKey:@"point"] CGPointValue];
        CGRect frame = CGRectMake(pt.x, pt.y, hyperlink.length, 14);
        [self.delegate didLongPressLink:hyperlink frame:frame];
        return;
    }
    if([self.delegate respondsToSelector:@selector(didLongPressImage:)] && imageURL)
    {
        [self.delegate didLongPressImage:hyperlink];
        return;
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//finds the character tap on at a point
- (NSUInteger)characterIndexAtPoint:(CGPoint)p
{
    if (!CGRectContainsPoint(self.bounds, p))
        return NSNotFound;
    
    CGRect textRect = self.bounds;
    if (!CGRectContainsPoint(textRect, p))
        return NSNotFound;
    
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    p = CGPointMake(p.x, textRect.size.height - p.y);
    
    CFIndex idx = NSNotFound;
    CFArrayRef lines = CTFrameGetLines(textFrame);
    NSUInteger numberOfLines = CFArrayGetCount(lines);
    if(numberOfLines > 0)
    {
        CGPoint lineOrigins[numberOfLines];
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), lineOrigins);
        NSUInteger lineIndex;
        
        for (lineIndex = 0; lineIndex < (numberOfLines - 1); lineIndex++)
        {
            CGPoint lineOrigin = lineOrigins[lineIndex];
            if (lineOrigin.y < p.y)
                break;
        }
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        // Convert CT coordinates to line-relative coordinates
        CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
        idx = CTLineGetStringIndexForPosition(line, relativePoint);
    }
    
    return idx;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setAttributedText:(NSAttributedString *)text
{
    if(textFrame)
        CFRelease(textFrame);
    textFrame = NULL;
    for(ViewItem* item in viewItems)
        [item.subView removeFromSuperview];
    [viewItems removeAllObjects];
    [super setAttributedText:text];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setText:(NSString *)text
{
    //self.attributedText = nil;
    if(textFrame)
        CFRelease(textFrame);
    textFrame = NULL;
    [super setText:text];
    [self setNeedsDisplay];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)didLoadURL:(NSString*)url
{
    for(ViewItem* item in viewItems)
    {
        if([item.URL isEqualToString:url])
            return YES;
    }
    return NO;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(ViewItem*)viewItemForTag:(int)tag
{
    if(viewItems.count < tag)
        [viewItems objectAtIndex:tag];
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//public method
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(CGFloat)suggestedHeight:(NSAttributedString*)attributedText width:(int)width
{
    if(attributedText)
    {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedText);
        //NSLog(@"frame.size.width: %f",frame.size.width);
        CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,CGSizeMake(width,10000.0f),NULL);
        //NSLog(@"size: %f",size.height);
        CGFloat height = MAX(0.f , ceilf(size.height));
        CFRelease(framesetter);
        return height;
    }
    return 0;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ViewItem

@synthesize subView,URL,frame;

+(ViewItem*)item:(UIView*)view url:(NSString*)url frame:(CGRect)rect
{
    ViewItem* item = [[ViewItem alloc] init];
    item.subView = view;
    item.URL = url;
    item.frame = rect;
    return item;
}



@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

