# DCLabel #

DCLabel extends UILabel attributedText property to make embedding images/video content simple. Also include is DCParseEngine that provides a powerful and customizable parsing engine to convert text tags to attributed strings. This allows simple html and markdown syntax to easy the burden of creating and customizing attributed strings.

# Example #

Convert this:
```objective-c
	@"hello **world**! This is an _example_ of what this can do!\nNow for a markdown list:\n 1. First\n 1. Second\n 1. Third\n \
	Here is [Google](http://www.google.com/). Now an image:\n![](http://imgs.xkcd.com/comics/subways.png)\nThe possiblities are endless!"
```


into this:

![](https://github.com/daltoniam/DCLabel/raw/screenshot/img/screenshot.png)

```objective-c
///////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString* text = @"hello **world**! This is an _example_ of what this can do!\nNow for a markdown list:\n 1. First\n 1. Second\n 1. Third\n \
    Here is [Google](http://www.google.com/). Now an image:\n![](http://imgs.xkcd.com/comics/subways.png)\nThe possiblities are endless!";
    DCParseEngine* engine = [DCParseEngine engineWithMDParser];
    int pad = 6;
    DCLabel* label = [[DCLabel alloc] initWithFrame:CGRectMake(pad, pad, self.view.frame.size.width-(pad*2), self.view.frame.size.height-(pad*2))];
    label.delegate = self;
    label.userInteractionEnabled = YES;
    engine.embedWidth = label.frame.size.width;
    engine.embedHeight = engine.embedWidth;
    label.attributedText = [engine parse:text];
    [self.view addSubview:label];
}
//DCLabel delegate methods
///////////////////////////////////////////////////////////////////////

-(UIView*)imageWillLoad:(NSString*)imgURL attributes:(NSDictionary*)attributes
{
	//this can be your favorite network image viewer, does not have to be DCImageView 
    DCImageView* imgView = [[DCImageView alloc] init];
    imgView.URL = imgURL;
    [imgView start];
    return imgView;
}
- (void)didSelectLink:(NSString*)link
{
    NSLog(@"open a webview or a custom view of your choosing");
}

- (void)didLongPressLink:(NSString*)link frame:(CGRect)frame
{
    NSLog(@"open an action of options (save,copy,open,etc)");
}

- (void)didSelectImage:(NSString*)imageURL
{
    NSLog(@"open a imageViewer or a custom view of your choosing");
}

- (void)didLongPressImage:(NSString*)imageURL
{
    NSLog(@"open an action of options (save,copy,open,etc)");
}
```

The engine can also be customized to support your own tags like so:
```objective-c
DCParseEngine* engine = [[DCParseEngine alloc] init];
[engine addPattern:@"**" close:@"**" attributes:@[DC_BOLD_TEXT]];
[engine addPattern:@"__" close:@"__" attributes:@[DC_BOLD_TEXT]];
[engine addPattern:@"*" close:@"*" attributes:@[DC_ITALIC_TEXT]];
[engine addPattern:@"_" close:@"_" attributes:@[DC_ITALIC_TEXT]];
[engine addPattern:@"![" close:@"](?)" block:^NSArray*(NSString* openTag,NSString* closeTag,NSString* text){
    NSString* link = [closeTag substringWithRange:NSMakeRange(2, closeTag.length-3)];
    return @[@{DC_IMAGE_LINK: link}];
}];
```
	
# Notes #

The ? character in the parsing engine is used as a wildcard. Currently only one wildcard per tag (both open and close tag can have there own) is supported at this time.

# Docs #

## DCLabel ##

This three properties add shadow to the text. All three of this methods work the same as the view.layer you get from quartz.
-  ```objective-c @property(nonatomic,strong)UIColor* textShadowColor;``` 

Set the shadow color. 
-  ```objective-c @property(nonatomic,assign)CGSize textShadowOffset;``` 

Set the offset of the shadow.
-  ```objective-c @property(nonatomic,assign)NSInteger textShadowBlur;``` 

Set the blur of the shadow.

- ```objective-c+(CGFloat)suggestedHeight:(NSAttributedString*)attributedText width:(int)width;``` 

returns the suggested height for the label based on the text and the width. This is very useful in determinting a TableViewCell/ScrollView height before drawing the label and adding it into the view hierarchy 

## DCLabel delegate Methods ##

-  ```objective-c - (void)didSelectLink:(NSString*)link;```
-  ```objective-c - (void)didLongPressLink:(NSString*)link frame:(CGRect)frame;```
-  ```objective-c - (void)didSelectImage:(NSString*)imageURL;```
-  ```objective-c - (void)didLongPressImage:(NSString*)imageURL;```

//return your imageView that loads the imgURL
-(UIView*)imageWillLoad:(NSString*)imgURL attributes:(NSDictionary*)attributes;

# Requirements #

This framework requires at least iOS 4 above. Xcode 4 is recommend.

# License #

DCLabel is license under the Apache License.

# Contact #

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam