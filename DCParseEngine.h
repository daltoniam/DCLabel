///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCParseEngine.h
//  iOSTester
//
//  Created by Dalton Cherry on 4/8/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

typedef NSArray* (^DCPatternBlock)(NSString* openTag,NSString* closeTag);


@interface DCParseEngine : NSObject
{
    NSMutableArray* patterns;
}

//add a pattern with this attributes to style the string.
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag attributes:(NSArray*)attribs;

//add a pattern with this attributes to style the string. Uses a block for a callback for styling that comes from the tags content
-(void)addPattern:(NSString*)openTag close:(NSString*)closeTag block:(DCPatternBlock)callback;

//start the parsing of string.
-(NSAttributedString*)parse:(NSString*)string;

//factory methods that create engines with default parsing syntax
+(DCParseEngine*)engineWithHTMLParser;
+(DCParseEngine*)engineWithMDParser;

//the height that image and videos will embed
@property(nonatomic,assign)float embedHeight;

//the width that image and videos will embed
@property(nonatomic,assign)float embedWidth;

@end
