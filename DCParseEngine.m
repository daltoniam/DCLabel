///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCParseEngine.m
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
@property(nonatomic,assign)BOOL keepTag;

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
@property(nonatomic,assign)BOOL keepTag;


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
    [self addPattern:openTag close:closeTag attributes:attribs keepTags:NO];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag block:(DCPatternBlock)callback
{
    [self addPattern:openTag close:closeTag keepTags:NO block:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//this is used when the attributes for a tag match will be known ahead of time. (e.g: hello *world* '*' bolds the text)
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs keepTags:(BOOL)keep
{
    [self purgePatterns:openTag close:closeTag];
    DCParsePattern* pattern = [DCParsePattern patternWithTag:openTag close:closeTag attribs:attribs];
    pattern.keepTag = keep;
    [patterns addObject:pattern];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag keepTags:(BOOL)keep block:(DCPatternBlock)callback
{
    [self purgePatterns:openTag close:closeTag];
    DCParsePattern* pattern = [DCParsePattern patternWithTag:openTag close:closeTag callback:callback];
    pattern.keepTag = keep;
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
            unichar currentChar = [string characterAtIndex:i];
            unichar checkChar = [range.closeTag characterAtIndex:0];
            BOOL isTag = NO;
            BOOL match = NO;
            if(checkChar == currentChar)
                match = YES;
            else if(isspace(checkChar) && (isspace(currentChar) || currentChar == '\n' || i == string.length-1) && range.closeTag.length == 1 )
            {
                isTag = YES;
                match = YES;
                if(i == string.length-1)
                    i++;
            }
            if(match)
            {
                NSString* uTag = nil;
                if(!isTag)
                    isTag = [self processTag:range.closeTag updateTag:&uTag string:string index:i];
                if(uTag)
                    range.closeTag = uTag;
                if(isTag)
                {
                    int totalChange = 0;
                    range.end = (i-offset) - range.start;
                    if(!range.keepTag)
                    {
                        range.end -= range.openTag.length;
                        //NSLog(@"start: %d endString length: %d",range.start-offset,endString.length);
                        if(range.start > -1 && range.start+range.openTag.length <= endString.length)
                        {
                            endString = [endString stringByReplacingCharactersInRange:NSMakeRange(range.start, range.openTag.length) withString:@""];
                            offset += range.openTag.length;
                            totalChange += range.openTag.length;
                        }
                    }

                    if(!range.keepTag)
                    {
                        //NSLog(@"i %d end: %d length: %d",i,(i-offset)+range.closeTag.length,endString.length);
                        int len = (i-offset)+range.closeTag.length;
                        if(len <= endString.length)
                        {
                            endString = [endString stringByReplacingCharactersInRange:NSMakeRange(i-offset, range.closeTag.length) withString:@""];
                            offset += range.closeTag.length;
                            totalChange += range.closeTag.length;
                        }
                    }
                    //if(range.keepTag)
                    i += range.closeTag.length-1;
                    
                    /*if(range.end == 0)
                        embedOffset++;
                    else
                        range.end += embedOffset;*/
                    [currentRanges removeObject:range];
                    //update the offset of the tag after this one
                    if(totalChange > 0)
                    {
                        int index = [collectRanges indexOfObject:range];
                        for(int i = index; i < collectRanges.count-1; i++)
                        {
                            DCStyleRange* range = [collectRanges objectAtIndex:i];
                            range.start -= totalChange;
                        }
                    }
                    //clean up any pattern that is no longer needed
                    NSMutableArray* removeArray = nil;
                    for(DCStyleRange* range in currentRanges)
                    {
                        if(range.start+range.end > endString.length)
                        {
                            if(!removeArray)
                                removeArray = [NSMutableArray array];
                            [removeArray addObject:range];
                        }
                    }
                    [currentRanges removeObjectsInArray:removeArray];
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
                        //NSLog(@"pattern openTag: %@",pattern.openTag);
                        //NSLog(@"open tag: %d",i);
                        DCStyleRange* range = [[DCStyleRange alloc] init];
                        range.start = i-offset;
                        range.attribs = pattern.attributes;
                        range.closeTag = pattern.closeTag;
                        range.openTag = pattern.openTag;
                        range.block = pattern.callback;
                        range.keepTag = pattern.keepTag;
                        [currentRanges addObject:range];
                        [collectRanges addObject:range];
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
    //NSLog(@"endString: %@",endString);
    int embedOffset = 0; //when a view is embed, we the end ranges of links get messed up
    NSMutableAttributedString* attribString = [[NSMutableAttributedString alloc] initWithString:endString attributes:nil];
    [attribString setFont:[UIFont systemFontOfSize:17]];
    for(DCStyleRange* range in collectRanges)
    {
        if(range.start != NSNotFound && range.start > -1 && range.start+range.end <= endString.length && range.end != NSNotFound)
        {
            NSRange rangeLoc = NSMakeRange(range.start, range.end);
            NSArray* array = range.attribs;
            if(!array && range.block)
                array = range.block(range.openTag,range.closeTag,[endString substringWithRange:rangeLoc]);
            if(array)
            {
                range.start += embedOffset;
                //range.end += embedOffset;
                rangeLoc.location += embedOffset;
                for(id object in array)
                {
                    if([object isKindOfClass:[NSString class]])
                    {
                        NSRange rangeText = rangeLoc;
                        rangeText.location -= embedOffset;   
                        NSString* style = object;
                        if([style isEqualToString:DC_BOLD_TEXT])
                            [attribString setTextBold:YES range:rangeText];
                        else if([style isEqualToString:DC_ITALIC_TEXT])
                            [attribString setTextItalic:YES range:rangeText];
                        else if([style isEqualToString:DC_UNDERLINE_TEXT])
                            [attribString setTextIsUnderlined:YES range:rangeText];
                        else if([style isEqualToString:DC_STRIKE_THROUGH_TEXT])
                            [attribString setTextStrikeOut:YES range:rangeText];
                    }
                    else if([object isKindOfClass:[UIFont class]])
                    {
                        UIFont* font = object;
                        [attribString setFont:font range:rangeLoc];
                    }
                    else if([object isKindOfClass:[UIColor class]])
                    {
                        UIColor* color = object;
                        [attribString setTextColor:color range:rangeLoc];
                    }
                    else if([object isKindOfClass:[NSDictionary class]])
                    {
                        //[attribString addAttributes:object range:rangeLoc];
                        for(id key in object)
                        {
                            id value = [object objectForKey:key];
                            if([key isEqualToString:DC_IMAGE_LINK])
                            {
                                float h = [[object objectForKey:@"height"] floatValue];
                                float w = [[object objectForKey:@"width"] floatValue];
                                if(h <= 0)
                                    h = self.embedHeight;
                                if(w <= 0)
                                    w = self.embedWidth;
                                [attribString addImage:value height:h width:w index:range.start attributes:object];
                                embedOffset++;
                            }
                            else if([key isEqualToString:DC_LINK_TEXT])
                                [attribString setTextIsHyperLink:value range:rangeLoc];
                            else
                                [attribString addAttribute:key value:value range:rangeLoc];
                        }
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
    if(index+tagName.length > string.length)
        return NO;
    NSString* check = [string substringWithRange:NSMakeRange(index, tagName.length)];
    if([tagName isEqualToString:check])
        return YES;
    //NSLog(@"tagName: %@",tagName);
    NSRange range = [tagName rangeOfString:@"?"];
    if(range.location != NSNotFound)
    {
        NSString* valid = [string substringWithRange:NSMakeRange(index, range.location)];
        if([valid isEqualToString:[tagName substringToIndex:range.location]] && range.location != string.length)
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
                        //NSLog(@"updateTag: %@",*updateTag);
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)purgePatterns:(NSString*)openTag close:(NSString*)closeTag
{
    for(DCParsePattern* pattern in patterns)
    {
        if([pattern.closeTag isEqualToString:closeTag] && [pattern.openTag isEqualToString:openTag])
        {
            [patterns removeObject:pattern];
            return;
        }
    }
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
    [engine addPattern:@"<a?>" close:@"</a>" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
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
    [engine addPattern:@"![" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        NSString* link = [closeTag substringWithRange:NSMakeRange(2, closeTag.length-3)];
        return [NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:link forKey:DC_IMAGE_LINK],nil];
    }];
    [engine addPattern:@"[" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
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
