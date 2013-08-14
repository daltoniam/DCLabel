///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCParseEngine.h
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
static NSString* const DC_HTML_ORDER_LIST = @"DCHTMLOrderedList";
static NSString* const DC_HTML_UNORDER_LIST = @"DCHTMLOrderedList";
static NSString* const DC_HTML_UNKNOWN_LIST = @"DCHTMLUnknown";
static NSString* const DC_TEXT_SIZE = @"DCTextSize";

typedef NSArray* (^DCPatternBlock)(NSString* openTag,NSString* closeTag,NSString* text);


@interface DCParseEngine : NSObject
{
    NSMutableArray* patterns;
}

//add a pattern with this attributes to style the string.
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs;

//add a pattern with this attributes to style the string. Uses a block for a callback for styling that comes from the tags content
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag block:(DCPatternBlock)callback;

//does the same as above, but can specific if tags are removed or not
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs keepOpen:(BOOL)open keepClose:(BOOL)close;

//does the same as above, but can specific if tags are removed or not
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag keepOpen:(BOOL)open keepClose:(BOOL)close block:(DCPatternBlock)callback;

//remove a pattern from the parser. Must be an exact match.
-(void)removePattern:(NSString*)openTag close:(NSString*)closeTag;

//'promote' a pattern to be first in the processing index.
-(void)promotePattern:(NSString*)openTag close:(NSString*)closeTag;

//start the parsing of string.
-(NSAttributedString*)parse:(NSString*)string;

//factory methods that create engines with default parsing syntax
+(DCParseEngine*)engineWithHTMLParser;
+(DCParseEngine*)engineWithMDParser;

//the height that image and videos will embed
@property(nonatomic,assign)float embedHeight;

//the width that image and videos will embed
@property(nonatomic,assign)float embedWidth;

//the default font you want. Default is system size 17
@property(nonatomic,assign)UIFont* font;

@end
