//
//  MasterViewController.h
//  XMLAnalyzer
//
//  Created by Mona Erfani on 2013-06-24.
//  Copyright (c) 2013 Mona Erfani. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>

@interface MasterViewController : NSViewController
    
@property (nonatomic, strong) NSMutableData *xmlData;
@property (nonatomic, strong) NSString *xmlType;
@property (nonatomic, strong) NSTextField *instructionLabel;
@property (nonatomic, strong) NSTextField *summaryLabel;
@property (nonatomic, strong) NSButton *myButton;
@property (nonatomic, strong) NSMutableString *csvString;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, assign) NSInteger statusCode;


@property (nonatomic, strong) NSURL * jiraUrl;

- (IBAction)selectFile;

@end
