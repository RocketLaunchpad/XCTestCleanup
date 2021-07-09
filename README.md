# XCTestCleanup

`XCTestCase` behavior can be surprising. The number of `XCTestCase` objects created and how long they live is somewhat counterintuitive.

The flow of execution runs something like this (h/t [this blog post]()):

1. `XCTest` queries the runtime for all subclasses of `XCTestCase`. For each such class, it queries for all methods that:
    1. Are not `private`
    1. Have names beginning with `test`
    1. Have no parameters or return value (although it can `throw`)
1. An `NSInvocation` is created for each class-method pair found above. For each invocation:
    1. A new instance of that class is instantiated
    1. The test function (referred to by the invocation) is performed

Thus, before any tests are run, `XCTest` creates a new `XCTestCase` instance for every test function contained in that class. Those instances are never deallocated.

If you have a large suite of `XCTestCase` classes, this can potentially result in a very large number of objects loaded in memory during test execution. It is important, then, to be smart about how you manage memory from within your tests. For example, let's say you have a test class with four `test` methods:

```swift
import XCTest

class TestSomeFunctionality: XCTestCase {
    private let state = SomeStateObjectBeingTested()

    func test1() { ... }
    func test2() { ... }
    func test3() { ... }
    func test4() { ... }
}
```

Running this test will result in four instances of this class. Each instance will have its own `state` variable. None of these instances will ever be released or deallocated. They will remain in memory for the entire duration of the test run. Apart from memory consumption, this can lead to unintended consequences in the event that that state object interacts with other (potentially global) state objects in other tests (for example, listening for notifications).

The recommended solution is:
1. Do not use initial values to set up properties.
1. Make each property an optional or an implicitly unwrapped optional.
1. Initialize each property in `setUp()`.
1. Set each property to `nil` in `tearDown()`.

This can be cumbersome, especially now that most developers are accustomed to having ARC take care of releasing and freeing objects. This framework is an attempt to address this issue.

## Usage

This framework provides two property wrappers for use in `XCTestCase` subclasses:

- `@AutoTearDown`: Use this to wrap an optional property and automatically set it to `nil` when the test case is torn down (via `tearDown()`).
- `@TestConstant`: Use this to wrap a constant property that you do not want to tear down when the test case is torn down.

The framework hooks into `XCTestCase.tearDownWithError()` and does the following:

- Using Swift reflection, iterate over all of the properties on this object.
- If the property is wrapped with an `@AutoTearDown` property wrapper, the value is set to `nil`.
- Otherwise, if the property is wrapped with a `@TestConstant` property wrapper, the value is ignored.
- Otherwise, an error is thrown containing a list of all of the property names that were not properly set to nil.

## Example

```swift
import XCTest
import XCTestCleanup

class TestSomeFunctionality: XCTestCase {
    @TestConstant
    private let expectedUsername = "jdoe"

    @TestConstant
    private let expectedPassword = "password123"

    // You do not need to set loginSerivce = nil in tearDown()
    // Using @AutoTearDown will do that automatically.
    @AutoTearDown
    private var loginService: LoginService?

    // If a test writes to this variable, an error will be raised in
    // tearDownWithError() indicating that this variable should have been
    // set to nil.
    private var lastResponse: SomeResponseObject?

    override func setUp() {
        super.setUp()
        loginService = MockLoginService(withExpectedUsername: expectedUsername, expectedPassword: expectedPassword)
    }

    func testSomething() {
        ...
    }
}
```

Using `@TestConstant` tells the framework that `expectedUsername` and `expectedPassword` are not expected to be set to `nil` when the test is complete.

Using `@AutoTearDown` tells the framework to set `loginService` to `nil` from the `tearDownWithError()` function.

Note that if a test writes to the `lastResponse` property, that value will remain in memory after the test completes. Since it is not marked as `@TestConstant` or `@AutoTearDown`, an error will be raised from `tearDownWithError()` if it contains non-`nil` value.

Also note that static properties are not checked by the framework. As such, you could make `expectedUsername` and `expectedPassword` static and eliminate the `@TestConstant` wrapper there.

