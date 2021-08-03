//
//  DetectTestCaseMemoryLeak.swift
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
import XCTestCleanup

class DetectTestCaseMemoryLeak: XCTestCase {

    enum TestEnum: Equatable {
        case noAssociatedValue
        case withAssociatedValue(String)
    }

    // NOTE: static properties are not checked
    private static let staticLetString = "This is a static constant that should not raise an error"

    // MARK: - ivars that are not torn down

    private let letString = "This is not correctly torn down"

    private let letInt = 1

    private let letEnumWithoutAssociatedValue = TestEnum.noAssociatedValue

    private let letEnumWithAssociatedValue = TestEnum.withAssociatedValue("associated value 1")

    private let letObject = NSNumber(integerLiteral: 1)

    // MARK: - @TestConstant ivars

    @TestConstant
    private var constString = "This is a constant that should not be deallocated"

    @TestConstant
    private var constInt = 2

    @TestConstant
    private var constEnumWithoutAssociatedValue = TestEnum.noAssociatedValue

    @TestConstant
    private var constEnumWithAssociatedValue = TestEnum.withAssociatedValue("associated value 2")

    @TestConstant
    private var constObject = NSNumber(integerLiteral: 2)

    // MARK: - @AutoTearDown ivars
    // These will be set to nil by the framework from the tearDownWithError() function.
    //
    // NOTE: Type inferrence determines these all need to be optional because of the requirement provided by
    // @AutoTearDown.

    @AutoTearDown
    private var autoTearDownString = "This should be set to nil automatically by the XCTestCleanup framework"

    @AutoTearDown
    private var autoTearDownInt = 3

    @AutoTearDown
    private var autoTearDownEnumWithoutAssociatedValue = TestEnum.noAssociatedValue

    @AutoTearDown
    private var autoTearDownEnumWithAssociatedValue = TestEnum.withAssociatedValue("associated value 3")

    @AutoTearDown
    private var autoTearDownObject = NSNumber(integerLiteral: 3)

    // MARK: - Test Functions

    override func tearDownWithError() throws {
        // Verify that calling the super.tearDownWithError() results in appropriate errors being raised.
        do {
            try super.tearDownWithError()
            XCTFail("Expected an error to be raised")
        }
        catch {
            guard let err = error as? TestCleanupError else {
                XCTFail("Unexpected error type")
                return
            }

            guard err.memoryLeakErrors.count == 5 else {
                XCTAssertEqual(err.memoryLeakErrors.count, 5)
                return
            }

            let classNames = Set(err.memoryLeakErrors.map { $0.className }).sorted()
            XCTAssertEqual(classNames, ["DetectTestCaseMemoryLeak"])

            let propertyNames = Set(err.memoryLeakErrors.map { $0.propertyName }).sorted()
            XCTAssertEqual(propertyNames, [
                "letEnumWithAssociatedValue",
                "letEnumWithoutAssociatedValue",
                "letInt",
                "letObject",
                "letString"
            ])
        }

        // Verify @AutoTearDown worked properly
        XCTAssertNil(autoTearDownString)
        XCTAssertNil(autoTearDownInt)
        XCTAssertNil(autoTearDownEnumWithAssociatedValue)
        XCTAssertNil(autoTearDownEnumWithoutAssociatedValue)
        XCTAssertNil(autoTearDownObject)

        // Verify let properties are not changed -- they are declared with let so they should not be changed
        XCTAssertEqual(letString, "This is not correctly torn down")
        XCTAssertEqual(letInt, 1)
        XCTAssertEqual(letEnumWithoutAssociatedValue, TestEnum.noAssociatedValue)
        XCTAssertEqual(letEnumWithAssociatedValue, TestEnum.withAssociatedValue("associated value 1"))
        XCTAssertEqual(letObject, NSNumber(integerLiteral: 1))

        // Verify @TestConstant properties are not changed
        XCTAssertEqual(constString, "This is a constant that should not be deallocated")
        XCTAssertEqual(constInt, 2)
        XCTAssertEqual(constEnumWithoutAssociatedValue, TestEnum.noAssociatedValue)
        XCTAssertEqual(constEnumWithAssociatedValue, TestEnum.withAssociatedValue("associated value 2"))
        XCTAssertEqual(constObject, NSNumber(integerLiteral: 2))
    }

    func testLetProperties() throws {
        XCTAssertEqual(letString, "This is not correctly torn down")
        XCTAssertEqual(letInt, 1)
        XCTAssertEqual(letEnumWithoutAssociatedValue, TestEnum.noAssociatedValue)
        XCTAssertEqual(letEnumWithAssociatedValue, TestEnum.withAssociatedValue("associated value 1"))
        XCTAssertEqual(letObject, NSNumber(integerLiteral: 1))
    }

    func testConstProperties() throws {
        XCTAssertEqual(constString, "This is a constant that should not be deallocated")
        XCTAssertEqual(constInt, 2)
        XCTAssertEqual(constEnumWithoutAssociatedValue, TestEnum.noAssociatedValue)
        XCTAssertEqual(constEnumWithAssociatedValue, TestEnum.withAssociatedValue("associated value 2"))
        XCTAssertEqual(constObject, NSNumber(integerLiteral: 2))
    }

    func testAutoTearDownProperties() throws {
        XCTAssertEqual(autoTearDownString, "This should be set to nil automatically by the XCTestCleanup framework")
        XCTAssertEqual(autoTearDownInt, 3)
        XCTAssertEqual(autoTearDownEnumWithoutAssociatedValue, TestEnum.noAssociatedValue)
        XCTAssertEqual(autoTearDownEnumWithAssociatedValue, TestEnum.withAssociatedValue("associated value 3"))
        XCTAssertEqual(autoTearDownObject, NSNumber(integerLiteral: 3))
    }
}
