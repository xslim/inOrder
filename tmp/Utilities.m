/*
Copyright (C) 2008 Darrell Walisser walisser@mac.com

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#import "Utilities.h"

@implementation Utilities

#import <unistd.h>
#import <stdio.h>
#import <fcntl.h>
#import <sys/stat.h>
#import <sys/mman.h>
#import <Foundation/NSException.h>

static NSMutableArray *gObjectStack = nil;

static void pushObject(id object)
{
    if (gObjectStack == nil)
        gObjectStack = [ [ NSMutableArray alloc ] init ];
    
    [ gObjectStack addObject:object ];
}

static void popObject()
{
    [ gObjectStack removeLastObject ];
}

static BOOL isOnStack(id object)
{
    return [ gObjectStack containsObject:object ];
}

void MyAssertFailed (const char* condition, const char* file, const int line) {

#if CATCH_EXCEPTIONS
    NS_DURING
#endif

	[ [ NSException
        exceptionWithName:@"Assertion Failed"
        reason:[ NSString stringWithFormat:@"Assertion failed at %@:%d\n\nASSERT ( %s );",
            [ [ [ NSString stringWithCString:file ] pathComponents ] lastObject ], 
				line, condition ]
        userInfo:nil ] raise ];

#if CATCH_EXCEPTIONS
NS_HANDLER

	// re-raise with stack trace
	[ [ NSException
			exceptionWithName:[ localException name ]
			reason:[ localException reason ]
			userInfo:[ NSDictionary dictionaryWithObject:[ Utilities getStackTrace:localException ] forKey:@"stack" ] ] raise ];

NS_ENDHANDLER
#endif

}

+ (UInt8*) memoryMapFile:(const char*)fileName 
                readOnly:(BOOL)readOnly
               outLength:(CFIndex*)length
 {
    struct stat 	statBuf;
    int 		fd;
    int                 protectionFlags;
    UInt8 		*bytes;
    
    ASSERT (0 == stat (fileName, &statBuf));
    
    protectionFlags = readOnly ? O_RDONLY : O_RDWR;
    
    fd = open (fileName, protectionFlags);
    ASSERT (fd >= 0);
    
    protectionFlags = readOnly ? PROT_READ : PROT_READ | PROT_WRITE;
    
    bytes = (UInt8*) mmap (
        NULL,
        statBuf.st_size, 
        protectionFlags, 
        MAP_PRIVATE,
        fd, 
        0
    );
                         
    ASSERT (bytes != NULL);
    close(fd);
     
    *length = statBuf.st_size;
    return bytes;
}

+ (void) unMemoryMapBytes:(UInt8*)bytes 
               withLength:(CFIndex)length
{
    munmap (bytes, length);
}

+ (CFPropertyListRef) loadPropertyListWithPath:(const char*)path
{
    CFDataRef			xmlData;
    CFStringRef			errorString;
    CFPropertyListRef 	plist;
    UInt8				*bytes;
    CFIndex				length;
    CFDataRef			tmpData;
    
    bytes = [ Utilities memoryMapFile:path
                             readOnly:YES
                            outLength:&length ];
    ASSERT (bytes != nil);
    
    tmpData = CFDataCreateWithBytesNoCopy (
        nil,
        bytes,
        length,
        kCFAllocatorNull
    );
    
    ASSERT (tmpData != nil);
    
    xmlData = CFDataCreateMutableCopy (
        kCFAllocatorDefault,
        length,
        tmpData
    );
    
    ASSERT (xmlData != nil);
    
    CFRelease (tmpData);
    [ Utilities unMemoryMapBytes:bytes withLength:length ];

    plist = CFPropertyListCreateFromXMLData (
        kCFAllocatorDefault,
        xmlData,
        kCFPropertyListMutableContainersAndLeaves,
        &errorString
    );

    if (plist == nil) {
    
        // If we failed, errorString will contain something useful
        // and we are responsible for releasing it
        //CFShow ("loadPropertyListWithPath, error=%@", errorString);
        CFRelease (errorString);
    }
    
    CFRelease (xmlData);
    return plist;
}

+ (void) savePropertyList:(CFPropertyListRef)plist
                   toPath:(const char*)path
{
    CFDataRef		xmlData;
    int          	fd;
    const UInt8*	bytes;
    CFIndex		length;
    
    xmlData = CFPropertyListCreateXMLData (
        kCFAllocatorDefault,
        plist
    );
    ASSERT (xmlData != nil);
    
    bytes = CFDataGetBytePtr (xmlData);
    length = CFDataGetLength (xmlData);
    
    fd = open (path, O_WRONLY | O_CREAT, 0600);
    ASSERT (fd >= 0);
    
    ASSERT (length == write (fd, bytes, length));
    
    close (fd);
    CFRelease (xmlData);
}

+ (NSMutableArray*) mutablePlistDeepCopyArray:(NSArray*)oldArray
{
    NSMutableArray 	*newArray;
    NSEnumerator	*objects;
    id		         object;
    
    pushObject(oldArray);
    
    newArray = [ NSMutableArray array ];
    
    objects = [ oldArray objectEnumerator ];
    while (nil != (object = [ objects nextObject ])) {
            
        if ( [ object isKindOfClass:[ NSDictionary class ] ]) {
        
            if (!isOnStack(object))
                [ newArray addObject:[ self mutablePlistDeepCopyDictionary:object ] ];
        }
        else
        if ( [ object isKindOfClass:[ NSArray class ] ] ) {
        
            if (!isOnStack(object))
                [ newArray addObject:[ self mutablePlistDeepCopyArray:object ] ];
        }
        //else
        //if ( [ object isKindOfClass:[ NSString class ] ]) {
        
            // note: don't copy strings
        //    [ newArray addObject:object ];
        //}
        else {
        
            [ newArray addObject:object ];

            // note: don't accept non-project builder plists
            //NSLog (@"%@", object);
            //ASSERT ("unsupported object" == 0);
        }
    }
    
    popObject();
    
    return newArray;
}

+ (NSMutableDictionary*) mutablePlistDeepCopyDictionary:(NSDictionary*)oldDict
{
    NSMutableDictionary *newDict;
    
 /*   
     newDict = CFPropertyListCreateDeepCopy (
        kCFAllocatorDefault,
        oldDict,
        kCFPropertyListMutableContainers
    );

    return newDict;
*/    
    NSEnumerator		*keys;
    NSString			*key;
    
    pushObject(oldDict);
    
    newDict = [ NSMutableDictionary dictionary ];
    
    keys = [ oldDict keyEnumerator ];
    while (nil != (key = [ keys nextObject ])) {
    
        id object = [ oldDict objectForKey:key ];
        
        if ( [ object isKindOfClass:[ NSDictionary class ] ]) {
        
            if (!isOnStack(object))
                [ newDict setObject:[ self mutablePlistDeepCopyDictionary:object ] forKey:key ];
        }
        else
        if ( [ object isKindOfClass:[ NSArray class ] ] ) {
        
            if (!isOnStack(object))
                [ newDict setObject:[ self mutablePlistDeepCopyArray:object ] forKey:key ];
        }
        //else
        //if ( [ object isKindOfClass:[ NSString class ] ]) {
        
            // note: don't copy strings
        //    [ newDict setObject:object forKey:key ];
        //}
        else {

            [ newDict setObject:object forKey:key ];
        
            // note: don't accept non-project builder plists
            //NSLog (@"%@", [ object class ]);
            //ASSERT ("unsupported object" == 0);
        }
    }
    
    popObject();
    
    return newDict;
}

+ (NSString*) getStackTrace:(NSException*)exception
{
	NSString* stack = @"";

	if ( [ exception methodForSelector:@selector(callStackReturnAddresses:) ] )
	{
		NSString* str = [ NSString stringWithFormat:@"/usr/bin/atos -p %d", 
			getpid() ];
	
		NSEnumerator	*e = [ [ exception callStackReturnAddresses ] objectEnumerator ];		 
		NSNumber* n;
		
		while (n = [ e nextObject ])
			str = [ str stringByAppendingFormat:@" 0x%x", [ n longValue ] ];
		
		//NSLog(@"%@", str);
		
		FILE* fp = popen ([str UTF8String], "r");
		if (fp)
		{
			unsigned char resBuf[512];
			size_t len;
			while (len = fread(resBuf, 1, sizeof(resBuf), fp))
				stack = [ stack stringByAppendingFormat:@"%@", 
					[ [ NSString alloc ] initWithBytes:resBuf length:len encoding:NSASCIIStringEncoding ] ];
			
			pclose(fp);
		}
		
		//NSLog(@"stack=%@", stack);
	}
	
	return stack;
/*
	fprintf(stderr, "------ STACK TRACE ------\n");
	id trace  = [ [ exception userInfo ] objectForKey:NSStackTraceKey ];
	if (trace != nil)
	{
		FILE* fp = popen([str UTF8String], "r");
		if (fp)
		{
			unsigned char resBuf[512];
			while(size_t len = fread(resBuf, 1, sizeof(resBuf), fp))
				fwrite(resBuf, 1, len, stderr);
			pclose(fp);
		}
	}
	fprintf(stderr, "-------------------------\n");
*/
}

@end

//
// EOF
//