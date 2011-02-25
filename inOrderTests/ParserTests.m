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

@synthesize parser;

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    self.parser = [[Parser alloc] init];
    
    NSString *dataFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"project" ofType:@"pbxproj"];
    [self.parser openFile:dataFile];
}

- (void)tearDown
{
    // Tear-down code here.
    self.parser = nil;
    
    [super tearDown];
}

- (void)testSave
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsPath stringByAppendingPathComponent:@"newProject.pbxproj"];
    
    NSLog(@"testSave to %@", path);
    BOOL isOk = [self.parser saveFileTo:path];
    
    STAssertTrue(isOk, @"Saving to %@ should work", path);
}

- (void)test
{
    NSString *dataFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"project" ofType:@"pbxproj"];
    
    Parser *p = [[Parser alloc] init];
    
    [p openFile:dataFile];
    [p populateFilesAndGroups];
    
    [p printPaths];
    NSLog(@"result %@", p.files);
    
    [p release];
    
    STFail(@"Unit tests are not implemented yet in ParserTests");
}

@end
