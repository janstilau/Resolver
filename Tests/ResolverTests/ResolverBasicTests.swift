//
//  ResolverBasicTests.swift
//  ResolverTests
//
//  Created by Michael Long on 11/14/17.
//  Copyright © 2017 com.hmlong. All rights reserved.
//

import XCTest
import Resolver

class ResolverBasicTests: XCTestCase {

    var resolver: Resolver!

    override func setUp() {
        super.setUp()
        resolver = Resolver()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRegistrationAndExplicitResolution() {
        // 注册了, 某个类型应该如何生成.
        resolver.register { XYZSessionService() }
        // 解析的时候, 传入这个类型的类对象, 获得这个类型对应的对象.
        let session: XYZSessionService? = resolver.resolve(XYZSessionService.self)
        XCTAssertNotNil(session)
    }

    func testRegistrationAndInferedResolution() {
        // 注册了某个类型应该如何生成
        resolver.register { XYZSessionService() }
        // 解析的时候, 传入的 type 值是 XYZSessionService.self
        // 这里, 可以直接调用 resolver.resolve(), 因为可以根据返回值, 确定 Service 就是 Int. 所以, resolve 里面的第一参数, 其实可以使用到默认参数值.
        let value: Int = resolver.resolve()
        let session: XYZSessionService? = resolver.resolve() as XYZSessionService
//        let temp = resolver.resolve() as Int, 这样写, type 的值就是 Int.type, 看来, as 可以改变类型
        XCTAssertNotNil(session)
    }

    func testRegistrationAndOptionalResolution() {
        // 注册了某个类型应该如何生成
        resolver.register { XYZSessionService() }
        // optional 基本和 resolve 一样, 不过是 lookup 的时候, 如果找不到, 就返回 nil 了
        let session: XYZSessionService? = resolver.optional()
        XCTAssertNotNil(session)
    }

    func testRegistrationAndOptionalResolutionFailure() {
        // 没有提前注册, 直接调用, 返回 nil.
        let session: XYZSessionService? = resolver.optional()
        XCTAssertNil(session)
    }

    func testRegistrationAndResolutionChain() {
        resolver.register { XYZSessionService() }
        // 注册, XYZService 如何生成, 调用了特定的构造函数, 而这个构造函数, 使用了 self.resolver.optional, 通过构造函数的参数, 来确定 Service 的类型.
        resolver.register { XYZService( self.resolver.optional() ) }
        let service: XYZService? = resolver.optional()
        XCTAssertNotNil(service)
        XCTAssertNotNil(service?.session)
    }

    func testRegistrationOverwritting() {
        // 注册 Service 应该如何生成, 使用了特定的构造函数, 传入了参数值.
        resolver.register() { XYZNameService("Fred") }
        resolver.register() { XYZNameService("Barney") }
        let service: XYZNameService? = resolver.optional()
        XCTAssertNotNil(service)
        XCTAssert(service?.name == "Barney")
    }

    func testRegistrationAndPassedResolver() {
        resolver.register { XYZSessionService() }
        // 如果了, XYZService 应该如何生成. 因为闭包的返回值是 XYZService, 所以, 注册的 key, 是 XYZService.self
        // 这里, r 就是 Resolver. 这是因为, register 函数有一个重载, 就是 (_ resolver: Resolver) -> Service? 的这种闭包.
        // 在调用 optional 的时候, 发现是这种类型, 就会将 resolver 自身传递进去.
        resolver.register { (r) -> XYZService in
            return XYZService( r.optional() )
        }
        let service: XYZService? = resolver.optional()
        XCTAssertNotNil(service)
        XCTAssertNotNil(service?.session)
    }

    func testRegistrationAndResolutionProperties() {
        // 注册了 XYZSessionService 应该如何生成, 然后, 返回值调用了 resolveProperties 方法, 这个方法, 可以进行后续的配置.
        // 在定义的时候, resolveProperties 的实现, 仅仅是把后面的闭包存起来了, 但是使用的时候, 这种写法, 让使用者很好很好的表达自己的代码含义.
        resolver.register { XYZSessionService() }
            .resolveProperties { (r, s) in
                s.name = "updated"
        }
        let session: XYZSessionService? = resolver.optional()
        XCTAssertNotNil(session)
        XCTAssert(session?.name == "updated")
    }

    func testRegistrationAndResolutionResolve() {
        resolver.register { XYZSessionService() }
        let session: XYZSessionService = resolver.resolve()
        XCTAssertNotNil(session)
    }

    func testRegistrationAndResolutionResolveArgs() {
        let service: XYZService = Resolver.resolve(args: true)
        XCTAssertNotNil(service.session)
    }

    func testStaticRegistrationAndResolution() {
        // 通过类方法进行注册, 其实就是使用一个全局量进行注册
        Resolver.register { XYZSessionService() }
        let service: XYZService = Resolver.resolve()
        XCTAssertNotNil(service.session)
    }

    func testStaticRegistrationWithArgsAndResolution() {
        // 通过类方法进行注册, 其实就是使用一个全局量进行注册
        Resolver.register { _, _ in XYZSessionService() }
        let service: XYZService = Resolver.resolve()
        XCTAssertNotNil(service.session)
    }

    func testRegistrationWithArgsCodeCoverage() {
        resolver.register(XYZSessionProtocol.self) { return nil } // induce internal error
        let session: XYZSessionProtocol? = resolver.optional()
        XCTAssertNil(session)
    }

}
