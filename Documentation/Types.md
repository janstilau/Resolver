# Resolver: Type Inference

## Registration

Resolver uses Swift type-inference to automatically detect the type of the class or struct being registered, based on the type of object returned by the factory function.

```swift
main.register { ABCService() }
```

The above factory closure is returning an ABCService, so here we're registering how to create an instance of ABCService.

## Parameters

Resolver can also automatically infer the instance type for method parameters, as shown here.

```swift
main.register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
```

In order to be initialized, XYZViewModel needs a fetcher of type XYZFetching, an updater of type XYZUpdating, and a service of type XYZService.

Instead of creating those objects directly, the factory method passes the buck back to Resolver, asking it to "resolve" those parameters as well.

The same chain of events occurs for every object requested during a given resolution cycle, until every dependent object has the resources it needs to be properly initialized.

## Resolution

Resolver can automatically infer the instance type of the object being requested (resolved).

```swift
var abc: ABCService = Resolver.resolve()
```

Here the variable type is ABCService, so Resolver will lookup the registration for that type and call its factory closure to resolve it to a specific instance.

## Explicit Type Specification

You can also explicitly tell Resolver the type of object or protocol you want to register or resolve.

```swift
Resolver.register(ABCServicing.self) { ABCService() }
var abc = Resolver.resolve(ABCServicing.self)
```


Resolver: 类型推断

注册

Resolver 使用 Swift 类型推断自动检测由工厂函数返回的对象类型，从而自动确定正在注册的类或结构的类型。

swift
Copy code
main.register { ABCService() }
上述工厂闭包返回一个 ABCService，因此我们在这里注册了如何创建 ABCService 实例。

参数

Resolver 还可以自动推断方法参数的实例类型，如下所示。

swift
Copy code
main.register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
为了初始化 XYZViewModel，需要一个类型为 XYZFetching 的 fetcher、一个类型为 XYZUpdating 的 updater，以及一个类型为 XYZService 的 service。

工厂方法不直接创建这些对象，而是将责任交还给 Resolver，要求它“解析”这些参数。

在给定的解析周期内，对于每个请求的对象，都会发生相同的事件链，直到每个依赖对象都有所需的资源，以便进行正确的初始化。

解析

Resolver 还可以自动推断正在请求的对象（解析）的实例类型。

swift
Copy code
var abc: ABCService = Resolver.resolve()
这里变量的类型是 ABCService，因此 Resolver 将查找该类型的注册，并调用其工厂闭包以将其解析为特定实例。

显式类型说明

您还可以显式告诉 Resolver 您要注册或解析的对象或协议的类型。

swift
Copy code
Resolver.register(ABCServicing.self) { ABCService() }
var abc = Resolver.resolve(ABCServicing.self)
