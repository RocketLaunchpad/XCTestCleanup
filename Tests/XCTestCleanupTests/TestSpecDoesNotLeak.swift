//
//  TestDetectMemoryLeak.swift
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

import Foundation
import Quick
import XCTest
import XCTestCleanup

class DetectMemoryLeakSpec: QuickSpec {

    // NOTE: static properties are not checked
    private static let staticLetString = "This is a static constant that should not raise an error"

    // MARK: - ivars that are not torn down

    private let letString = "This is not correctly torn down"

    private let letObject = NSNumber(integerLiteral: 1)

    // MARK: - @TestConstant ivars

    @TestConstant
    private var constString = "This is a constant that should not be deallocated"

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
    private var autoTearDownObject = NSNumber(integerLiteral: 3)

    // Because of how QuickSpec tests are run, none of the properties on this class are initialized
    // when the test runner instances of thee class are created.
    override func tearDownWithError() throws {
        // Verify that calling the super.tearDownWithError() results in appropriate errors being raised.
        do {
            try super.tearDownWithError()
        }
        catch {
            XCTFail("No error should have been raised")
        }
    }

    override func spec() {
        describe("describe1") {
            context("context1.1") {
                it("it1.1.1") { XCTAssertTrue(true) }
                it("it1.1.2") { XCTAssertTrue(true) }
            }
            context("context1.2") {
                it("it1.2.1") { XCTAssertTrue(true) }
                it("it1.2.2") { XCTAssertTrue(true) }
            }
        }
        describe("describe2") {
            context("context2.1") {
                it("it2.1.1") { XCTAssertTrue(true) }
                it("it2.1.2") { XCTAssertTrue(true) }
            }
            context("context1.2") {
                it("it2.2.1") { XCTAssertTrue(true) }
                it("it2.2.2") { XCTAssertTrue(true) }
            }
        }
    }
}
