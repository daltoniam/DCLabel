# DCLabel #

DCLabel extends UILabel attributedText property to make embedding images/video content simple. Also include is DCParseEngine that provides a powerful and customizable parsing engine to convert text tags to attributed strings. This allows simple html and markdown syntax to easy the burden of creating and customizing attributed strings.

# Example #

	- (void)viewDidLoad
	{
	    [super viewDidLoad];
	    int offset = 6;
	    DCLabel* label = [[DCLabel alloc] initWithFrame:CGRectMake(offset, offset, self.view.frame.size.width-(offset*2), self.view.frame.size.height-(offset*2))];
	    label.delegate = self;
	    [self.view addSubview:label];
		//HTML option
	    //NSString* text = [NSString stringWithFormat:@"hello <b>World</b>! This is <i>really</i> cool! Here is <a href='http://www.google.com/'>Google</a>."];
		//DCParseEngine* engine = [DCParseEngine engineWithHTMLParser];
	    //label.attributedText = [engine parse:text];
	    NSString* text = [NSString stringWithFormat:@"hello **World**! This is *really* cool! Here is [Google](http://www.google.com/). Now an image:\n![](http://imgs.xkcd.com/comics/subways.png)\nok now that is over:\n\n![](http://google.com)\n"];
		DCParseEngine* engine = [DCParseEngine engineWithMDParser];
	    engine.embedWidth = label.frame.size.width;
	    label.attributedText = [engine parse:text];
	    label.userInteractionEnabled = YES; //if you want to be able to tap hyperlinks or images
    
	    label.numberOfLines = 0; //allow the label text lines count to be unrestricted
	    CGRect frame = label.frame;
	    frame.size.height = [DCLabel suggestedHeight:label.attributedText width:frame.size.width];
	    label.frame = frame;
	}
	
	//delegate method
	-(UIView*)imageWillLoad:(NSString*)imgURL attributes:(NSDictionary*)attributes
	{
		//this is using my network imageView DCImageView. Feel free to use your favorite one.
		//you can find DCImageView here: https://github.com/daltoniam/DCImageView
	    DCImageView* imgView = [[DCImageView alloc] init];
	    imgView.showProgress = YES;
	    //imgView.contentMode = UIViewContentModeCenter;
	    imgView.URL = imgURL;
	    [imgView start];
	    return imgView;
	}
	
The engine can also be customized to support your own tags like so:

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
	
# Notes #

The ? character in the parsing engine is used as a wildcard. Currently only one wildcard per tag (both open and close tag can have there own) is supported at this time.

# Requirements #

This framework requires at least iOS 4 above. Xcode 4 is recommend.

# License #

DCLabel is license under the Apache License.

# Contact #

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam