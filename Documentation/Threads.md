#  Resolver: Threads

## Thread Safety

Resolver uses a unique recursive locking strategy and is designed to be thread safe during service registration and resolution.

Successful service resolution assumes, however, that all service registrations will occur **prior** to the first resolution request. 

If you kick off thread A to do registrations and then also kick off a thread B that needs to resolve some of those services... well, let's just say that bad things will probably occur as you're setting up a race between registrations and resolutions. It's hard, after all, to resolve a request for `XYZService` if the factory for that service has yet to be registered.

Fortunately, Resolver has a solution for that.

## ResolverRegistering

If you use `ResolverRegistering.registerAllServices` to register all of your dependencies, then you shouldn't have any issues.

```swift
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        registerMyNetworkServices()
        registerMyViewModels()
    }
    
    public static func registerMyNetworkServices() {
        register { ServiceA() }
        register { ServiceB() }
    }
    
    public static func registerMyViewModels() {
        register { ModelA() }
        register { ModelB() }
    }
}
```

Resolver will automatically call `registerAllServices` the very first time it's asked to resolve a particular service, ensuring that everything is properly registered before it goes looking for it.

For more, see the section on [Registration.](Registration.md)


Resolver: 线程

线程安全

Resolver 使用独特的递归锁策略，并被设计为在服务注册和解析过程中是线程安全的。

然而，成功的服务解析假设所有服务注册将在第一次解析请求之前发生。

如果你启动线程 A 进行注册，然后同时启动线程 B 需要解析其中一些服务...嗯，让我们说可能会发生不好的事情，因为你正在设置注册和解析之间的竞争。毕竟，如果服务的工厂尚未注册，很难解析对 XYZService 的请求。

幸运的是，Resolver 对此有解决方案。

ResolverRegistering

如果你使用 ResolverRegistering.registerAllServices 来注册所有依赖项，那么你不应该有任何问题。

swift
Copy code
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        registerMyNetworkServices()
        registerMyViewModels()
    }
    
    public static func registerMyNetworkServices() {
        register { ServiceA() }
        register { ServiceB() }
    }
    
    public static func registerMyViewModels() {
        register { ModelA() }
        register { ModelB() }
    }
}
Resolver 将在第一次被要求解析特定服务时自动调用 registerAllServices，确保在查找服务之前一切都已正确注册。

有关更多信息，请参阅 Registration 部分。
