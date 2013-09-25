//
//  XMLLoader.h
//  PhoCusWright
//
//  Created by Gavin Heer on 20/08/09.
//  Copyright 2009 QuickMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@protocol XMLLoaderDelegate
- (void)xmlDidFinishLoading:(NSObject *)classType;
@end


@interface XMLLoader : NSObject {
	id _delegate;
	NSMutableData *xmlData;
	NSMutableData *lastLoadedXMLData;
	NSURL *url;
	BOOL isDone;
}


+ (NSString *)xmlFilePathFromResources:(NSString*)filename;

- (id)initWithContentsOfFile:(NSString *)filepath ;
- (id)initWithURL:(NSURL *)aURL;

- (void)loadXML:(id<XMLLoaderDelegate>)delegate;
- (NSArray*)xmlParse;
-(id)initWithData:(NSData *)data;

@property (nonatomic, strong) NSMutableData *xmlData;
@property (nonatomic, strong) NSMutableData *lastLoadedXMLData;
@property (nonatomic, copy)   NSURL *url;
@property (nonatomic, assign) BOOL isDone;

@end
