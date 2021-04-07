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
    
    // MARK: - Lifecycle
    
    // parent 的设计, 意义何在 ???
    // 这里, 猜测是 parent 是更加一般化的依赖注入的配置. 用在项目里面, 就是一般性的依赖注册生成策略, 而在各个模块里面, 可以使用更加精细化的配置.
    // 这些低层次的 Resolver 可以覆盖父层的配置, 当低层次的 Resolver 没有配置的时候, 可以使用父层的配置.
    public init(parent: Resolver? = nil) {
        self.parent = parent
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
    
    /// Static shortcut function used to register a specifc Service type and its instantiating factory method.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public static func register<Service>(_ type: Service.Type = Service.self, name: Resolver.Name? = nil,
                                         factory: @escaping ResolverFactoryResolver<Service>) -> ResolverOptions<Service> {
        return main.register(type, name: name, factory: factory)
    }
    
    /// Static shortcut function used to register a specifc Service type and its instantiating factory method with multiple argument support.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that accepts arguments and constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public static func register<Service>(_ type: Service.Type = Service.self, name: Resolver.Name? = nil,
                                         factory: @escaping ResolverFactoryArgumentsN<Service>) -> ResolverOptions<Service> {
        return main.register(type, name: name, factory: factory)
    }
    
    /// Registers a specifc Service type and its instantiating factory method.
    ///
    /// - parameter type: Type of Service being registered. Optional, may be inferred by factory result type.
    /// - parameter name: Named variant of Service being registered.
    /// - parameter factory: Closure that constructs and returns instances of the Service.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func register<Service>(_ type: Service.Type = Service.self, // 类对象
                                        name: Resolver.Name? = nil, // 名称
                                        factory: @escaping ResolverFactory<Service>) // 生成Service 对象的闭包.
    -> ResolverOptions<Service> {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(Service.self).hashValue
        // 传递进来的, 是 ResolverFactory<Service> = () -> Service? 这种闭包类型, 那么生成的 Item, 就是
        let registration = ResolverRegistrationOnly(resolver: self, key: key, name: name, factory: factory)
        add(registration: registration, with: key, name: name)
        return registration
    }
    
    /// Registers a specifc Service type and its instantiating factory method.
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
        let key = ObjectIdentifier(Service.self).hashValue
        let registration = ResolverRegistrationResolver(resolver: self, key: key, name: name, factory: factory)
        add(registration: registration, with: key, name: name)
        return registration
    }
    
    /// Registers a specifc Service type and its instantiating factory method with multiple argument support.
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
        let key = ObjectIdentifier(Service.self).hashValue
        let registration = ResolverRegistrationArgumentsN(resolver: self, key: key, name: name, factory: factory)
        add(registration: registration, with: key, name: name)
        return registration
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
           // 在拿到 registration 之后, 还调用了 registration registration.scope.resolve 来获取最终的 service.
           let service = registration.scope.resolve(resolver: root, registration: registration, args: args) {
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
    // resolve 的意思就是, 从已经注册的信息里面, 构建一个新的 Service 的对象出来返回.
    // 这里, 之所以这个返回值不是 Optinal 的, 是因为如果找不到, 就 fatalError 了.
    public final func resolve<Service>(_ type: Service.Type = Service.self,
                                       name: Resolver.Name? = nil,
                                       args: Any? = nil) -> Service {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        // 最根本的, 从数据里面查找的思路是没有变的.
        if let registration = lookup(type, name: name),
           let service = registration.scope.resolve(resolver: self, registration: registration, args: args) {
            return service
        }
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
    public static func optional<Service>(_ type: Service.Type = Service.self, name: Resolver.Name? = nil, args: Any? = nil) -> Service? {
        lock.lock()
        defer { lock.unlock() }
        registrationCheck()
        if let registration = root.lookup(type, name: name),
           let service = registration.scope.resolve(resolver: root, registration: registration, args: args) {
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
           let service = registration.scope.resolve(resolver: self, registration: registration, args: args) {
            return service
        }
        return nil
    }
    
    // MARK: - Internal
    
    /// Internal function searches the current and parent registries for a ResolverRegistration<Service> that matches
    /// the supplied type and name.
    private final func lookup<Service>(_ type: Service.Type, name: Resolver.Name?) -> ResolverRegistration<Service>? {
        // 还是根据 Service.type 的哈希值, 到一个字典里面进行查找.
        let key = ObjectIdentifier(Service.self).hashValue
        let containerName = name?.rawValue ?? NONAME
        if let container = registrations[key],
           let registration = container[containerName] {
            return registration as? ResolverRegistration<Service>
        }
        if let parent = parent,
           let registration = parent.lookup(type, name: name) {
            return registration
        }
        return nil
    }
    
    /// Internal function adds a new registration to the proper container.
    private final func add<Service>(registration: ResolverRegistration<Service>,
                                    with key: Int,
                                    name: Resolver.Name?) {
        if var container = registrations[key] {
            container[name?.rawValue ?? NONAME] = registration
            registrations[key] = container
        } else {
            // 这里写的太复杂了, 提前定义一个 key 不更好吗.
            registrations[key] = [name?.rawValue ?? NONAME : registration]
        }
    }
    
    private let NONAME = "*"
    private let parent: Resolver?
    private let lock = Resolver.lock
    private var registrations = [Int : [String : Any]]()
}

/// Resolving an instance of a service is a recursive process (service A needs a B which needs a C).
private class ResolverRecursiveLock {
    init() {
        pthread_mutexattr_init(&recursiveMutexAttr)
        pthread_mutexattr_settype(&recursiveMutexAttr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&recursiveMutex, &recursiveMutexAttr)
    }
    func lock() {
        pthread_mutex_lock(&recursiveMutex)
    }
    func unlock() {
        pthread_mutex_unlock(&recursiveMutex)
    }
    private var recursiveMutex = pthread_mutex_t()
    private var recursiveMutexAttr = pthread_mutexattr_t()
}

extension Resolver {
    // 在 extension 里面, 定义了一个静态属性.
    // 静态属性, 不会改变对象的内存结构.
    private static let lock = ResolverRecursiveLock()
}

/// Resolver Service Name Space Support
extension Resolver {
    
    /// Internal class used by Resolver for typed name space support.
    // 虽然, 就是 String. 但是专门定义了一个类型, 标明这是 Resolver 内的 name
    // 和 NSNotification.Name 是一个道理.
    public struct Name: ExpressibleByStringLiteral {
        
        let rawValue: String
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

@inline(__always)
private func registrationCheck() {
    guard registrationNeeded else {
        return
    }
    if let registering = (Resolver.root as Any) as? ResolverRegistering {
        type(of: registering).registerAllServices()
    }
    registrationNeeded = false
}

// 没有入参, 返回一个特定类型的对象.
public typealias ResolverFactory<Service> = () -> Service?
public typealias ResolverFactoryResolver<Service> = (_ resolver: Resolver) -> Service?
public typealias ResolverFactoryArgumentsN<Service> = (_ resolver: Resolver, _ args: Resolver.Args) -> Service?
public typealias ResolverFactoryMutator<Service> = (_ resolver: Resolver, _ service: Service) -> Void
public typealias ResolverFactoryMutatorArgumentsN<Service> = (_ resolver: Resolver,
                                                              _ service: Service,
                                                              _ args: Resolver.Args) -> Void

/// A ResolverOptions instance is returned by a registration function in order to allow additonal configuratiom. (e.g. scopes, etc.)
public class ResolverOptions<Service> {
    
    // MARK: - Parameters
    
    public var scope: ResolverScope
    
    fileprivate weak var resolver: Resolver?
    fileprivate var mutator: ResolverFactoryMutator<Service>? // 这个闭包, 用来对新生成的对象, 进行配置.
    fileprivate var mutatorWithArgumentsN: ResolverFactoryMutatorArgumentsN<Service>? // 这个闭包, 用来对新生成的对象, 进行配置.
    
    // MARK: - Lifecycle
    
    public init(resolver: Resolver) {
        self.resolver = resolver
        self.scope = Resolver.defaultScope
    }
    
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
    public final func implements<Protocol>(_ type: Protocol.Type, name: Resolver.Name? = nil) -> ResolverOptions<Service> {
        resolver?.register(type.self, name: name) { r, _ in r.resolve(Service.self) as? Protocol }
        return self
    }
    
    /// Allows easy assignment of injected properties into resolved Service.
    ///
    /// - parameter block: Resolution block.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func resolveProperties(_ block: @escaping ResolverFactoryMutator<Service>) -> ResolverOptions<Service> {
        mutator = block
        return self
    }
    
    /// Allows easy assignment of injected properties into resolved Service.
    ///
    /// - parameter block: Resolution block that also receives resolution arguments.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func resolveProperties(_ block: @escaping ResolverFactoryMutatorArgumentsN<Service>) -> ResolverOptions<Service> {
        mutatorWithArgumentsN = block
        return self
    }
    
    /// Defines scope in which requested Service may be cached.
    ///
    /// - parameter block: Resolution block.
    ///
    /// - returns: ResolverOptions instance that allows further customization of registered Service.
    ///
    @discardableResult
    public final func scope(_ scope: ResolverScope) -> ResolverOptions<Service> {
        self.scope = scope
        return self
    }
    
    /// Internal function to apply mutations with and w/o arguments
    fileprivate func mutate(_ service: Service, resolver: Resolver, args: Any?) {
        self.mutator?(resolver, service)
        if let mutatorWithArgumentsN = mutatorWithArgumentsN {
            mutatorWithArgumentsN(resolver, service, Resolver.Args(args))
        }
    }
}

/// ResolverRegistration base class stores the registration keys.
public class ResolverRegistration<Service>: ResolverOptions<Service> {
    
    public var key: Int
    public var cacheKey: String
    
    public init(resolver: Resolver, key: Int, name: Resolver.Name?) {
        self.key = key
        if let namedService = name {
            self.cacheKey = String(key) + ":" + namedService.rawValue
        } else {
            self.cacheKey = String(key)
        }
        super.init(resolver: resolver)
    }
    
    public func resolve(resolver: Resolver, args: Any?) -> Service? {
        fatalError("abstract function")
    }
    
}

/// ResolverRegistration stores a service definition and its factory closure.
public final class ResolverRegistrationOnly<Service>: ResolverRegistration<Service> {
    
    public var factory: ResolverFactory<Service>
    
    public init(resolver: Resolver,
                key: Int,
                name: Resolver.Name?,
                factory: @escaping ResolverFactory<Service>) {
        self.factory = factory
        super.init(resolver: resolver, key: key, name: name)
    }
    
    // 首先, 使用 facotry 闭包, 生成对象, 然后, 使用 mutate 对新生成的对象进行配置.
    // 如果配置了那两个自定义对象的闭包, 那么在 mutate 里面就会被调用.
    public final override func resolve(resolver: Resolver, args: Any?) -> Service? {
        guard let service = factory() else {
            return nil
        }
        mutate(service, resolver: resolver, args: args)
        return service
    }
}

/// ResolverRegistrationResolver stores a service definition and its factory closure.
public final class ResolverRegistrationResolver<Service>: ResolverRegistration<Service> {
    
    public var factory: ResolverFactoryResolver<Service>
    
    public init(resolver: Resolver, key: Int, name: Resolver.Name?, factory: @escaping ResolverFactoryResolver<Service>) {
        self.factory = factory
        super.init(resolver: resolver, key: key, name: name)
    }
    
    public final override func resolve(resolver: Resolver, args: Any?) -> Service? {
        guard let service = factory(resolver) else {
            return nil
        }
        mutate(service, resolver: resolver, args: args)
        return service
    }
}

/// ResolverRegistrationArguments stores a service definition and its factory closure.
public final class ResolverRegistrationArgumentsN<Service>: ResolverRegistration<Service> {
    
    public var factory: ResolverFactoryArgumentsN<Service>
    
    public init(resolver: Resolver, key: Int, name: Resolver.Name?, factory: @escaping ResolverFactoryArgumentsN<Service>) {
        self.factory = factory
        super.init(resolver: resolver, key: key, name: name)
    }
    
    public final override func resolve(resolver: Resolver, args: Any?) -> Service? {
        guard let service = factory(resolver, Resolver.Args(args)) else {
            return nil
        }
        mutate(service, resolver: resolver, args: args)
        return service
    }
}

// ResolverRegistrationArgumentsN, ResolverRegistrationResolver, ResolverRegistrationOnly 仅仅是 factory 不同, 但逻辑基本是相同的.

// Scopes

// Resolver scopes exist to control when resolution occurs and how resolved instances are cached. (If at all.)
// 这里, class 代表什么.
public protocol ResolverScopeType: class {
    func resolve<Service>(resolver: Resolver,
                          registration: ResolverRegistration<Service>,
                          args: Any?) -> Service?
}

// Swift 里面, 类簇模式的实现.
public class ResolverScope: ResolverScopeType {
    
    // Moved definitions to ResolverScope to allow for dot notation access
    
    /// All application scoped services exist for lifetime of the app. (e.g Singletons)
    public static let application = ResolverScopeCache()
    /// Cached services exist for lifetime of the app or until their cache is reset.
    public static let cached = ResolverScopeCache()
    /// Graph services are initialized once and only once during a given resolution cycle. This is the default scope.
    public static let graph = ResolverScopeGraph()
    /// Shared services persist while strong references to them exist. They're then deallocated until the next resolve.
    public static let shared = ResolverScopeShare()
    /// Unique services are created and initialized each and every time they're resolved.
    public static let unique = ResolverScopeUnique()
    
    // abstract base for class never called
    public func resolve<Service>(resolver: Resolver, registration: ResolverRegistration<Service>, args: Any?) -> Service? {
        fatalError("abstract")
    }
}

extension Resolver {
    
    // Resolver scope definitions maintained for compatibility with previous usage.
    @available(swift, deprecated: 4.1, message: "Please use .application to access scope.")
    public static let application = ResolverScope.application
    @available(swift, deprecated: 4.1, message: "Please use .cached to access scope.")
    public static let cached = ResolverScope.cached
    @available(swift, deprecated: 4.1, message: "Please use .graph to access scope.")
    public static let graph = ResolverScope.graph
    @available(swift, deprecated: 4.1, message: "Please use .shared to access scope.")
    public static let shared = ResolverScope.shared
    @available(swift, deprecated: 4.1, message: "Please use .unique to access scope.")
    public static let unique = ResolverScope.unique
    
}

/// Cached services exist for lifetime of the app or until their cache is reset.
public class ResolverScopeCache: ResolverScope {
    
    public override init() {}
    
    public final override func resolve<Service>(resolver: Resolver,
                                                registration: ResolverRegistration<Service>,
                                                args: Any?) -> Service? {
        if let service = cachedServices[registration.cacheKey] as? Service {
            return service
        }
        // 如果找不到, 就生成, 然后把生成的 service 对象, 存到缓存池里面.
        let service = registration.resolve(resolver: resolver, args: args)
        if let service = service {
            cachedServices[registration.cacheKey] = service
        }
        return service
    }
    
    public final func reset() {
        cachedServices.removeAll()
    }
    
    // 一个缓存器, 所以, ResolverScopeCache 的主要功能就是, 根据 cacheKey 来寻找缓存.
    fileprivate var cachedServices = [String : Any](minimumCapacity: 32)
}

/// Graph services are initialized once and only once during a given resolution cycle. This is the default scope.
public final class ResolverScopeGraph: ResolverScope {
    
    public override init() {}
    
    public final override func resolve<Service>(resolver: Resolver, registration: ResolverRegistration<Service>, args: Any?) -> Service? {
        if let service = graph[registration.cacheKey] as? Service {
            return service
        }
        resolutionDepth = resolutionDepth + 1
        let service = registration.resolve(resolver: resolver, args: args)
        resolutionDepth = resolutionDepth - 1
        if resolutionDepth == 0 {
            graph.removeAll()
        } else if let service = service, type(of: service as Any) is AnyClass {
            graph[registration.cacheKey] = service
        }
        return service
    }
    
    private var graph = [String : Any?](minimumCapacity: 32)
    private var resolutionDepth: Int = 0
}

/// Shared services persist while strong references to them exist. They're then deallocated until the next resolve.
public final class ResolverScopeShare: ResolverScope {
    
    public override init() {}
    
    public final override func resolve<Service>(resolver: Resolver, registration: ResolverRegistration<Service>, args: Any?) -> Service? {
        if let service = cachedServices[registration.cacheKey]?.service as? Service {
            return service
        }
        let service = registration.resolve(resolver: resolver, args: args)
        if let service = service, type(of: service as Any) is AnyClass {
            cachedServices[registration.cacheKey] = BoxWeak(service: service as AnyObject)
        }
        return service
    }
    
    public final func reset() {
        cachedServices.removeAll()
    }
    
    private struct BoxWeak {
        weak var service: AnyObject?
    }
    
    private var cachedServices = [String : BoxWeak](minimumCapacity: 32)
}

/// Unique services are created and initialized each and every time they're resolved.
// 每次都重新创建.
public final class ResolverScopeUnique: ResolverScope {
    
    public override init() {}
    public final override func resolve<Service>(resolver: Resolver, registration: ResolverRegistration<Service>, args: Any?) -> Service? {
        return registration.resolve(resolver: resolver, args: args)
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
    // projectedValue 返回原始值.
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
        return service == nil
    }
    public var wrappedValue: Service {
        mutating get {
            if initialize {
                self.initialize = false
                self.service = container?.resolve(Service.self, name: name, args: args) ?? Resolver.resolve(Service.self, name: name, args: args)
            }
            return service
        }
        mutating set { service = newValue  }
    }
    public var projectedValue: LazyInjected<Service> {
        get { return self }
        mutating set { self = newValue }
    }
    public mutating func release() {
        self.service = nil
    }
}

/// Weak lazy injection property wrapper. Note that embedded container and name properties will be used if set prior to service instantiation.
///
/// Wrapped dependent service is not resolved until service is accessed.
///
@propertyWrapper public struct WeakLazyInjected<Service> {
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
        return service == nil
    }
    public var wrappedValue: Service? {
        mutating get {
            if initialize {
                self.initialize = false
                let service = container?.resolve(Service.self, name: name, args: args) ?? Resolver.resolve(Service.self, name: name, args: args)
                self.service = service as AnyObject
                return service
            }
            return service as? Service
        }
        mutating set { service = newValue as AnyObject }
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
