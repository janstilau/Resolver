#  Resolver: Scopes

## What's a scope, and why do I want one?

Scopes are used to control the lifecycle of a given object instance once it's been resolved. That means that scopes are basically caches, and those caches are used to keep track of the objects they create.

When asked to resolve a particular service, Resolver will find the registration for that service and ask its associated *scope* to provide the instance needed. If the object exists in the cache for that scope then a reference to the cached object is returned. If it *doesn't* exist in the cache, then Resolver will make one using the registration factory and then add it to the cache so it's available next time.

This means that *every* service requested from a scope, with the sole exception of `unique`,  will be cached for some period of time.

How long? Well, that depends on the scope. Some cached instances exist only during a given [resolution cycle](Cycle.md), while others my stick around and maintain a single instance for the entire lifetime of the app.

Resolver has six built-in scopes, all defined on the type `ResolverScope`:

* [.application](#application)
* [.cached](#cached)
* [.graph](#graph) (default)
* [.shared](#shared)
* [.unique](#unique)
* [.container](#container)

Make sure you know and understand the differences between them, becaue if there's one advanced feature of Resolver you absolutely *must* understand, it's this one.

## How do I assign a Scope?

Registrations are assigned to a given scope using the `.scope(...)` modifier on a given registration.  

```swift
register { XYZApplicationService() }
    .scope(.application)
```

If you don't specify a scope for a given registration Resolver will punt and use the globally defined [default scope](#default) (usually [.graph](#graph)). This means that all registrations exist in a given scope, explicitly specified or not. 


## Scope: Application<a name=application></a>

The `application` scope will make Resolver retain a given object instance once it's been resolved the first time, and any subsequent resolutions will *always* return the initial instance.

```swift
register { XYZApplicationService() }
    .scope(.application)
```

This effectively makes the object a `Singleton`.

## Scope: Cached<a name=cached></a>

This scope stores a strong reference to the resolved instance. Once created, every subsequent call to resolve will return the same instance.

```swift
register { MyViewModel() }
    .scope(.cached)
```

This is similar to how an application scope behaves, but unlike an application scope, cached scopes can be `reset`, releasing their cached objects.

This is useful if you need, say, a session-level scope that caches specific information until a user logs out.

```swift
ResolverScope.cached.reset()
```

You can also add your own [custom caches](#custom) to Resolver.

## Scope: Graph<a name=graph></a>

This scope will reuse any object instances resolved during a given [resolution cycle](Cycle.md).

Once the requested object is resolved any internally cached instances will be discarded and the next call to resolve them will produce new instances.

Graph is Resolver's **default** scope, so check out the following code:

```swift
register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
register { resolve() as XYZCombinedService as XYZFetching }
register { resolve() as XYZCombinedService as XYZUpdating }
register { XYZCombinedService() }

var viewModel: XYZViewModel = resolver.resolve()
```

When the call to `resolve` is made, Resolver needs to create an instance of `XYZViewModel`, so it locates and calls the proper factory. That factory is happy to comply, but in order to make a XYZViewModel it's first going to need to resolve all of that object's initialization parameters.

This starts with `fetcher`, which ultimately resolves to `XYZCombinedService`, so the `XYZCombinedService` factory is called to create one. This instance is returned and it's *also* cached in the current object graph.

The next parameter is an `updater`, which coincidentally for this example *also* resolves to `XYZCombinedService`.

But since we've already resolved `XYZCombinedService` once during this cycle, the cached instance will be returned as the parameter for `updater`.

Resolver then resolves the `service` object, and the code initializes a copy of `XYZViewModel` and returns it.

The graph tracks all of the objects that are resolved by all of the objects that are resolved by all of the objects... until the final result is returned. At which point all of the internally cached references are released and your application now is responsible for the object's lifecycle.

If you don't want this behavior, and if every request should get its own `unique` copy, specify it using the `unique` scope.

## Scope: Shared<a name=shared></a>

This scope stores a *weak* reference to the resolved instance.

```swift
register { MyViewModel() }
    .scope(.shared)
```

While a strong reference to the resolved instance exists any subsequent calls to resolve will return the same instance.

However, once all strong references are released, the shared instance is released, and the next call to resolve will produce a new instance.

This is useful in cases like Master/Detail view controllers, where it's possible that both the MasterViewController and the DetailViewController would like to "share" the same instance of a specific view model.

**Note that value types, including structs, are never shared since the concept of a weak reference to them doesn't apply.**

Only class types can have weak references, and as such only class types can be shared.

## Scope: Unique<a name=unique></a>

This is the simplest scope, in that Resolver calls the registration factory to create a new instance of your type each and every time you call resolve.

It's specified like this:

```swift
register { XYZCombinedService() }
    .scope(.unique)
```

## Scope: Container<a name=container></a>

The `container` scope will cause a given object instance to be retained by the `cache` of the `Resolver` instance used for registration. Once it's been resolved the first time, any subsequent resolutions will return the initial instance as long as that container exists, or until its cache is reset or released.

This scope is commonly used in situations where service instances need the same lifecycle as the container.  It's especially handy for mocking and testing where containers may be created on the fly and then disposed.

```swift
resolver.register { XYZApplicationService() }
    .scope(.container)
```

## The Default Scope<a name=default></a>

The default scope used by Resolver when registering an object is [graph](#graph).

But you can change that if you wish, with the only caveat being that you need to do so **before** you do your first registration.

As such, changing the default scope behavior to `unique` would best be done as follows:

```swift
extension Resolver: ResolverRegistering {
    static func registerAllServices() {
        Resolver.defaultScope = .unique
        registerMyNetworkServices()
    }
}
```

## Custom Caches<a name=custom></a>

You can add and use your own scopes. As mentioned above, you might want your own session-level scope to cache information that's needed for as long as a given user is logged in.

To create your own distinct session cache, add the following to your main `AppDelegate+Injection.swift` file:

```swift
extension ResolverScope {
    static let session = ResolverScopeCache()
}
```

Your session scope can then be used and specified just like any built-in scope.

```swift
register { UserManager() }
    .scope(.session)
```

And it can be reset as needed.

```swift
ResolverScope.session.reset()
```

## The ResolverScope Protocol

Finally, if you need some behavior not supported by the built in scopes, you can roll your own using the `ResolverScopeType` protocol and add it to Resolver as shown in [Custom Caches](#custom).

Just use the existing implementations as your guides.



Resolver: 作用域

什么是作用域，为什么我要用它？

作用域用于控制一旦解析了给定对象实例后该实例的生命周期。这意味着作用域基本上是缓存，这些缓存用于跟踪它们创建的对象。

当请求解析特定服务时，Resolver 将查找该服务的注册，并要求其关联的 作用域 提供所需的实例。如果对象存在于该作用域的缓存中，则返回对缓存对象的引用。如果在缓存中不存在，则 Resolver 将使用注册工厂创建一个对象，然后将其添加到缓存中，以便下次使用。

这意味着从作用域请求的 每个 服务，唯一的例外是 unique，都将被缓存一段时间。

多长时间？好吧，这取决于作用域。一些缓存实例仅在给定的 解析周期 内存在，而其他的可能会一直存在并保持单一实例，直到应用程序的整个生命周期。

Resolver 有六个内置作用域，都定义在类型 ResolverScope 上：

.application
.cached
.graph（默认值）
.shared
.unique
.container
确保您了解并理解它们之间的区别，因为如果有一项 Resolver 的高级功能您绝对 必须 理解，那就是这个。

如何分配作用域？

使用 .scope(...) 修饰符在给定注册上为其分配作用域。

swift
Copy code
register { XYZApplicationService() }
    .scope(.application)
如果不为给定注册指定作用域，Resolver 将推迟并使用全局定义的默认作用域（通常是 .graph）。这意味着所有注册都存在于给定的作用域中，无论是否显式指定。

作用域：Application<a name=application></a>

application 作用域将使 Resolver 保留解析过的对象实例，一旦解析过，任何后续解析都将始终返回初始实例。

swift
Copy code
register { XYZApplicationService() }
    .scope(.application)
这实际上使对象成为 Singleton。

作用域：Cached<a name=cached></a>

此作用域存储对已解析实例的强引用。一旦创建，每次调用解析都将返回相同的实例。

swift
Copy code
register { MyViewModel() }
    .scope(.cached)
这与应用程序作用域的行为类似，但与应用程序作用域不同，缓存作用域可以被 reset，释放其缓存的对象。

如果需要，这对于需要缓存特定信息直到用户注销的会话级别的作用域是有用的。

swift
Copy code
ResolverScope.cached.reset()
您还可以向 Resolver 添加自己的自定义缓存。

作用域：Graph<a name=graph></a>

此作用域将重用在给定解析周期期间解析的任何对象实例。

一旦请求的对象被解析，任何内部缓存的实例将被丢弃，并下一次解析它们将生成新实例。

Graph 是 Resolver 的 默认 作用域，所以请看下面的代码：

swift
Copy code
register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
register { resolve() as XYZCombinedService as XYZFetching }
register { resolve() as XYZCombinedService as XYZUpdating }
register { XYZCombinedService() }

var viewModel: XYZViewModel = resolver.resolve()
当调用 resolve 时，Resolver 需要创建 XYZViewModel 的实例，因此它找到并调用适当的工厂。该工厂很乐意遵守，但为了制作 XYZViewModel，它首先需要解析所有该对象的初始化参数。

这从 fetcher 开始，其最终解析为 XYZCombinedService，因此调用 XYZCombinedService 工厂以创建一个。此实例被返回，并且还在当前对象图中缓存。

接下来的参数是 updater，巧合的是对于此示例 也 解析为 XYZCombinedService。

但由于我们在此周期内已经解析了 XYZCombinedService 一次，将返回缓存的实例作为 updater 的参数。

然后，Resolver 解析 service 对象，代码初始化 XYZViewModel 的副本并返回。

图跟踪由所有被解析的对象引发的所有对象引发的所有对象...直到最终结果被返回。此时所有内部缓存的引用都被释放，您的应用程序现在负责对象的生命周期。

如果不想要此行为，并且每个请求都应该获得自己的 unique 副本，请使用 unique 作用域指定它。

作用域：Shared<a name=shared></a>

此作用域将对已解析实例存储 弱 引用。

swift
Copy code
register { MyViewModel() }
    .scope(.shared)
在存在对已解析实例的强引用的同时，每次调用解析都将返回相同的实例。

但是，一旦释放所有强引用，共享实例将被释放，下一次调用解析将产生一个新实例。

这在 Master/Detail 视图控制器等情况下很有用，其中可能希望 MasterViewController 和 DetailViewController “共享” 特定视图模型的相同实例。

请注意，值类型，包括结构体，永远不会被共享，因为对它们的弱引用的概念并不适用。

只有类类型可以有弱引用，因此只有类类型可以被共享。

作用域：Unique<a name=unique></a>

这是最简单的作用域，因为 Resolver 调用注册工厂每次调用 resolve 时都会创建您类型的新实例。

它的指定方式如下：

swift
Copy code
register { XYZCombinedService() }
    .scope(.unique)
作用域：Container<a name=container></a>

container 作用域将导致给定对象实例由用于注册的 Resolver 实例的 cache 保留。一旦解析了第一次，任何后续解析都将返回初始实例，只要该容器存在，或者直到其缓存被重置或释放。

在服务实例需要与容器具有相同的生命周期的情况下，这个作用域通常被使用。在模拟和测试中特别方便，其中容器可能会被动态创建，然后被处理。

swift
Copy code
resolver.register { XYZApplicationService() }
    .scope(.container)
默认作用域<a name=default></a>

在注册对象时，Resolver 使用的默认作用域是 graph。

但是，如果您愿意，可以更改它，唯一的注意事项是您需要在进行第一次注册之前这样做。

因此，将默认作用域行为更改为 unique 最好是这样做的：

swift
Copy code
extension Resolver: ResolverRegistering {
    static func registerAllServices() {
        Resolver.defaultScope = .unique
        registerMyNetworkServices()
    }
}
自定义缓存<a name=custom></a>

您可以添加和使用自己的作用域。如上所述，您可能希望具有与给定用户登录的时间一样长的生命周期的自己的会话级别的作用域。

要创建您自己的独立会话缓存，请将以下内容添加到您的主 AppDelegate+Injection.swift 文件中：

swift
Copy code
extension ResolverScope {
    static let session = ResolverScopeCache()
}
然后您的会话作用域可以像任何内置作用域一样使用和指定。

swift
Copy code
register { UserManager() }
    .scope(.session)
并根据需要重置它。

swift
Copy code
ResolverScope.session.reset()
ResolverScope 协议

最后，如果内置作用域不支持您需要的某些行为，您可以使用 ResolverScopeType 协议自己创建，并按照自定义缓存中所示将其添加到 Resolver。

只需使用现有的实现作为指南。
