///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCParseEngine.m
//  iOSTester
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCParseEngine.h"
#import "DCAttributedString.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//private objects
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DCParsePattern : NSObject

@property(nonatomic,strong)NSString* openTag;
@property(nonatomic,strong)NSString* closeTag;
@property(nonatomic,strong)NSArray* attributes;
@property(nonatomic,assign)DCPatternBlock callback;

+(DCParsePattern*)patternWithTag:(NSString*)open close:(NSString*)close attribs:(NSArray*)attrs;
+(DCParsePattern*)patternWithTag:(NSString*)open close:(NSString*)close callback:(DCPatternBlock)block;

@end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DCStyleRange : NSObject

@property(nonatomic,assign)int start;
@property(nonatomic,assign)int end;
@property(nonatomic,assign)NSArray* attribs;
@property(nonatomic,assign)NSString* closeTag;
@property(nonatomic,strong)NSString* openTag;
@property(nonatomic,assign)DCPatternBlock block;


@end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DCParseEngine

@synthesize embedHeight,embedWidth;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(id)init
{
    if(self = [super init])
    {
        patterns = [[NSMutableArray alloc] init];
        self.embedHeight = 200;
        self.embedWidth = 200;
    }
    return self;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//this is used when the attributes for a tag match will be known ahead of time. (e.g: hello *world* '*' bolds the text)
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs
{
    DCParsePattern* pattern = [DCParsePattern patternWithTag:openTag close:closeTag attribs:attribs];
    [patterns addObject:pattern];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag block:(DCPatternBlock)callback
{
    DCParsePattern* pattern = [DCParsePattern patternWithTag:openTag close:closeTag callback:callback];
    [patterns addObject:pattern];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSAttributedString*)parse:(NSString*)string
{
    NSString* endString = [NSString stringWithString:string];
    int offset = 0;
    NSMutableArray* currentRanges = [NSMutableArray array];
    NSMutableArray* collectRanges = [NSMutableArray array];
    BOOL found = NO;
    for(int i = 0; i < string.length; i++)
    {
        for(DCStyleRange* range in currentRanges)
        {
            if([range.closeTag characterAtIndex:0] == [string characterAtIndex:i])
            {
                NSString* uTag = nil;
                BOOL isTag = [self processTag:range.closeTag updateTag:&uTag string:string index:i];
                if(uTag)
                    range.closeTag = uTag;
                if(isTag)
                {
                    endString = [endString stringByReplacingCharactersInRange:NSMakeRange(i-offset, range.closeTag.length) withString:@""];
                    range.end = (i-offset) - range.start;
                    offset += range.closeTag.length;
                    i += range.closeTag.length;
                    [currentRanges removeObject:range];
                    found = YES;
                    break;
                }
            }
        }
        if(!found)
        {
            for(DCParsePattern* pattern in patterns)
            {
                if([pattern.openTag characterAtIndex:0] == [string characterAtIndex:i])
                {
                    NSString* currentTag = nil;
                    NSString* uTag = nil;
                    BOOL isTag = [self processTag:pattern.openTag updateTag:&uTag string:string index:i];
                    if(uTag)
                    {
                        currentTag = pattern.openTag;
                        pattern.openTag = uTag;
                    }
                    if(isTag)
                    {
                        endString = [endString stringByReplacingCharactersInRange:NSMakeRange(i-offset, pattern.openTag.length) withString:@""];
                        DCStyleRange* range = [[DCStyleRange alloc] init];
                        range.start = i-offset;
                        range.attribs = pattern.attributes;
                        range.closeTag = pattern.closeTag;
                        range.openTag = pattern.openTag;
                        range.block = pattern.callback;
                        [currentRanges addObject:range];
                        [collectRanges addObject:range];
                        offset += pattern.openTag.length;
                        i += pattern.openTag.length-1;
                        if(uTag)
                            pattern.openTag = currentTag;
                        break;
                    }
                }
            }
        }
        found = NO;
    }
    NSMutableAttributedString* attribString = [[NSMutableAttributedString alloc] initWithString:endString attributes:nil];
    [attribString setFont:[UIFont systemFontOfSize:17]];
    for(DCStyleRange* range in collectRanges)
    {
        NSArray* array = range.attribs;
        if(!array && range.block)
            array = range.block(range.openTag,range.closeTag);
        if(array)
        {
            for(id object in array)
            {
                if([object isKindOfClass:[NSString class]])
                {
                    NSString* style = object;
                    if([style isEqualToString:DC_BOLD_TEXT])
                        [attribString setTextBold:YES range:NSMakeRange(range.start, range.end)];
                    else if([style isEqualToString:DC_ITALIC_TEXT])
                        [attribString setTextItalic:YES range:NSMakeRange(range.start, range.end)];
                    else if([style isEqualToString:DC_UNDERLINE_TEXT])
                        [attribString setTextIsUnderlined:YES range:NSMakeRange(range.start, range.end)];
                    else if([style isEqualToString:DC_STRIKE_THROUGH_TEXT])
                        [attribString setTextStrikeOut:YES range:NSMakeRange(range.start, range.end)];
                }
                else if([object isKindOfClass:[UIFont class]])
                {
                    UIFont* font = object;
                    [attribString setFont:font];
                }
                else if([object isKindOfClass:[UIColor class]])
                {
                    UIColor* color = object;
                    [attribString setTextColor:color range:NSMakeRange(range.start, range.end)];
                }
                else if([object isKindOfClass:[NSDictionary class]])
                {
                    for(id key in object)
                    {
                        id value = [object objectForKey:key];
                        if([key isEqualToString:DC_LINK_TEXT])
                            [attribString setTextIsHyperLink:value range:NSMakeRange(range.start, range.end)];
                        else if([key isEqualToString:DC_IMAGE_LINK])
                            [attribString addImage:value height:self.embedHeight width:self.embedWidth index:range.start];
                    }
                }
            }
        }
    }
    return attribString;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)processTag:(NSString*)tagName updateTag:(NSString**)updateTag string:(NSString*)string index:(int)index
{
    NSString* check = [string substringWithRange:NSMakeRange(index, tagName.length)];
    if([tagName isEqualToString:check])
        return YES;
    NSRange range = [tagName rangeOfString:@"?"];
    if(range.location != NSNotFound)
    {
        unichar end = [tagName characterAtIndex:range.location+1];
        NSString* last = [tagName substringFromIndex:range.location+1];
        int start = index+range.location;
        for(int i = start; i < string.length; i++)
        {
            if(end == [string characterAtIndex:i])
            {
                NSString* check = [string substringWithRange:NSMakeRange(i, last.length)];
                if([check isEqualToString:last])
                {
                    NSString* source = [string substringWithRange:NSMakeRange(start, i-start)];
                    *updateTag = [tagName stringByReplacingOccurrencesOfString:@"?" withString:source];
                    return YES;
                }
            }
        }
    }
    return NO;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//factory methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//html parser
+(DCParseEngine*)engineWithHTMLParser
{
    DCParseEngine* engine = [[DCParseEngine alloc] init];
    [engine addPattern:@"<b>" close:@"</b>" attributes:[NSArray arrayWithObject:DC_BOLD_TEXT]];
    [engine addPattern:@"<strong>" close:@"</strong>" attributes:[NSArray arrayWithObject:DC_BOLD_TEXT]];
    [engine addPattern:@"<i>" close:@"</i>" attributes:[NSArray arrayWithObject:DC_ITALIC_TEXT]];
    [engine addPattern:@"<em>" close:@"</em>" attributes:[NSArray arrayWithObject:DC_ITALIC_TEXT]];
    [engine addPattern:@"<a?>" close:@"</a>" block:^NSArray*(NSString* openTag,NSString* closeTag){
        NSRange range = [openTag rangeOfString:@"href="];
        int start = range.location + range.length + 1;
        range = [openTag rangeOfString:@" " options:0 range:NSMakeRange(start, openTag.length-start)];
        int end = 0;
        if(range.location != NSNotFound)
            end = range.location-2;
        else
            end = openTag.length-2;
        NSString* link = [openTag substringWithRange:NSMakeRange(start, end-start)];
        return [NSArray arrayWithObjects:[UIColor colorWithRed:0 green:0 blue:238.0f/255.0f alpha:1],[NSDictionary dictionaryWithObject:link forKey:DC_LINK_TEXT],nil];
    }];
    return engine;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//markdown parser
+(DCParseEngine*)engineWithMDParser
{
    DCParseEngine* engine = [[DCParseEngine alloc] init];
    [engine addPattern:@"***" close:@"***" attributes:[NSArray arrayWithObjects:DC_ITALIC_TEXT,DC_BOLD_TEXT, nil]];
    [engine addPattern:@"**" close:@"**" attributes:[NSArray arrayWithObject:DC_BOLD_TEXT]];
    [engine addPattern:@"*" close:@"*" attributes:[NSArray arrayWithObject:DC_ITALIC_TEXT]];
    [engine addPattern:@"___" close:@"___" attributes:[NSArray arrayWithObjects:DC_ITALIC_TEXT,DC_BOLD_TEXT, nil]];
    [engine addPattern:@"__" close:@"__" attributes:[NSArray arrayWithObject:DC_BOLD_TEXT]];
    [engine addPattern:@"_" close:@"_" attributes:[NSArray arrayWithObject:DC_ITALIC_TEXT]];
    [engine addPattern:@"![" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag){
        NSString* link = [closeTag substringWithRange:NSMakeRange(2, closeTag.length-3)];
        return [NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:link forKey:DC_IMAGE_LINK],nil];
    }];
    [engine addPattern:@"[" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag){
        NSString* link = [closeTag substringWithRange:NSMakeRange(2, closeTag.length-3)];
        return [NSArray arrayWithObjects:[UIColor colorWithRed:0 green:0 blue:238.0f/255.0f alpha:1],[NSDictionary dictionaryWithObject:link forKey:DC_LINK_TEXT],nil];
    }];
    return engine;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation DCParsePattern

@synthesize openTag,closeTag,attributes;

+(DCParsePattern*)patternWithTag:(NSString*)open close:(NSString*)close attribs:(NSArray*)attrs
{
    DCParsePattern* pattern = [[DCParsePattern alloc] init];
    pattern.openTag = open;
    pattern.closeTag = close;
    pattern.attributes = attrs;
    return pattern;
}

+(DCParsePattern*)patternWithTag:(NSString*)open close:(NSString*)close callback:(DCPatternBlock)block
{
    DCParsePattern* pattern = [[DCParsePattern alloc] init];
    pattern.openTag = open;
    pattern.closeTag = close;
    pattern.callback = block;
    return pattern;
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DCStyleRange

@synthesize attribs,closeTag,start,end,openTag,block;

@end
