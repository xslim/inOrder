//
//  ParserTests.m
//  inOrder
//
//  Created by Taras Kalapun on 25.02.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "ParserTests.h"
#import "Parser.h"

@implementation ParserTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)test
{
    NSString *dataFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"project" ofType:@"pbxproj"];
    
    Parser *p = [[Parser alloc] init];
    
    [p parseFile:dataFile];
    [p populateFilesAndGroups];
    
    [p printPaths];
    NSLog(@"result %@", p.files);
    
    [p release];
    
    STFail(@"Unit tests are not implemented yet in ParserTests");
}

@end
