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
@property(nonatomic,assign)BOOL keepOpen;
@property(nonatomic,assign)BOOL keepClose;

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
@property(nonatomic,assign)BOOL keepOpen;
@property(nonatomic,assign)BOOL keepClose;


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
        self.font = [UIFont systemFontOfSize:17];
    }
    return self;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//this is used when the attributes for a tag match will be known ahead of time. (e.g: hello *world* '*' bolds the text)
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs
{
    [self addPattern:openTag close:closeTag attributes:attribs keepOpen:NO keepClose:NO];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag block:(DCPatternBlock)callback
{
    [self addPattern:openTag close:closeTag keepOpen:NO keepClose:NO block:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//this is used when the attributes for a tag match will be known ahead of time. (e.g: hello *world* '*' bolds the text)
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs keepOpen:(BOOL)open keepClose:(BOOL)close
{
    [self removePattern:openTag close:closeTag];
    DCParsePattern* pattern = [DCParsePattern patternWithTag:openTag close:closeTag attribs:attribs];
    pattern.keepOpen = open;
    pattern.keepClose = close;
    [patterns addObject:pattern];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag keepOpen:(BOOL)open keepClose:(BOOL)close block:(DCPatternBlock)callback
{
    [self removePattern:openTag close:closeTag];
    DCParsePattern* pattern = [DCParsePattern patternWithTag:openTag close:closeTag callback:callback];
    pattern.keepOpen = open;
    pattern.keepClose = close;
    [patterns addObject:pattern];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)removePattern:(NSString*)openTag close:(NSString*)closeTag
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
-(void)promotePattern:(NSString*)openTag close:(NSString*)closeTag
{
    for(DCParsePattern* pattern in patterns)
    {
        if([pattern.closeTag isEqualToString:closeTag] && [pattern.openTag isEqualToString:openTag])
        {
            [patterns removeObject:pattern];
            [patterns insertObject:pattern atIndex:0];
            return;
        }
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSAttributedString*)parse:(NSString*)string
{
    NSString* endString = [NSString stringWithString:string];
    int offset = 0;
    NSMutableArray* currentRanges = [NSMutableArray array];
    NSMutableArray* collectRanges = [NSMutableArray array];
    BOOL found = NO;
    //unichar turtleFace = [string characterAtIndex:string.length-1];
    //NSLog(@"currentChar: %c",turtleFace);
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
            else if(isspace(checkChar) && (isspace(currentChar) || currentChar == '\n' || i == string.length-1) && range.closeTag.length == 1 &&
                    ![range.closeTag isEqualToString:@"\n"])
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
                    if(!range.keepOpen)
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

                    if(!range.keepClose)
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
                    /*if(totalChange > 0)
                    {
                        int index = [collectRanges indexOfObject:range];
                        for(int i = index; i < collectRanges.count-1; i++)
                        {
                            DCStyleRange* range = [collectRanges objectAtIndex:i];
                            range.start -= totalChange;
                            if(range.start < 0)
                                range.start = 0;
                        }
                    }*/
                    //clean up any pattern that is no longer needed
                    NSMutableArray* removeArray = nil;
                    for(DCStyleRange* checkRange in currentRanges)
                    {
                        if(checkRange.start+checkRange.end > endString.length || [checkRange.openTag isEqualToString:range.openTag])
                        {
                            if(!removeArray)
                                removeArray = [NSMutableArray array];
                            [removeArray addObject:checkRange];
                        }
                    }
                    [currentRanges removeObjectsInArray:removeArray];
                    for(DCStyleRange* checkRange in collectRanges)
                    {
                        if(checkRange.start > range.start && checkRange.end < range.end && checkRange != range)
                            checkRange.start -= range.openTag.length;
                    }
                    found = YES;
                    break;
                }
            }
        }
        if(!found)
        {
            int ind = 0;
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
                        DCStyleRange* range = nil;
                        for(DCStyleRange* oldRange in currentRanges)
                        {
                            if([oldRange.openTag isEqualToString:pattern.openTag] && [oldRange.closeTag isEqualToString:pattern.closeTag])
                            {
                                range = oldRange;
                                break;
                            }
                        }
                        //NSLog(@"pattern openTag: %@",pattern.openTag);
                        //NSLog(@"open tag: %d",i);
                        if(!range)
                        {
                            range = [[DCStyleRange alloc] init];
                            [currentRanges addObject:range];
                            [collectRanges addObject:range];
                        }
                        range.start = i-offset;
                        [self updateRange:range pattern:pattern];
                        i += pattern.openTag.length-1;
                        if(uTag)
                            pattern.openTag = currentTag;
                        //add any other patterns with the same openingTag and different closing tag
                        for(int k = ind+1; k < patterns.count; k++)
                        {
                            DCParsePattern* match = [patterns objectAtIndex:k];
                            if([match.openTag isEqualToString:pattern.openTag])
                            {
                                DCStyleRange* matchRange = [[DCStyleRange alloc] init];
                                matchRange.start = range.start;
                                [self updateRange:matchRange pattern:match];
                                [currentRanges addObject:matchRange];
                                [collectRanges addObject:matchRange];
                            }
                        }
                        break;
                    }
                }
                ind++;
            }
        }
        found = NO;
    }
    //NSLog(@"endString: %@",endString);
    int numIndex = 0;
    int embedOffset = 0; //when a view is embed, we the end ranges of links get messed up
    NSMutableAttributedString* attribString = [[NSMutableAttributedString alloc] initWithString:endString attributes:nil];
    [attribString setFont:self.font];
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
                        if(rangeText.location == 0 && rangeText.length == 0)
                            continue;
                        if([style isEqualToString:DC_BOLD_TEXT])
                            [attribString setTextBold:YES range:rangeText];
                        else if([style isEqualToString:DC_ITALIC_TEXT])
                            [attribString setTextItalic:YES range:rangeText];
                        else if([style isEqualToString:DC_UNDERLINE_TEXT])
                            [attribString setTextIsUnderlined:YES range:rangeText];
                        else if([style isEqualToString:DC_STRIKE_THROUGH_TEXT])
                            [attribString setTextStrikeOut:YES range:rangeText];
                        else if([style isEqualToString:DC_UNORDERED_LIST])
                            [attribString setUnOrderedList:rangeText.location-1];
                        else if([style isEqualToString:DC_ORDERED_LIST])
                            [attribString setOrderedList:rangeText.location-1 number:++numIndex];
                        else if([style isEqualToString:DC_HTML_UNKNOWN_LIST])
                        {
                            NSDictionary* attributes = [attribString attributesAtIndex:rangeText.location effectiveRange:NULL];
                            if(attributes[DC_HTML_ORDER_LIST])
                                [attribString setOrderedList:rangeText.location-1 number:++numIndex];
                            else
                                [attribString setUnOrderedList:rangeText.location-1];
                        }
                        
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
                            else if([key isEqualToString:DC_TEXT_SIZE])
                                [attribString setTextSize:[value floatValue] range:rangeLoc];
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
-(void)updateRange:(DCStyleRange*)range pattern:(DCParsePattern*)pattern
{
    range.attribs = pattern.attributes;
    range.closeTag = pattern.closeTag;
    range.openTag = pattern.openTag;
    range.block = pattern.callback;
    range.keepOpen = pattern.keepOpen;
    range.keepClose = pattern.keepClose;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//factory methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//html parser
+(DCParseEngine*)engineWithHTMLParser
{
    DCParseEngine* engine = [[DCParseEngine alloc] init];
    [engine addPattern:@"<b>" close:@"</b>" attributes:@[DC_BOLD_TEXT]];
    [engine addPattern:@"<strong>" close:@"</strong>" attributes:@[DC_BOLD_TEXT]];
    [engine addPattern:@"<i>" close:@"</i>" attributes:@[DC_ITALIC_TEXT]];
    [engine addPattern:@"<em>" close:@"</em>" attributes:@[DC_ITALIC_TEXT]];
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
        return @[[UIColor colorWithRed:0 green:0 blue:238.0f/255.0f alpha:1],@{DC_LINK_TEXT: link}];
    }];
    [engine addPattern:@"<img?>" close:@"</img>" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        NSMutableDictionary* dict = [DCParseEngine processAttributes:openTag];
        if(dict[@"src"])
            [dict setObject:dict[@"src"] forKey:DC_IMAGE_LINK];
        if(dict)
            return @[dict];
        return nil;
    }];
    [engine addPattern:@"<img?/>" close:@" " block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        NSMutableDictionary* dict = [DCParseEngine processAttributes:openTag];
        if(dict[@"src"])
            [dict setObject:dict[@"src"] forKey:DC_IMAGE_LINK];
        if(dict)
            return @[dict];
        return nil;
    }];
    [engine addPattern:@"<p>" close:@"</p>" attributes:nil];
    [engine addPattern:@"<ol>" close:@"</ol>" attributes:@[@{DC_HTML_ORDER_LIST: [NSNumber numberWithBool:YES]}]];
    [engine addPattern:@"<ul>" close:@"</ul>" attributes:@[@{DC_HTML_UNORDER_LIST: [NSNumber numberWithBool:YES]}]];
    [engine addPattern:@"<li>" close:@"</li>" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        return @[DC_HTML_UNKNOWN_LIST];
    }];
    [engine addPattern:@"<span?>" close:@"</span>" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        
        NSMutableArray* collect = [NSMutableArray array];
        NSRange find = [openTag rangeOfString:@"font-size:"];
        if(find.location != NSNotFound)
        {
            int pos = find.location+find.length;
            NSRange end = [openTag rangeOfString:@";" options:0 range:NSMakeRange(pos, [openTag length]-pos)];
            if(end.location == NSNotFound)
                end = [openTag rangeOfString:@"'" options:0 range:NSMakeRange(pos, [openTag length]-pos)];
            if(end.location == NSNotFound)
                end = [openTag rangeOfString:@"\"" options:0 range:NSMakeRange(pos, [openTag length]-pos)];
            if(end.location == NSNotFound)
                end = NSMakeRange([openTag length],0);
            CGFloat size = [[openTag substringWithRange:end] floatValue];
            if(size > 0)
                [collect addObject:@{DC_TEXT_SIZE: [NSNumber numberWithFloat:size]}];
        }
        find = [openTag rangeOfString:@"text-decoration:"];
        if(find.location != NSNotFound)
        {
            int pos = find.location+find.length;
            if(pos != NSNotFound && openTag.length > pos)
            {
                NSString* decorations = [openTag substringWithRange:NSMakeRange(pos, [openTag length]-pos)];
                if([decorations rangeOfString:@"line-through"].location != NSNotFound)
                    [collect addObject:DC_UNDERLINE_TEXT];
                if([decorations rangeOfString:@"underline"].location != NSNotFound)
                    [collect addObject:DC_STRIKE_THROUGH_TEXT];
            }
        }
        find = [openTag rangeOfString:@"color:"];
        if(find.location != NSNotFound)
        {
            int pos = find.location+find.length;
            NSRange end = [openTag rangeOfString:@";" options:0 range:NSMakeRange(pos, [openTag length]-pos)];
            if(end.location == NSNotFound)
                end = [openTag rangeOfString:@" " options:0 range:NSMakeRange(pos, [openTag length]-pos)];
            if(end.location == NSNotFound)
                end = [openTag rangeOfString:@"\n" options:0 range:NSMakeRange(pos, [openTag length]-pos)];
            if(end.location != NSNotFound)
            {
                NSString* cssstring = [openTag substringWithRange:NSMakeRange(pos, end.location-pos)];
                cssstring = [DCParseEngine trimWhiteSpace:cssstring];
                if([cssstring hasPrefix:@"#"] && cssstring.length > 3)
                    [collect addObject:[DCParseEngine colorFromHexCode:cssstring]];
                else if([cssstring hasPrefix:@"rgb("])
                {
                    NSRange rRange = [cssstring rangeOfString:@"("];
                    NSRange eRange = [cssstring rangeOfString:@")"];
                    rRange.location += 1;
                    if(rRange.location != NSNotFound && eRange.location != NSNotFound)
                    {
                        NSString* value = [cssstring substringWithRange:NSMakeRange(rRange.location, eRange.location-rRange.location)];
                        NSArray* vals = [value componentsSeparatedByString:@","];
                        if(vals.count == 3)
                        {
                            UIColor* color = [UIColor colorWithRed:[[DCParseEngine trimWhiteSpace:vals[0]] floatValue]/255.0f
                                                             green:[[DCParseEngine trimWhiteSpace:vals[1]] floatValue]/255.0f
                                                              blue:[[DCParseEngine trimWhiteSpace:vals[2]] floatValue]/255.0f alpha:1];
                            [collect addObject:color];
                        }
                    }
                }
            }
        }

        
        return collect;
    }];
    return engine;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//markdown parser
+(DCParseEngine*)engineWithMDParser
{
    DCParseEngine* engine = [[DCParseEngine alloc] init];
    [engine addPattern:@"**" close:@"**" attributes:@[DC_BOLD_TEXT]];
    [engine addPattern:@"__" close:@"__" attributes:@[DC_BOLD_TEXT]];
    [engine addPattern:@"*" close:@"*" attributes:@[DC_ITALIC_TEXT]];
    [engine addPattern:@"_" close:@"_" attributes:@[DC_ITALIC_TEXT]];
    [engine addPattern:@"![" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        NSString* link = [closeTag substringWithRange:NSMakeRange(2, closeTag.length-3)];
        return @[@{DC_IMAGE_LINK: link}];
    }];
    [engine addPattern:@"[" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        NSString* link = [closeTag substringWithRange:NSMakeRange(2, closeTag.length-3)];
        return @[[UIColor colorWithRed:0 green:0 blue:238.0f/255.0f alpha:1],@{DC_LINK_TEXT: link}];
    }];
    [engine addPattern:@"-" close:@" " keepOpen:NO keepClose:YES block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        return @[DC_UNORDERED_LIST];
    }];
    [engine addPattern:@"+" close:@" " keepOpen:NO keepClose:YES block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
        return @[DC_UNORDERED_LIST];
    }];
    for(int i = 1; i < 10; i++)
    {
        [engine addPattern:[NSString stringWithFormat:@"%d.",i] close:@" " keepOpen:NO keepClose:YES block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
            return @[DC_ORDERED_LIST];
        }];
    }
    int fontSize = 11;
    NSString* tag = @"######";
    for(int i = 0; i < 6; i++)
    {
        [engine addPattern:tag close:tag attributes:[NSArray arrayWithObjects:[UIFont boldSystemFontOfSize:fontSize], nil]];
        [engine addPattern:tag close:@"\n" attributes:[NSArray arrayWithObjects:[UIFont boldSystemFontOfSize:fontSize], nil] keepOpen:NO keepClose:YES];
        fontSize += 2;
        if(tag.length > 1)
            tag = [tag substringFromIndex:1];
    }
    return engine;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSMutableDictionary*)processAttributes:(NSString*)string
{
    NSArray* attrArray = [string componentsSeparatedByString:@" "];
    if([attrArray lastObject])
    {
        NSString* val = [attrArray lastObject];
        if([val hasSuffix:@">"])
        {
            val = [val substringToIndex:val.length-1];
            NSMutableArray* array = [NSMutableArray arrayWithArray:attrArray];
            [array replaceObjectAtIndex:array.count-1 withObject:val];
            attrArray = array;
        }
    }
    NSMutableArray* collect = [NSMutableArray arrayWithCapacity:attrArray.count];
    for(int i = 1; i < attrArray.count; i++)
    {
        NSString* string = [attrArray objectAtIndex:i];
        if(([string rangeOfString:@"="].location == NSNotFound || [string isEqualToString:@"="]) && collect.count > 0)
        {
            NSString* last = [collect lastObject];
            if([last characterAtIndex:last.length-1] == '\'' || [last characterAtIndex:last.length-1] == '\"')
                [collect addObject:string];
            else
            {
                last = [last stringByAppendingFormat:@" %@",string];
                [collect removeLastObject];
                [collect addObject:last];
            }
        }
        else
            [collect addObject:string];
    }
    if(collect.count > 0)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:attrArray.count];
        for(NSString* attr in collect)
        {
            NSRange split = [attr rangeOfString:@"="];
            if(split.location != NSNotFound)
            {
                NSString* value = [attr substringWithRange:NSMakeRange(split.location+1, attr.length-(split.location+1))];
                value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
                NSString* key = [attr substringWithRange:NSMakeRange(0, split.location)];
                if(key.length > 0)
                {
                    key = [key stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    key = [key stringByReplacingOccurrencesOfString:@"'" withString:@""];
                    [dict setObject:value forKey:key];
                }
            }
        }
        return dict;
    }
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)trimWhiteSpace:(NSString*)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(UIColor*)colorFromHexCode:(NSString *)hexString
{
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3)
    {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6)
        cleanString = [cleanString stringByAppendingString:@"ff"];
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
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
