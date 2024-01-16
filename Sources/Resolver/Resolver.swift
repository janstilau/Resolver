#if os(iOS)
import UIKit
import SwiftUI
#elseif os(macOS) || os(tvOS) || os(watchOS)
import Foundation
import SwiftUI
#else
import Foundation
#endif

public protocol ResolverRegistering {
    // 这是一个 static
    static func registerAllServices()
}

/// The Resolving protocol is used to make the Resolver registries available to a given class.
public protocol Resolving {
    var resolver: Resolver { get }
}

extension Resolving {
    public var resolver: Resolver {
        return Resolver.root
    }
}

/// Resolver is a Dependency Injection registry that registers Services for later resolution and
/// injection into newly constructed instances.
public final class Resolver {
    
    // MARK: - Defaults
    
    /// Default registry used by the static Registration functions.
    public static var main: Resolver = Resolver()
    /// Default registry used by the static Resolution functions and by the Resolving protocol.
    public static var root: Resolver = main
    
    
    /// Default scope applied when registering new objects.
    public static var defaultScope: ResolverScope = .graph
    /// Internal scope cache used for .scope(.container)
    public lazy var cache: ResolverScope = ResolverScopeCache()
    
    // MARK: - Lifecycle
    
    /// Initialize with optional child scope.
    /// If child is provided this container is searched for registrations first, then any of its children.
    public init(child: Resolver? = nil) {
        if let child = child {
            self.childContainers.append(child)
        }
    }
    
    /// Initializer which maintained Resolver 1.0's "parent" functionality even when multiple child scopes were added in 1.4.3.
    @available(swift, deprecated: 5.0, message: "Please use Resolver(child:).")
    public init(parent: Resolver) {
        self.childContainers.append(parent)
    }
    
    /// Adds a child container to this container. Children will be searched if this container fails to find a registration factory
    /// that matches the desired type.
    public func add(child: Resolver) {
        lock.lock()
        defer { lock.unlock() }
        self.childContainers.append(child)
    }
    
    /// Call function to force one-time initialization of the Resolver registries. Usually not needed as functionality
    /// occurs automatically the first time a resolution function is called.
    public final func registerServices() {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
    }
    
    /// Call function to force one-time initialization of the Resolver registries. Usually not needed as functionality
    /// occurs automatically the first time a resolution function is called.
    public static var registerServices: (() -> Void)? = {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
    }
    
    /// Called to effectively reset Resolver to its initial state, including recalling registerAllServices if it was provided. This will
    /// also reset the three known caches: application, cached, shared.
    public static func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        main = Resolver()
        root = main
        ResolverScope.application.reset()
        ResolverScope.cached.reset()
        ResolverScope.shared.reset()
        registrationNeeded = true
    }
    
    
    
    
    
    // MARK: - Service Registration
    
    /// Static shortcut function used to register a specifc Service type and its instantiating factory method.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public static func register<Service>(_ type: Service.Type = Service.self,
                                         name: Resolver.Name? = nil,
                                         factory: @escaping ResolverFactory<Service>) -> ResolverOptions<Service> {
        return main.register(type, name: name, factory: factory)
    }
    
    /// Static shortcut function used to register a specific Service type and its instantiating factory method.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public static func register<Service>(_ type: Service.Type = Service.self,
                                         name: Resolver.Name? = nil,
                                         factory: @escaping ResolverFactoryResolver<Service>) -> ResolverOptions<Service> {
        return main.register(type, name: name, factory: factory)
    }
    
    /// Static shortcut function used to register a specific Service type and its instantiating factory method with multiple argument support.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that accepts arguments and constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public static func register<Service>(_ type: Service.Type = Service.self, 
                                         name: Resolver.Name? = nil,
                                         factory: @escaping ResolverFactoryArgumentsN<Service>) -> ResolverOptions<Service> {
        return main.register(type, name: name, factory: factory)
    }
    
    
    // 上面三个是 static, 下面的是真正的实现.
    // ResolverFactoryAnyArguments 都是用的这个工厂方法.
    
    /// Registers a specific Service type and its instantiating factory method.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func register<Service>(_ type: Service.Type = Service.self,
                                        name: Resolver.Name? = nil,
                                        factory: @escaping ResolverFactory<Service>) -> ResolverOptions<Service> {
        lock.lock()
        defer { lock.unlock() }
        
        // 将 factory 变为最最通用的一种形式, 这样可以进行统一的存储.
        let key = Int(bitPattern: ObjectIdentifier(Service.self))
        let factory: ResolverFactoryAnyArguments = { (_, _) in factory() }
        let registration = ResolverRegistration<Service>(resolver: self, key: key, name: name, factory: factory)
        add(registration: registration, with: key, name: name)
        return ResolverOptions(registration: registration)
    }
    
    /// Registers a specific Service type and its instantiating factory method.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func register<Service>(_ type: Service.Type = Service.self, 
                                        name: Resolver.Name? = nil,
                                        factory: @escaping ResolverFactoryResolver<Service>) -> ResolverOptions<Service> {
        lock.lock()
        defer { lock.unlock() }
        let key = Int(bitPattern: ObjectIdentifier(Service.self))
        let factory: ResolverFactoryAnyArguments = { (r,_) in factory(r) }
        let registration = ResolverRegistration<Service>(resolver: self, key: key, name: name, factory: factory)
        add(registration: registration, with: key, name: name)
        return ResolverOptions(registration: registration)
    }
    
    /// Registers a specific Service type and its instantiating factory method with multiple argument support.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that accepts arguments and constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func register<Service>(_ type: Service.Type = Service.self, 
                                        name: Resolver.Name? = nil,
                                        factory: @escaping ResolverFactoryArgumentsN<Service>) -> ResolverOptions<Service> {
        lock.lock()
        defer { lock.unlock() }
        let key = Int(bitPattern: ObjectIdentifier(Service.self))
        let factory: ResolverFactoryAnyArguments = { (r, a) in factory(r, Args(a)) }
        let registration = ResolverRegistration<Service>(resolver: self, key: key, name: name, factory: factory)
        add(registration: registration, with: key, name: name)
        return ResolverOptions(registration: registration)
    }
    
    
    
    
    
    
    // MARK: - Service Resolution
    
    /// Static function calls the root registry to resolve a given Service type.
    ///
    /// - parameter type: Type of Service being resolved. Optional, may be inferred by assignment result type.
    /// - parameter name: Named variant of Service being resolved.
    /// - parameter args: Optional arguments that may be passed to registration factory.
    ///
    /// - returns: Instance of specified Service.
    public static func resolve<Service>(_ type: Service.Type = Service.self, 
                                        name: Resolver.Name? = nil,
                                        args: Any? = nil) -> Service {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        
        if let registration = root.lookup(type, name: name),
            let service = registration.resolve(resolver: root, args: args) {
            return service
        }
        fatalError("RESOLVER: '\(Service.self):\(name?.rawValue ?? "NONAME")' not resolved. To disambiguate optionals use resolver.optional().")
    }
    
    /// Resolves and returns an instance of the given Service type from the current registry or from its
    /// parent registries.
    ///
    /// - parameter type: Type of Service being resolved. Optional, may be inferred by assignment result type.
    /// - parameter name: Named variant of Service being resolved.
    /// - parameter args: Optional arguments that may be passed to registration factory.
    ///
    /// - returns: Instance of specified Service.
    ///
    public final func resolve<Service>(_ type: Service.Type = Service.self,
                                       name: Resolver.Name? = nil,
                                       args: Any? = nil) -> Service {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        
        if let registration = lookup(type, name: name), 
            let service = registration.resolve(resolver: self, args: args) {
            return service
        }
        // disambiguate 消除.
        // 使用 resolve 就是一定需要创建出某个对象出来. 
        fatalError("RESOLVER: '\(Service.self):\(name?.rawValue ?? "NONAME")' not resolved. To disambiguate optionals use resolver.optional().")
    }
    
    /// Static function calls the root registry to resolve an optional Service type.
    ///
    /// - parameter type: Type of Service being resolved. Optional, may be inferred by assignment result type.
    /// - parameter name: Named variant of Service being resolved.
    /// - parameter args: Optional arguments that may be passed to registration factory.
    ///
    /// - returns: Instance of specified Service.
    ///
    public static func optional<Service>(_ type: Service.Type = Service.self,
                                         name: Resolver.Name? = nil,
                                         args: Any? = nil) -> Service? {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        if let registration = root.lookup(type, name: name),
           let service = registration.resolve(resolver: root, args: args) {
            return service
        }
        return nil
    }
    
    /// Resolves and returns an optional instance of the given Service type from the current registry or
    /// from its parent registries.
    ///
    /// - parameter type: Type of Service being resolved. Optional, may be inferred by assignment result type.
    /// - parameter name: Named variant of Service being resolved.
    /// - parameter args: Optional arguments that may be passed to registration factory.
    ///
    /// - returns: Instance of specified Service.
    ///
    public final func optional<Service>(_ type: Service.Type = Service.self,
                                        name: Resolver.Name? = nil,
                                        args: Any? = nil) -> Service? {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        if let registration = lookup(type, name: name), 
            let service = registration.resolve(resolver: self, args: args) {
            return service
        }
        return nil
    }
    
    
    
    
    // MARK: - Internal
    
    /// Internal function searches the current and child registries for a ResolverRegistration<Service> that matches
    /// the supplied type and name.
    private final func lookup<Service>(_ type: Service.Type, name: Resolver.Name?) -> ResolverRegistration<Service>? {
        
        let key = Int(bitPattern: ObjectIdentifier(Service.self))
        // 还是优先寻找, 带 name 的.
        if let name = name?.rawValue {
            if let registration = namedRegistrations["\(key):\(name)"] as? ResolverRegistration<Service> {
                return registration
            }
        } else if let registration = typedRegistrations[key] as? ResolverRegistration<Service> {
            return registration
        }
        
        for child in childContainers {
            if let registration = child.lookup(type, name: name) {
                return registration
            }
        }
        return nil
    }
    
    /// Internal function adds a new registration to the proper container.
    private final func add<Service>(registration: ResolverRegistration<Service>, with key: Int, name: Resolver.Name?) {
        if let name = name?.rawValue {
            namedRegistrations["\(key):\(name)"] = registration
        } else {
            typedRegistrations[key] = registration
        }
    }
    
    private let NONAME = "*"
    private let lock = Resolver.lock
    private var childContainers: [Resolver] = []
    private var typedRegistrations = [Int : Any]()
    private var namedRegistrations = [String : Any]()
}

/// Resolving an instance of a service is a recursive process (service A needs a B which needs a C).
private final class ResolverRecursiveLock {
    init() {
        pthread_mutexattr_init(&recursiveMutexAttr)
        pthread_mutexattr_settype(&recursiveMutexAttr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&recursiveMutex, &recursiveMutexAttr)
    }
    @inline(__always)
    final func lock() {
        pthread_mutex_lock(&recursiveMutex)
    }
    @inline(__always)
    final func unlock() {
        pthread_mutex_unlock(&recursiveMutex)
    }
    private var recursiveMutex = pthread_mutex_t()
    private var recursiveMutexAttr = pthread_mutexattr_t()
}

extension Resolver {
    // 全局使用的是一把锁.
    fileprivate static let lock = ResolverRecursiveLock()
}

/// Resolver Service Name Space Support
// 使用类型, 来代替基本的数据类型.
extension Resolver {
    
    /// Internal class used by Resolver for typed name space support.
    public struct Name: ExpressibleByStringLiteral, Hashable, Equatable {
        public let rawValue: String
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        public init(stringLiteral: String) {
            self.rawValue = stringLiteral
        }
        public static func name(fromString string: String?) -> Name? {
            if let string = string { return Name(string) }
            return nil
        }
        static public func == (lhs: Name, rhs: Name) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }
    }
    
}

/// Resolver Multiple Argument Support
extension Resolver {
    
    /// Internal class used by Resolver for multiple argument support.
    public struct Args {
        
        private var args: [String:Any?]
        
        public init(_ args: Any?) {
            if let args = args as? Args {
                self.args = args.args
            } else if let args = args as? [String:Any?] {
                self.args = args
            } else {
                self.args = ["" : args]
            }
        }
        
#if swift(>=5.2)
        public func callAsFunction<T>() -> T {
            assert(args.count == 1, "argument order indeterminate, use keyed arguments")
            return (args.first?.value as? T)!
        }
        
        public func callAsFunction<T>(_ key: String) -> T {
            return (args[key] as? T)!
        }
#endif
        
        public func optional<T>() -> T? {
            return args.first?.value as? T
        }
        
        public func optional<T>(_ key: String) -> T? {
            return args[key] as? T
        }
        
        public func get<T>() -> T {
            assert(args.count == 1, "argument order indeterminate, use keyed arguments")
            return (args.first?.value as? T)!
        }
        
        public func get<T>(_ key: String) -> T {
            return (args[key] as? T)!
        }
        
    }
    
}

// Registration Internals

private var registrationNeeded: Bool = true

// 在适当的时机, 调用该方法, 来完成依赖关系的 lazy 初始化.
@inline(__always)
private func registrationCheck() {
    guard registrationNeeded else {
        return
    }
    if let registering = (Resolver.root as Any) as? ResolverRegistering {
        // 第一看到, 还有这么使用的.
        type(of: registering).registerAllServices()
    }
    registrationNeeded = false
}

// 不需要参数
public typealias ResolverFactory<Service> = () -> Service?
// 需要 Resolver 参数
public typealias ResolverFactoryResolver<Service> = (_ resolver: Resolver) -> Service?
// 需要 Resolver 参数, 和 Resolver.Args 参数
public typealias ResolverFactoryArgumentsN<Service> = (_ resolver: Resolver, _ args: Resolver.Args) -> Service?
// 需要 Resolver 参数, 和 Any 参数. 这是 Registeration 里面存储的项.
// Any 包含 Resolver.Args
public typealias ResolverFactoryAnyArguments<Service> = (_ resolver: Resolver, _ args: Any?) -> Service?


// 需要 Resolver 参数, 和 Service 参数
public typealias ResolverFactoryMutator<Service> = (_ resolver: Resolver, _ service: Service) -> Void
// 需要 Resolver 参数, 和 Service 参数, 和 Resolver.Args 参数
public typealias ResolverFactoryMutatorArgumentsN<Service> = (_ resolver: Resolver, _ service: Service, _ args: Resolver.Args) -> Void

/// A ResolverOptions instance is returned by a registration function in order to allow additional configuration. (e.g. scopes, etc.)
// 这就是一个包装体, 经常出现这样的设计. 主要是为了链式编程的
// 就如同 Alamofire 里面, 返回一个 Request 对象一样. 第一个 request 方法, 返回了一个 Request 对象, 然后所有的后续操作, 都是在操作这个对象.
// 然后还是返回 self, 就是所有的操作, 都是在修改 Request 对象的内部数据. 或者, 是触发了全局的状态改变, 就如同这里的 registration.resolver?.register.
// 专门写这样的一个类, 来进行链式调用, 是很常见的一种情况.
public struct ResolverOptions<Service> {
    
    // MARK: - Parameters
    
    // 所有的数据项, 都在这里. 各种函数都是为了修改这里状态. 每次都返回 struct, 虽然都是在复制数据, 但是对于 registration 是同样的位置.
    public var registration: ResolverRegistration<Service>
    
    // MARK: - Fuctionality
    
    /// Indicates that the registered Service also implements a specific protocol that may be resolved on
    /// its own.
    ///
    /// - parameter type: Type of protocol being registered.
    /// - parameter name: Named variant of protocol being registered.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public func implements<Protocol>(_ type: Protocol.Type, 
                                     name: Resolver.Name? = nil) -> ResolverOptions<Service> {
        // implements 的作用, 其实就是, 当 resolve 需要的是一个 Protocol.Type 的时候, 使用当前的 Service 来进行生成.
        // 这样就实现了, Imp 注册给了上层的抽象接口的效果了.
        // register 还是使用的最原始的做法, 然后传递一个工厂方法的 block 进去. 因为这里已经明确的知道了, Service.self 已经注册了, 所以直接使用 resolve 函数.
        registration.resolver?.register(type.self, name: name) {
            r, args in
            r.resolve(Service.self, args: args) as? Protocol
        }
        return self
    }
    
    /// Allows easy assignment of injected properties into resolved Service.
    ///
    /// - parameter block: Resolution block.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    // 不需要参数的初始化器.
    @discardableResult
    public func resolveProperties(_ block: @escaping ResolverFactoryMutator<Service>) -> ResolverOptions<Service> {
        registration.update { existingFactory in
            return { (resolver, args) in
                // 先用原本的生成出 service, 然后使用传入的 Block 进行修改.
                guard let service = existingFactory(resolver, args) else {
                    return nil
                }
                block(resolver, service)
                return service
            }
        }
        return self
    }
    
    /// Allows easy assignment of injected properties into resolved Service.
    ///
    /// - parameter block: Resolution block that also receives resolution arguments.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    // 需要参数的初始化器.
    @discardableResult
    public func resolveProperties(_ block: @escaping ResolverFactoryMutatorArgumentsN<Service>) -> ResolverOptions<Service> {
        registration.update { existingFactory in
            return { (resolver, args) in
                guard let service = existingFactory(resolver, args) else {
                    return nil
                }
                block(resolver, service, Resolver.Args(args))
                return service
            }
        }
        return self
    }
    
    /// Defines scope in which requested Service may be cached.
    ///
    /// - parameter block: Resolution block.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public func scope(_ scope: ResolverScope) -> ResolverOptions<Service> {
        registration.scope = scope
        return self
    }
}

/// ResolverRegistration base class provides storage for the registration keys, scope, and property mutator.
public final class ResolverRegistration<Service> {
    
    public let key: Int
    public let cacheKey: String
    
    fileprivate var factory: ResolverFactoryAnyArguments<Service>
    fileprivate var scope: ResolverScope = Resolver.defaultScope
    
    fileprivate weak var resolver: Resolver?
    
    public init(resolver: Resolver, key: Int, name: Resolver.Name?, factory: @escaping ResolverFactoryAnyArguments<Service>) {
        self.resolver = resolver
        self.key = key
        if let namedService = name {
            self.cacheKey = String(key) + ":" + namedService.rawValue
        } else {
            self.cacheKey = String(key)
        }
        self.factory = factory
    }
    
    /// Called by Resolver containers to resolve a registration. Depending on scope may return a previously cached instance.
    // 真正的生成 Service 的地方, 又包装了一层, 而不是直接拿出 factory 进行的调用. 这样做的主要目的就是为了缓存. 
    public final func resolve(resolver: Resolver, args: Any?) -> Service? {
        return scope.resolve(registration: self, resolver: resolver, args: args)
    }
    
    /// Called by Resolver scopes to instantiate a new instance of a service.
    public final func instantiate(resolver: Resolver, args: Any?) -> Service? {
        return factory(resolver, args)
    }
    
    /// Called by ResolverOptions to wrap a given service factory with new behavior.
    // modifier 是传入一个 ResolverFactoryAnyArguments, 返回一个 ResolverFactoryAnyArguments, 而 self.factory 也是一个 ResolverFactoryAnyArguments
    // 这个 update(factory 不是给外界使用的.
    public final func update(factory modifier: (_ factory: @escaping ResolverFactoryAnyArguments<Service>) -> ResolverFactoryAnyArguments<Service>) {
        // 嵌套组合, 外界可以无限的使用 update.
        self.factory = modifier(factory)
    }
    
}

// Scopes

/// Resolver scopes exist to control when resolution occurs and how resolved instances are cached. (If at all.)
public protocol ResolverScopeType: AnyObject {
    func resolve<Service>(registration: ResolverRegistration<Service>, 
                          resolver: Resolver,
                          args: Any?) -> Service?
    func reset()
}

public class ResolverScope: ResolverScopeType {
    
    // Moved definitions to ResolverScope to allow for dot notation access
    
    /// All application scoped services exist for lifetime of the app. (e.g Singletons)
    public static let application = ResolverScopeCache()
    
    /// Proxy to container's scope. Cache type depends on type supplied to container (default .cache)
    public static let container = ResolverScopeContainer()
    /// Cached services exist for lifetime of the app or until their cache is reset.
    public static let cached = ResolverScopeCache()
    /// Graph services are initialized once and only once during a given resolution cycle. This is the default scope.
    public static let graph = ResolverScopeGraph()
    /// Shared services persist while strong references to them exist. They're then deallocated until the next resolve.
    public static let shared = ResolverScopeShare()
    
    /// Unique services are created and initialized each and every time they're resolved.
    // unique 就是最原始的, 每次都重新进行创建.
    public static let unique = ResolverScope()
    
    public init() {}
    
    // 默认的实现, 就是直接使用 registration 来制作出实例来.
    // 相当于每次都进行生成.
    /// Core scope resolution simply instantiates new instance every time it's called (e.g. .unique)
    public func resolve<Service>(registration: ResolverRegistration<Service>,
                                 resolver: Resolver,
                                 args: Any?) -> Service? {
        return registration.instantiate(resolver: resolver, args: args)
    }
    
    public func reset() {
        // nothing to see here. move along.
    }
}

/// Cached services exist for lifetime of the app or until their cache is reset.
public class ResolverScopeCache: ResolverScope {
    
    public override init() {}
    
    public override func resolve<Service>(registration: ResolverRegistration<Service>, resolver: Resolver, args: Any?) -> Service? {
        // 这里有一个缓存的概念.
        if let service = cachedServices[registration.cacheKey] as? Service {
            return service
        }
        let service = registration.instantiate(resolver: resolver, args: args)
        if let service = service {
            cachedServices[registration.cacheKey] = service
        }
        return service
    }
    
    public override func reset() {
        cachedServices.removeAll()
    }
    
    fileprivate var cachedServices = [String : Any](minimumCapacity: 32)
}

/// Graph services are initialized once and only once during a given resolution cycle. This is the default scope.
public final class ResolverScopeGraph: ResolverScope {
    
    public override init() {}
    
    public override final func resolve<Service>(registration: ResolverRegistration<Service>,
                                                resolver: Resolver,
                                                args: Any?) -> Service? {
        if let service = graph[registration.cacheKey] as? Service {
            return service
        }
        resolutionDepth = resolutionDepth + 1
        // registration.instantiate 的过程里面, 可能还会触发到这里.
        //
        let service = registration.instantiate(resolver: resolver, args: args)
        resolutionDepth = resolutionDepth - 1
        if resolutionDepth == 0 {
            graph.removeAll()
        } else if let service = service, 
                    type(of: service as Any) is AnyClass {
            graph[registration.cacheKey] = service
        }
        return service
    }
    
    public override final func reset() {}
    
    private var graph = [String : Any?](minimumCapacity: 32)
    private var resolutionDepth: Int = 0
}

/// Shared services persist while strong references to them exist. They're then deallocated until the next resolve.
public final class ResolverScopeShare: ResolverScope {
    
    public override init() {}
    
    public override final func resolve<Service>(registration: ResolverRegistration<Service>, resolver: Resolver, args: Any?) -> Service? {
        if let service = cachedServices[registration.cacheKey]?.service as? Service {
            return service
        }
        let service = registration.instantiate(resolver: resolver, args: args)
        // 如果, Service 是引用类型, 那么才使用这个.
        if let service = service,
            type(of: service as Any) is AnyClass {
            cachedServices[registration.cacheKey] = BoxWeak(service: service as AnyObject)
        }
        return service
    }
    
    public override final func reset() {
        cachedServices.removeAll()
    }
    
    private struct BoxWeak {
        weak var service: AnyObject?
    }
    
    private var cachedServices = [String : BoxWeak](minimumCapacity: 32)
}

/// Unique services are created and initialized each and every time they're resolved. Performed by default implementation of ResolverScope.
public typealias ResolverScopeUnique = ResolverScope

/// Proxy to container's scope. Cache type depends on type supplied to container (default .cache)
public final class ResolverScopeContainer: ResolverScope {
    
    public override init() {}
    
    public override final func resolve<Service>(registration: ResolverRegistration<Service>, resolver: Resolver, args: Any?) -> Service? {
        return resolver.cache.resolve(registration: registration, resolver: resolver, args: args)
    }
}


#if os(iOS)
/// Storyboard Automatic Resolution Protocol
public protocol StoryboardResolving: Resolving {
    func resolveViewController()
}

/// Storyboard Automatic Resolution Trigger
public extension UIViewController {
    // swiftlint:disable unused_setter_value
    @objc dynamic var resolving: Bool {
        get {
            return true
        }
        set {
            if let vc = self as? StoryboardResolving {
                vc.resolveViewController()
            }
        }
    }
    // swiftlint:enable unused_setter_value
}
#endif

// Swift Property Wrappers

#if swift(>=5.1)
/// Immediate injection property wrapper.
///
/// Wrapped dependent service is resolved immediately using Resolver.root upon struct initialization.
///
@propertyWrapper public struct Injected<Service> {
    private var service: Service
    public init() {
        self.service = Resolver.resolve(Service.self)
    }
    public init(name: Resolver.Name? = nil, container: Resolver? = nil) {
        self.service = container?.resolve(Service.self, name: name) ?? Resolver.resolve(Service.self, name: name)
    }
    public var wrappedValue: Service {
        get { return service }
        mutating set { service = newValue }
    }
    public var projectedValue: Injected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
}

/// OptionalInjected property wrapper.
///
/// If available, wrapped dependent service is resolved immediately using Resolver.root upon struct initialization.
///
@propertyWrapper public struct OptionalInjected<Service> {
    private var service: Service?
    public init() {
        self.service = Resolver.optional(Service.self)
    }
    public init(name: Resolver.Name? = nil, container: Resolver? = nil) {
        self.service = container?.optional(Service.self, name: name) ?? Resolver.optional(Service.self, name: name)
    }
    public var wrappedValue: Service? {
        get { return service }
        mutating set { service = newValue }
    }
    public var projectedValue: OptionalInjected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
}

/// Lazy injection property wrapper. Note that embedded container and name properties will be used if set prior to service instantiation.
///
/// Wrapped dependent service is not resolved until service is accessed.
///
@propertyWrapper public struct LazyInjected<Service> {
    private var lock = Resolver.lock
    private var initialize: Bool = true
    private var service: Service!
    public var container: Resolver?
    public var name: Resolver.Name?
    public var args: Any?
    public init() {}
    
    public init(name: Resolver.Name? = nil, container: Resolver? = nil) {
        self.name = name
        self.container = container
    }
    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return service == nil
    }
    public var wrappedValue: Service {
        // 直到, 真正使用 wrappedValue 的时候, 才触发解析的过程. 
        mutating get {
            lock.lock()
            defer { lock.unlock() }
            if initialize {
                self.initialize = false
                self.service = container?.resolve(Service.self, name: name, args: args) ?? Resolver.resolve(Service.self, name: name, args: args)
            }
            return service
        }
        mutating set {
            lock.lock()
            defer { lock.unlock() }
            initialize = false
            service = newValue
        }
    }
    public var projectedValue: LazyInjected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
    public mutating func release() {
        lock.lock()
        defer { lock.unlock() }
        self.service = nil
    }
}

/// Weak lazy injection property wrapper. Note that embedded container and name properties will be used if set prior to service instantiation.
///
/// Wrapped dependent service is not resolved until service is accessed.
///
@propertyWrapper public struct WeakLazyInjected<Service> {
    private var lock = Resolver.lock
    private var initialize: Bool = true
    private weak var service: AnyObject?
    public var container: Resolver?
    public var name: Resolver.Name?
    public var args: Any?
    public init() {}
    public init(name: Resolver.Name? = nil, container: Resolver? = nil) {
        self.name = name
        self.container = container
    }
    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return service == nil
    }
    public var wrappedValue: Service? {
        mutating get {
            lock.lock()
            defer { lock.unlock() }
            if initialize {
                self.initialize = false
                self.service = (container?.resolve(Service.self, name: name, args: args)
                                ?? Resolver.resolve(Service.self, name: name, args: args)) as AnyObject
            }
            return service as? Service
        }
        mutating set {
            lock.lock()
            defer { lock.unlock() }
            initialize = false
            service = newValue as AnyObject
        }
    }
    public var projectedValue: WeakLazyInjected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
/// Immediate injection property wrapper for SwiftUI ObservableObjects. This wrapper is meant for use in SwiftUI Views and exposes
/// bindable objects similar to that of SwiftUI @observedObject and @environmentObject.
///
/// Dependent service must be of type ObservableObject. Updating object state will trigger view update.
///
/// Wrapped dependent service is resolved immediately using Resolver.root upon struct initialization.
///
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper public struct InjectedObject<Service>: DynamicProperty where Service: ObservableObject {
    @ObservedObject private var service: Service
    public init() {
        self.service = Resolver.resolve(Service.self)
    }
    public init(name: Resolver.Name? = nil, container: Resolver? = nil) {
        self.service = container?.resolve(Service.self, name: name) ?? Resolver.resolve(Service.self, name: name)
    }
    public var wrappedValue: Service {
        get { return service }
        mutating set { service = newValue }
    }
    public var projectedValue: ObservedObject<Service>.Wrapper {
        return self.$service
    }
}
#endif
#endif
