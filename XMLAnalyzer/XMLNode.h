//
//  XMLNode.h
//
//  Created by Mona on 12-04-07. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLNode : NSObject {
	int preStateIndex;
	NSString *edge;
	int currentStateIndex;
}

@property(nonatomic, assign) int preStateIndex;
@property(nonatomic, retain) NSString *edge;
@property(nonatomic, assign) int currentStateIndex;

@end
