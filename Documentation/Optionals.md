#  Resolver: Optionals

## Why the expected result is not the expected result

Resolver is pretty good at inferring type, but one thing that can trip it up is optionals.

Consider the following:

```swift
Resolver.register() { ABCService() }
var abc: ABCService? = Resolver.resolve()
```

Try the above, and the expected resolution will fail. Why? Well, remember that Resolver depends on Swift to infer the correct type, based on the type of the expected result.

Here, you'd expect the type to be `ABCService`, but to Swift, the type is actually `Optional(ABCService)`.

And though that's the type Resolver will attempt to resolve, it's not the type that was registered beforehand.

## A little help from a friend

Fortunately, the solution is simple.

```swift
var abc: ABCService? = Resolver.optional()
```

The `optional()` method has a different type signature, and using it allows Swift and Resolver to again infer the correct type.

## The other optional

```swift
var abc: ABCService! = Resolver.resolve()
```

This will also fail to resolve, and for the same reason. To Swift, `ABCService` is not an `ABCService`, but an `ImplicitlyUnwrappedOptional(ABCService)`.

Fortunately, the solution is the same.

```swift
var abc: ABCService! = Resolver.optional()
```

## Explicit Type Specification

You can also punt and explicitly tell Resolver the type of object or protocol you want to resolve.

```swift
var abc: ABCService? = Resolver.resolve(ABCService.self)
```

This could be helpful if for some reason you wanted to resolve to a specific instance.

```swift
var abc: ABCServicing? = Resolver.resolve(ABCService.self)
```

##  Optional annotation

An annotation is available that supports optional resolving. If the service is not registered, then the value will be nil, otherwise it will be not nil:
```swift
class InjectedViewController: UIViewController {
    @OptionalInjected var service: XYZService?
    func load() {
        service?.load()
    }
}
```

Resolver: 可选项

为什么期望的结果不是预期的结果

Resolver 在推断类型方面做得很好，但有一件事可能会让它困扰，那就是可选项。

考虑以下情况：

swift
Copy code
Resolver.register() { ABCService() }
var abc: ABCService? = Resolver.resolve()
尝试上述代码，期望的解析将失败。为什么呢？嗯，记住 Resolver 依赖于 Swift 推断正确的类型，这是基于期望结果的类型。

在这里，你期望的类型应该是 ABCService，但对于 Swift 来说，类型实际上是 Optional(ABCService)。

尽管这是 Resolver 将尝试解析的类型，但它不是之前注册的类型。

朋友的一点帮助

幸运的是，解决方案很简单。

swift
Copy code
var abc: ABCService? = Resolver.optional()
optional() 方法具有不同的类型签名，使用它可以让 Swift 和 Resolver 再次推断出正确的类型。

另一个可选项

swift
Copy code
var abc: ABCService! = Resolver.resolve()
这也将无法解析，原因相同。对于 Swift 来说，ABCService 不是一个 ABCService，而是一个 ImplicitlyUnwrappedOptional(ABCService)。

幸运的是，解决方案是相同的。

swift
Copy code
var abc: ABCService! = Resolver.optional()
显式类型规定

您还可以选择明确告诉 Resolver 您要解析的对象或协议的类型。

swift
Copy code
var abc: ABCService? = Resolver.resolve(ABCService.self)
如果出于某种原因您想要解析到特定实例，这可能会有所帮助。

swift
Copy code
var abc: ABCServicing? = Resolver.resolve(ABCService.self)
可选项注解

有一个支持可选项解析的注解。如果未注册服务，则该值将为 nil，否则将不为 nil：

swift
Copy code
class InjectedViewController: UIViewController {
    @OptionalInjected var service: XYZService?
    func load() {
        service?.load()
    }
}
