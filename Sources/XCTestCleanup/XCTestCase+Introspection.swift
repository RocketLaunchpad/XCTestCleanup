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

public extension XCTestCase {

    func inspectProperties() throws {
        let mirror = Mirror(reflecting: self)

        let memoryLeakErrors = mirror.children.compactMap {
            inspectChild(withLabel: $0, value: $1)
        }

        guard memoryLeakErrors.isEmpty else {
            throw TestCleanupError(memoryLeakErrors: memoryLeakErrors)
        }
    }

    // Note that introspection can report nil values for children. These are passed in a parameter of type `Any`.
    // Unwrapping this value is a bit more complicated than a simple if-let statement.
    // See: https://stackoverflow.com/a/47757312/511287
    private func inspectChild(withLabel label: String?, value: Any) -> TestMemoryLeakError? {
        guard let propertyName = label else {
            return nil
        }

        let className = String(describing: type(of: self))

        // Unwrap a possible optional
        if case Optional<Any>.some(let actualValue) = value {
            if let toTearDown = actualValue as? AutoTearDownProtocol {
                toTearDown.tearDown()
                return nil
            }
            else if let _ = actualValue as? TestConstantProtocol {
                // Ignore constants
                return nil
            }
            else {
                // We have a non-nil value -- populate an error
                return TestMemoryLeakError(className: className, propertyName: propertyName)
            }
        }

        // Value is nil
        return nil
    }
}
