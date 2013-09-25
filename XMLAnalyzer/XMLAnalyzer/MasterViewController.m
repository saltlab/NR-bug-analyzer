//
//  MasterViewController.m
//  XMLAnalyzer
//
//  Created by Mona Erfani on 2013-06-24.
//  Copyright (c) 2013 Mona Erfani. All rights reserved.
//

#import "MasterViewController.h"
#import "XMLLoader.h"
#import "TouchXML.h"
#import "XMLWriter.h"
#import "TFHpple.h"

//#define URL @"https://tracker.moodle.org/browse/" //Moodle
#define URL @"https://bugzilla.mozilla.org/show_activity.cgi?id=" //Firefox
//#define URL @"https://bugs.eclipse.org/bugs/show_activity.cgi?id="  //Eclipse
//#define URL @"https://bugzilla.wikimedia.org/show_activity.cgi?id="   //Wikimedia

//#define QM 1
#define QM 0

@interface MasterViewController ()

@end

@implementation MasterViewController

@synthesize xmlData, xmlType, csvString, responseData, statusCode, jiraUrl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)awakeFromNib
{
    //Start from bottom left corner
    self.instructionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(60, 250, 400, 40)];
    [self.instructionLabel setStringValue:@"Choose a Jira/Bugzilla XML file to split to its bug reports and analyze them!"];
    [self.instructionLabel setBezeled:NO];
    [self.instructionLabel setDrawsBackground:NO];
    [self.instructionLabel setEditable:NO];
    [self.instructionLabel setSelectable:NO];
    [self.view addSubview:self.instructionLabel];
    
    self.myButton = [[NSButton alloc] initWithFrame:NSMakeRect(320, 200, 100, 40)];
    [self.view addSubview: self.myButton];
    [self.myButton setTitle: @"Upload File"];
    [self.myButton setButtonType:NSMomentaryLightButton];
    [self.myButton setBezelStyle:NSRoundedBezelStyle];
    [self.myButton setTarget:self];
    [self.myButton setAction:@selector(selectFile)];
    
    self.summaryLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(60, 100, 400, 50)];
    [self.summaryLabel setBezeled:NO];
    [self.summaryLabel setDrawsBackground:NO];
    [self.summaryLabel setEditable:NO];
    [self.summaryLabel setSelectable:NO];
    
    self.csvString = [[NSMutableString alloc] init];
    
}

- (void)selectFile
{
    //create the File Open Dialog class
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    //enable the selection of files in the dialog
    [openDlg setCanChooseFiles:YES];
    //enable the selection of directories in the dialog
    [openDlg setCanChooseDirectories:YES];

    //display the dialog.  If the OK button was pressed, process the files
    if ([openDlg runModal] == NSOKButton)
    {
        //get an array containing the full filenames of all files and directories selected
        [self xmlSplit:[openDlg URLs]];
    }
}

-(void) xmlSplit:(NSArray*)urls
{
    NSURL *filePath = [urls objectAtIndex:0];
    NSString* fileName = [filePath lastPathComponent];
    
    //check if it is an xml file
    NSRange range = [fileName rangeOfString:@".xml" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound && range.location + range.length == [fileName length])
    {
        self.xmlData = [NSMutableData dataWithContentsOfURL:filePath];
        CXMLDocument* xmlParser = [[CXMLDocument alloc] initWithData:self.xmlData options:0 error:nil];
        NSArray* resultNodes = nil;
        
        //check if it is Jira file
        NSRange jiraRange = [fileName rangeOfString:@"Jira" options:NSCaseInsensitiveSearch];
        //check if it is Bugzilla file
        NSRange bugzillaRange = [fileName rangeOfString:@"Bugzilla" options:NSCaseInsensitiveSearch];
        
        if (jiraRange.location != NSNotFound)
        {
            if (self.xmlData) {
                self.xmlType = @"Jira";
                [self.csvString appendString:@"BugID, ResolutionTime, BugStatus, BugResolution, NumberComments,  NumberAuthors, NumberWatches, BugStatusHistory, BugResolutionHistory, BugStatusResolutionHistory \n"]; 
                [self createXMLFilesDirectory];
                NSUInteger i;
                resultNodes = [xmlParser nodesForXPath:@"//channel/item" error:nil];
                for (CXMLElement* resultElement in resultNodes) {
                CXMLElement* resultElement = [resultNodes objectAtIndex:i];
                    [self parseJiraXMLFiles:resultElement];
                    
                    i= [resultNodes indexOfObject:resultElement] + 1;
                    //[self writeXMLFile:resultElement withIndex:i];
                }
                [self.summaryLabel setStringValue:[NSString stringWithFormat:@"Summary: \nThere are %ld bug reports in this %@ file, which are saved in ../Documents/XMLBugReports/", (unsigned long)i, self.xmlType]];
                [self.view addSubview:self.summaryLabel];
                [self outputCSVFile];
            }
        }
        else if (bugzillaRange.location != NSNotFound)
        {
            if (self.xmlData) {
                self.xmlType = @"Bugzilla";
                [self.csvString appendString:@"BugID, ResolutionTime, BugStatus, BugResolution, NumberComments,  NumberAuthors, NumberCC, BugStatusHistory, BugResolutionHistory, BugStatusResolutionHistory \n"];
                [self createXMLFilesDirectory];
                NSUInteger i;
                resultNodes = [xmlParser nodesForXPath:@"//bugzilla/bug" error:nil];
                for (CXMLElement* resultElement in resultNodes) {
                    [self parseXMLFiles:resultElement];
                    i= [resultNodes indexOfObject:resultElement] + 1;
                    //[self writeXMLFile:resultElement withIndex:i];
                }
                [self.summaryLabel setStringValue:[NSString stringWithFormat:@"Summary: %ld bug reports and their metrics are saved in ../Documents/XMLBugReports/", (unsigned long)i]];
                [self.view addSubview:self.summaryLabel];
                [self outputCSVFile];
            }
        }
        else
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"This XML file is not defined. Please select Jira/Bugzilla XML file."];
            [alert runModal];
        }
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"This is not an XML file. Please select an XML file."];
        [alert runModal];
    }
}

- (void)parseJiraXMLFiles:(CXMLElement*)resultElement {
    
    //add bug ID
    NSArray *bugIdNodes = [resultElement elementsForName:@"key"];
    NSString *bugId = [[bugIdNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugId]];
    
    //add resolution time
    NSArray *creationTimeNodes = [resultElement elementsForName:@"created"];
    NSString *creationTime = [creationTimeNodes count]>0 ? [[creationTimeNodes objectAtIndex:0] stringValue] : @"";
    NSArray *updatedTimeNodes = [resultElement elementsForName:@"updated"];
    NSString *updatedTime = [updatedTimeNodes count]>0 ? [[updatedTimeNodes objectAtIndex:0] stringValue]  : @"";
    NSArray *endTimeNodes = [resultElement elementsForName:@"resolved"];
    NSString *endTime = [endTimeNodes count]>0 ? [[endTimeNodes objectAtIndex:0] stringValue] : @"";
    if ([endTime isEqualToString:@""])
        [self getTimeDifferenceJira:creationTime with:updatedTime];
    else
        [self getTimeDifferenceJira:creationTime with:endTime];
    
    //add bug status
    NSArray *statusNodes = [resultElement elementsForName:@"status"];
    NSString *bugStatus = [[statusNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugStatus]];
    
    //add bug resolution
    NSArray *resolutionNodes = [resultElement elementsForName:@"resolution"];
    NSString *bugResolution = [[resolutionNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugResolution]];
    
    //add number of comments and authors
    NSArray *cmtsNodes = [resultElement elementsForName:@"comments"];
    NSArray *cmtNodes;
    NSMutableArray *authorNames = [[NSMutableArray alloc] init];
    
    for (CXMLElement *cmtNode in cmtsNodes) {
        
        //add number of comments
        cmtNodes = [cmtNode elementsForName:@"comment"];
        int noCmt = (int)[cmtNodes count];
        [self.csvString appendString:[NSString stringWithFormat:@"%i, ", noCmt]];
    
        //add number of authors
        for (CXMLElement *node in cmtNodes) {
            NSArray* authorNodes = [node attributes];
            for (CXMLNode *node in authorNodes) {
                NSString *attName = [node name];
                if ([attName isEqualToString:@"author"]) {
                    NSString *authorName = [node stringValue];
                    if (![authorNames containsObject:authorName])
                        [authorNames addObject:authorName];
                }
            }
        }
    }

    int noAuthors = (int)[authorNames count];
    [self.csvString appendString:[NSString stringWithFormat:@"%i, ", noAuthors]];
    
    //add number of watches
    NSArray *ccNodes = [resultElement elementsForName:@"watches"];
    NSString *watches = [[ccNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@,", watches]];
    
    
    //add status and resolution history
//    if ([bugId length]>0){
//        //add status and resolution history
//        if (QM == 1)
//            [self dowloadQMURLContent:bugId];
//        else
//            [self dowloadURLContent:bugId];
//    }
//    else
        [self.csvString appendString:@"\n"];
    
}

- (void)parseXMLFiles:(CXMLElement*)resultElement {
    
    //add bug ID
    NSArray *bugIdNodes = [resultElement elementsForName:@"bug_id"];
    NSString *bugId = [[bugIdNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugId]];
    
    //add resolution time
    NSArray *creationTimeNodes = [resultElement elementsForName:@"creation_ts"];
    NSString *creationTime = [[creationTimeNodes objectAtIndex:0] stringValue];
    NSArray *endTimeNodes = [resultElement elementsForName:@"delta_ts"];
    NSString *endTime = [[endTimeNodes objectAtIndex:0] stringValue];
    [self getTimeDifference:creationTime with:endTime];
    
    //add bug status
    NSArray *statusNodes = [resultElement elementsForName:@"bug_status"];
    NSString *bugStatus = [[statusNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugStatus]];
    
    //add bug resolution
    NSArray *resolutionNodes = [resultElement elementsForName:@"resolution"];
    NSString *bugResolution = [[resolutionNodes objectAtIndex:0] stringValue];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugResolution]];

    //add number of comments
    NSArray *cmtIdNodes = [resultElement elementsForName:@"long_desc"];
    int noCmt = (int)[cmtIdNodes count]-1;
    [self.csvString appendString:[NSString stringWithFormat:@"%i, ", noCmt]];
    
    //add number of authors
    NSMutableArray *authorNames = [[NSMutableArray alloc] init];
    NSArray *authorNodes;
    NSString *authorName;
    for (CXMLElement *node in cmtIdNodes) {
        authorNodes = [node elementsForName:@"who"];
        authorName = [[authorNodes objectAtIndex:0] stringValue];
        if (![authorNames containsObject:authorName])
            [authorNames addObject:authorName];
    }
    int noAuthors = (int)[authorNames count];
    [self.csvString appendString:[NSString stringWithFormat:@"%i, ", noAuthors]];
    
    //add number of cc
    NSArray *ccNodes = [resultElement elementsForName:@"cc"];
    int cc = (int)[ccNodes count];
    [self.csvString appendString:[NSString stringWithFormat:@"%i,", cc]];

    //add status and resolution history
//    if ([bugId length]>0)
//        [self dowloadURLContent:bugId];
//    else
        [self.csvString appendString:@"\n"];
    
}

- (void)getTimeDifference:(NSString*)Time1 with:(NSString*)Time2
{
    //2005-11-13 01:44:32 -0800
    NSDate *date1 = [NSDate dateWithString:Time1];
    NSDate *date2 = [NSDate dateWithString:Time2];
    NSTimeInterval secondsBetween = [date2 timeIntervalSinceDate:date1];
    int numberOfDays = secondsBetween / 86400;
    [self.csvString appendString:[NSString stringWithFormat:@"%i, ", numberOfDays]];
}

- (void)getTimeDifferenceJira:(NSString*)Time1 with:(NSString*)Time2
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"ccc, dd MMM yyyy HH:mm:ss ZZZZ"];
    NSDate *date1 = [dateFormat dateFromString:Time1];
    NSDate *date2 = [dateFormat dateFromString:Time2];
                     
	NSTimeInterval secondsBetween = [date2 timeIntervalSinceDate:date1];
    int numberOfDays = secondsBetween / 86400;
    [self.csvString appendString:[NSString stringWithFormat:@"%i, ", numberOfDays]];     
    
}

- (void)dowloadURLContent:(NSString*)bugId  {
    NSURL * url;
    if ([self.xmlType isEqualToString:@"Bugzilla"])
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL, bugId]];
    else
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?page=com.atlassian.jira.plugin.system.issuetabpanels:changehistory-tabpanel", URL, bugId]];
     
    NSData * data = [NSData dataWithContentsOfURL:url];
    NSStringEncoding encoding;
    NSError *error = nil;
    if (data != nil) {
        NSString *webSource = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error];
        if ([self.xmlType isEqualToString:@"Bugzilla"])
            [self getMetricsFromHtml:webSource];
        else
            [self getJiraMetricsFromHtml:webSource];
    }
    else
        [self.csvString appendString:@"\n"];
}

- (void)dowloadQMURLContent:(NSString*)bugId  {
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL, bugId]];
    NSData * data = [NSData dataWithContentsOfURL:url];
    //NSStringEncoding encoding;
    //NSError *error = nil;
    if (data != nil) {
        //NSString *webSource = [NSString stringWithContentsOfURL:url usedEncoding:&encoding error:&error];
        [self dowloadURLContent:bugId];
    }
}

- (void)getJiraMetricsFromHtml:(NSString*)webSource
{
    
    TFHpple * xpathParser = [[TFHpple alloc] initWithHTMLData:[webSource dataUsingEncoding:NSUTF8StringEncoding]];
    TFHppleElement *element  = [xpathParser peekAtSearchWithXPathQuery:@"//div[@id='activitymodule']"]; 
    NSString *mystring = [self getStringForTFHppleElement:element];
    
    NSMutableCharacterSet *charactersToKeep = [NSMutableCharacterSet alphanumericCharacterSet];
    [charactersToKeep addCharactersInString:@"\n"];
    NSCharacterSet *charactersToRemove = [charactersToKeep invertedSet];
    NSString *trimmedReplacement = [[ mystring componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@"" ];
    NSArray *items2 = [trimmedReplacement componentsSeparatedByString:@"\n"];
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:items2];
    [items removeObject: @""];
    
    NSMutableArray *bugStatusHistory = [[NSMutableArray alloc] init];
    NSMutableArray *bugStatusHistoryTrim = [[NSMutableArray alloc] init];
    NSMutableArray *bugResolutionHistory = [[NSMutableArray alloc] init];
    NSMutableArray *bugResolutionHistoryTrim = [[NSMutableArray alloc] init];
    NSMutableString *bugStatusResolutionHistory = [[NSMutableString alloc] init];
    
    [bugResolutionHistory addObject:@"---"];
    NSString *item;
    
    for (int i = 0; i < [items count]; i++)
    {
        item = [items[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if([item isEqualToString:@"Status"]) {
            [bugStatusHistory addObject:[items[i+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            [bugStatusHistory addObject:[items[i+3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
        else if([item isEqualToString:@"Resolution"]) {
            [bugResolutionHistory addObject:[items[i+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            if (i+3 < [items count] &&
                (([items[i+3] caseInsensitiveCompare:@"Unresolved"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"NeedsInfo"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Fixed"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Built"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"WontFix"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Incomplete"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Approved"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Rejected"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Invalid"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Duplicate"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Deferred"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Notabug"]== NSOrderedSame) ||
                ([items[i+3] caseInsensitiveCompare:@"Submitted"]== NSOrderedSame)))
                [bugResolutionHistory addObject:[items[i+3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
    }
    
    //build bugStatusHistory
    for (int j = 0; j < [bugStatusHistory count]; j++){
        if ((j == 0) || (j==[bugStatusHistory count]-1))
            [bugStatusHistoryTrim addObject:bugStatusHistory[j]];
        else if ([bugStatusHistory[j] isEqualToString:bugStatusHistory[j+1]]) {
            [bugStatusHistoryTrim addObject:bugStatusHistory[j]];
            j++;
        }
    }
    
    //build bugResolutionHistory
    for (int j = 0; j < [bugResolutionHistory count]; j++){
        if ((j == 0) || (j==[bugResolutionHistory count]-1))
            [bugResolutionHistoryTrim addObject:bugResolutionHistory[j]];
        else if ([bugResolutionHistory[j] isEqualToString:bugResolutionHistory[j+1]]) {
            [bugResolutionHistoryTrim addObject:bugResolutionHistory[j]];
            j++;
        }
    }
    
    //build bugStatusResolutionHistory
    if ([bugResolutionHistoryTrim count] == [bugStatusHistoryTrim count]) {
        for (int j = 0; j < [bugStatusHistoryTrim count]; j++)
            [bugStatusResolutionHistory appendString: [NSString stringWithFormat:@"%@ (%@) > ", bugStatusHistoryTrim[j], bugResolutionHistoryTrim[j]]];
        
        if ([bugStatusResolutionHistory length] > 0)
            bugStatusResolutionHistory = [NSMutableString stringWithString:[bugStatusResolutionHistory substringToIndex:[bugStatusResolutionHistory length] - 2]];
    }
    else
        [bugStatusResolutionHistory appendString:@""];
    
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", [bugStatusHistoryTrim componentsJoinedByString:@" > "]]];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", [bugResolutionHistoryTrim componentsJoinedByString:@" > "]]];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugStatusResolutionHistory]];
    [self.csvString appendString:@"\n"];
}

- (void)getMetricsFromHtml:(NSString*)webSource
{

    TFHpple * xpathParser = [[TFHpple alloc] initWithHTMLData:[webSource dataUsingEncoding:NSUTF8StringEncoding]];
    TFHppleElement *element  = [xpathParser peekAtSearchWithXPathQuery:@"//div[@id='bugzilla-body']/table[@cellpadding=4]"];
    
    //for wiki
    //TFHppleElement *element  = [xpathParser peekAtSearchWithXPathQuery:@"///table[@cellpadding=4]"];
    NSString *mystring = [self getStringForTFHppleElement:element];
    NSArray *items = [mystring componentsSeparatedByString:@"\n"];
    NSMutableArray *bugStatusHistory = [[NSMutableArray alloc] init];
    NSMutableArray *bugStatusHistoryTrim = [[NSMutableArray alloc] init];
    NSMutableArray *bugResolutionHistory = [[NSMutableArray alloc] init];
    NSMutableArray *bugResolutionHistoryTrim = [[NSMutableArray alloc] init];
    NSMutableString *bugStatusResolutionHistory = [[NSMutableString alloc] init];
    
    NSString *item;
    
    for (int i = 0; i < [items count]; i++)
    {
        item = [items[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if([item isEqualToString:@"Status"]) {
            [bugStatusHistory addObject:[items[i+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            [bugStatusHistory addObject:[items[i+2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
        else if([item isEqualToString:@"Resolution"]) {
            [bugResolutionHistory addObject:[items[i+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            [bugResolutionHistory addObject:[items[i+2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
    }
    
    //build bugStatusHistory
    for (int j = 0; j < [bugStatusHistory count]; j++){
        if ((j == 0) || (j==[bugStatusHistory count]-1))
            [bugStatusHistoryTrim addObject:bugStatusHistory[j]];
        else if ([bugStatusHistory[j] isEqualToString:bugStatusHistory[j+1]]) {
            [bugStatusHistoryTrim addObject:bugStatusHistory[j]];
            j++;
        }
    }
    
    //build bugResolutionHistory
    for (int j = 0; j < [bugResolutionHistory count]; j++){
        if ((j == 0) || (j==[bugResolutionHistory count]-1))
            [bugResolutionHistoryTrim addObject:bugResolutionHistory[j]];
        else if ([bugResolutionHistory[j] isEqualToString:bugResolutionHistory[j+1]]) {
            [bugResolutionHistoryTrim addObject:bugResolutionHistory[j]];
            j++;
        }
    }
    
    //build bugStatusResolutionHistory
    if ([bugResolutionHistoryTrim count] == [bugStatusHistoryTrim count]) {
        for (int j = 0; j < [bugStatusHistoryTrim count]; j++)
            [bugStatusResolutionHistory appendString: [NSString stringWithFormat:@"%@ (%@) > ", bugStatusHistoryTrim[j], bugResolutionHistoryTrim[j]]];
        
        if ([bugStatusResolutionHistory length] > 0)
            bugStatusResolutionHistory = [NSMutableString stringWithString:[bugStatusResolutionHistory substringToIndex:[bugStatusResolutionHistory length] - 2]];
    }
    else
        [bugStatusResolutionHistory appendString:@""];
    
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", [bugStatusHistoryTrim componentsJoinedByString:@" > "]]];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", [bugResolutionHistoryTrim componentsJoinedByString:@" > "]]];
    [self.csvString appendString:[NSString stringWithFormat:@"%@, ", bugStatusResolutionHistory]];
    [self.csvString appendString:@"\n"];
}

-(NSString*) getStringForTFHppleElement:(TFHppleElement *)element
{
    
    NSMutableString *result = [NSMutableString new];
    
    // Iterate recursively through all children
    for (TFHppleElement *child in [element children])
        [result appendString:[self getStringForTFHppleElement:child]];
    
    // Hpple creates a <text> node when it parses texts
    if ([element.tagName isEqualToString:@"text"])
        [result appendString:element.content];
    
    return result;
}


- (NSString*)getLibraryCachesDirectory
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = searchPaths[0];
    return cachesPath;
}

- (void)createXMLFilesDirectory
{    
    NSString *directory = [@"/Users/User1/Documents/XMLBugReports/" stringByAppendingPathComponent: [NSString stringWithFormat:@"/%@XMLFiles", self.xmlType]];
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:directory]) {
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:NULL]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Create folder failed. Please check the directory."];
            [alert runModal];
        }
    }
}

- (void) writeXMLFile:(CXMLElement*)resultElement withIndex:(NSUInteger)i
{
    XMLWriter* xmlWriter = [[XMLWriter alloc]init];
    [xmlWriter writeStartDocumentWithEncodingAndVersion:@"UTF-8" version:@"1.0"];
    NSMutableString *theMutableCopy = [[resultElement XMLString] mutableCopy];
    [theMutableCopy replaceOccurrencesOfString:@" & " withString:@" &amp; " options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [xmlWriter write:theMutableCopy];
    // Create paths to output txt file
    [self outputXMLFile:[xmlWriter toString] withIndex:i];
}

- (void)outputXMLFile:(NSMutableString *)outputString withIndex:(NSUInteger)i
{
    NSString *directory = [@"/Users/User1/Documents/XMLBugReports/" stringByAppendingPathComponent: [NSString stringWithFormat:@"/%@XMLFiles", self.xmlType]];
    NSString *path = [[NSString alloc] initWithFormat:@"%@",[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"xmlFile_%ld.xml", (unsigned long)i]]];
    freopen([path cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdout);
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:path];
    //[fileHandler seekToEndOfFile];
    [fileHandler writeData:[outputString dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler closeFile];
}

- (void)outputCSVFile
{
    NSString *path = [[NSString alloc] initWithFormat:@"%@",[@"/Users/User1/Documents/XMLBugReports/" stringByAppendingPathComponent:@"stats.csv"]];
    freopen([path cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdout);
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:path];
    //[fileHandler seekToEndOfFile];
    [fileHandler writeData:[self.csvString dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler closeFile];
}

@end







