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

#import <Foundation/Foundation.h>


@interface Utilities : NSObject 
{
}

///
// Memory map a file. Pass YES as readOnly if
// you want to map read-only. This method uses MAP_PRIVATE
// so the mapping can't be shared with another process.
///
+ (UInt8*) memoryMapFile:(const char*)fileName 
                readOnly:(BOOL)readOnly
               outLength:(CFIndex*)length;

///
// Unmap a previously mapped section of memory
///
+ (void) unMemoryMapBytes:(UInt8*)bytes 
               withLength:(CFIndex)length;

///
// Load a property list from a file.
// returns a mutable copy of the property list
///
+ (CFPropertyListRef) loadPropertyListWithPath:(const char*)path;

///
// Save a property list in memory to a xml file
///
+ (void) savePropertyList:(CFPropertyListRef)plist
                   toPath:(const char*)path;


+ (NSMutableArray*) mutablePlistDeepCopyArray:(NSArray*)oldArray;
+ (NSMutableDictionary*) mutablePlistDeepCopyDictionary:(NSDictionary*)oldDict;

+ (NSString*) getStackTrace:(NSException*)exception;

@end

void MyAssertFailed (const char* condition, const char* file, const int line); 
#define ASSERT(condition) \
    if (!(condition)) { \
        MyAssertFailed(#condition, __FILE__, __LINE__); \
    }

//
// EOF
//