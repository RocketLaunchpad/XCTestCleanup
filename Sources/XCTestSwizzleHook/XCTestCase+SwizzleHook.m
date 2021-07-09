//
//  XCTestCase+SwizzleHook.h
//  XCTestSwizzleHook
//
//  Copyright (c) 2021 Rocket Insights, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

@import XCTest;
#import "XCTestCase+SwizzleHook.h"

@implementation XCTestCase (SwizzleHook)

// We cannot implement +load in Swift, so we need to do it in Objective-C.
// Simply perform the +loadSwizzleHook selector if self responds to it.
//
// We cannot declare that selector in our interface because we would not be able to override it from Swift, so we have
// to use -performSelector: instead of calling it directly.
+ (void)load
{
    if ([self respondsToSelector:@selector(loadSwizzleHook)])
    {
        [self performSelector:@selector(loadSwizzleHook)];
    }
}

@end
