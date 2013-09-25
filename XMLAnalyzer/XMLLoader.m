//
//  XMLLoader.m
//  PhoCusWright
//
//  Created by Gavin Heer on 20/08/09.
//  Copyright 2009 QuickMobile. All rights reserved.
//

#import "XMLLoader.h"


@implementation XMLLoader

@synthesize xmlData,lastLoadedXMLData, url, isDone;

+ (NSString *)xmlFilePathFromResources:(NSString*)filename {
    return [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
}

-(id)initWithURL:(NSURL *)aURL {
	if (aURL == nil) {
		return nil;
	}
	
	if (self = [super init]) {
		url = aURL;	
	}
	
	return self;
}

-(id)initWithContentsOfFile:(NSString *)filepath {
 	if (self = [super init]) {
        self.xmlData  = [[NSMutableData alloc] initWithContentsOfFile:filepath];
        self.lastLoadedXMLData = [self.xmlData copy];

	}
	return self;
}

-(id)initWithData:(NSData *)data {
 	if (self = [super init]) {
        self.xmlData  = (NSMutableData*)data;
        self.lastLoadedXMLData = [self.xmlData copy];
  	}
	return self;
}


- (void)loadXML:(id<XMLLoaderDelegate>)delegate {
	_delegate = delegate;
	
	NSURLConnection *conn;
	NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
	if ([NSURLConnection canHandleRequest:request]) {
		conn = [NSURLConnection connectionWithRequest:request delegate:self];
		if (conn) {
			self.xmlData = [NSMutableData data];
		}
	}
}



- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// didReceiveResponse is called at the beginning of the request when
	// the connection is ready to receive data. We set the length to zero to
	// prepare the array to receive data
	[self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	// Each time we receive a chunk of data, we'll appeend it to the 
	// data array.
	[self.xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// When the data has all finished loading, we set a copy of the 
	// loaded data for us to access. This will allow us to not worry about whether
	// a load is already in progress when accessing the data.
	
	self.lastLoadedXMLData = [self.xmlData copy];
	 	
	// Make sure the _delegate object actually has the xmlDidFinishLoading
	// method, and if it does, call it to notify the delegate that the
	// data has finished loading.
	if ([_delegate respondsToSelector:@selector(xmlDidFinishLoading:)]) {
		[_delegate xmlDidFinishLoading:self];
	}
	
}

- (NSArray*)xmlParse {
	NSAssert([self isMemberOfClass:[XMLLoader class]] == NO, @"Object is of abstract base class XMLLoader");
	return NULL;
}


@end
