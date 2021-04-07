//
//  ResolverScopeNameTests.swift
//  ResolverTests
//
//  Created by Michael Long on 5/6/18.
//  Copyright © 2018 com.hmlong. All rights reserved.
//

import XCTest
@testable import Resolver

class ResolverScopeNameTests: XCTestCase {

    var resolver: Resolver!

    override func setUp() {
        super.setUp()
        resolver = Resolver()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testResolverScopeNameGraph() {
        resolver.register(name: "Fred") { XYZNameService("Fred") }
        resolver.register(name: "Barney") { XYZNameService("Barney") }
        // let temp = resolver.optional(name: "Fred") 会报错, Generic parameter 'Service' could not be inferred
        // Swift 里面, 通过返回值来确定泛型类型, 是一个很重要的一点, 例如, 闭包的返回值, 来确定接受闭包的函数的返回值的类型
        let service1: XYZNameService? = resolver.optional(name: "Fred")
        let service2: XYZNameService? = resolver.optional(name: "Barney")
        let service3: XYZNameService? = resolver.optional(name: "Barney")
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service3)
        
        if let s1 = service1, let s2 = service2, let s3 = service3 {
            XCTAssert(s1.name == "Fred")
            XCTAssert(s2.name == "Barney")
            XCTAssert(s3.name == "Barney")
            XCTAssert(s1.id != s2.id)
            XCTAssert(s2.id != s3.id)
        } else {
            XCTFail("sessions not resolved")
        }
    }

    func testResolverScopeNameShared() {
        resolver.register(name: "Fred") { XYZNameService("Fred") }.scope(.shared)
        resolver.register(name: "Barney") { XYZNameService("Barney") }.scope(.shared)
        let service1: XYZNameService? = resolver.optional(name: "Fred")
        let service2: XYZNameService? = resolver.optional(name: "Barney")
        let service3: XYZNameService? = resolver.optional(name: "Barney")
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service3)
        if let s1 = service1, let s2 = service2, let s3 = service3 {
            XCTAssert(s1.name == "Fred")
            XCTAssert(s2.name == "Barney")
            XCTAssert(s3.name == "Barney")
            XCTAssert(s1.id != s2.id)
            XCTAssert(s2.id == s3.id)
        } else {
            XCTFail("sessions not resolved")
        }
    }

    func testResolverScopeNameApplication() {
        resolver.register(name: "Fred") { XYZNameService("Fred") }.scope(.application)
        resolver.register(name: "Barney") { XYZNameService("Barney") }.scope(.application)
        let service1: XYZNameService? = resolver.optional(name: "Fred")
        let service2: XYZNameService? = resolver.optional(name: "Barney")
        let service3: XYZNameService? = resolver.optional(name: "Barney")
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service3)
        if let s1 = service1, let s2 = service2, let s3 = service3 {
            XCTAssert(s1.name == "Fred")
            XCTAssert(s2.name == "Barney")
            XCTAssert(s3.name == "Barney")
            XCTAssert(s1.id != s2.id)
            XCTAssert(s2.id == s3.id)
        } else {
            XCTFail("sessions not resolved")
        }
    }

    func testResolverScopeNameCached() {
        resolver.register(name: "Fred") { XYZNameService("Fred") }.scope(.cached)
        resolver.register(name: "Barney") { XYZNameService("Barney") }.scope(.cached)
        let service1: XYZNameService? = resolver.optional(name: "Fred")
        let service2: XYZNameService? = resolver.optional(name: "Barney")
        let service3: XYZNameService? = resolver.optional(name: "Barney")
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service3)
        if let s1 = service1, let s2 = service2, let s3 = service3 {
            XCTAssert(s1.name == "Fred")
            XCTAssert(s2.name == "Barney")
            XCTAssert(s3.name == "Barney")
            XCTAssert(s1.id != s2.id)
            XCTAssert(s2.id == s3.id)
        } else {
            XCTFail("sessions not resolved")
        }
    }

    func testResolverScopeNameUnique() {
        resolver.register(name: "Fred") { XYZNameService("Fred") }.scope(.unique)
        resolver.register(name: "Barney") { XYZNameService("Barney") }.scope(.unique)
        let service1: XYZNameService? = resolver.optional(name: "Fred")
        let service2: XYZNameService? = resolver.optional(name: "Barney")
        let service3: XYZNameService? = resolver.optional(name: "Barney")
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service3)
        if let s1 = service1, let s2 = service2, let s3 = service3 {
            XCTAssert(s1.name == "Fred")
            XCTAssert(s2.name == "Barney")
            XCTAssert(s3.name == "Barney")
            XCTAssert(s1.id != s2.id)
            XCTAssert(s2.id != s3.id)
        } else {
            XCTFail("sessions not resolved")
        }
    }

}
