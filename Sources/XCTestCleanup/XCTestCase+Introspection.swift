//
//  XCTestCase+Introspection.swift
//  XCTestCleanup
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

import XCTest
import XCTestCleanupObjCHelpers

public extension XCTestCase {

    func inspectProperties() throws {
        let className = String(describing: type(of: self))
        let selfMirror = Mirror(reflecting: self)

        // Iterate over the child properties of self
        let memoryLeakErrors = selfMirror.children.compactMap { (label: String?, value: Any) -> TestMemoryLeakError? in
            guard let propertyName = label else {
                NSLog("Ignoring unnamed property")
                return nil
            }

            // If we are under a QuickSpec, properties in test runner objects are not initialized.
            // It will crash if we try to create a Mirror for such an uninitialized value.
            // There's no easy way to do a numeric comparison to see if the address of value is equal to 0x00000000, so
            // we'll delegate to an Objective-C helper function.
            if IsNullPointer(value) {
                NSLog("Ignoring raw null pointer for %@", propertyName)
                return nil
            }

            // Check this child to see if it is nil.
            //
            // The value parmeter can be nil, but since it is expressed in an any, we can't use a simple if-let statement.
            // Instead, we use another mirror and inspect the display style of the reflected value to detect nil values.
            //
            // See: https://stackoverflow.com/q/33877433/511287
            // See: https://stackoverflow.com/a/33877857/511287
            let childMirror = Mirror(reflecting: value)

            // If this is not an optional
            // -or-
            // If it is an optional and there are one or more children
            // Then this should have been set to nil. Check to see if this is an exception
            if childMirror.displayStyle != .optional || childMirror.children.count != 0 {
                // Tear down properties marked as @AutoTearDown
                if let toTearDown = value as? AutoTearDownProtocol {
                    NSLog("Auto tear down property %@", propertyName)
                    toTearDown.tearDown()
                    return nil
                }
                // Ignore properties marked as @TestConstant
                else if let _ = value as? TestConstantProtocol {
                    NSLog("Ignoring test constant property %@", propertyName)
                    return nil
                }
                // Signal a leak
                else {
                    NSLog("Found memory leak of property %@", propertyName)
                    return TestMemoryLeakError(className: className, propertyName: propertyName)
                }
            }
            // Otherwise, this did not need to be set to nil
            else {
                NSLog("Ignoring property %@", propertyName)
                return nil
            }
        }

        // Wrap any existing errors in a TestCleanupError
        guard memoryLeakErrors.isEmpty else {
            NSLog("Found %d memory leak errors", memoryLeakErrors.count)
            throw TestCleanupError(memoryLeakErrors: memoryLeakErrors)
        }
    }
}
