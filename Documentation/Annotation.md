#  Resolver: Annotation

Another common Dependency Injection strategy is annotation: adding comments or other metadata to the code which indicates that the following service needs to be resolved by the dependency injection system.

This is commonly done on Android using Dagger 2, and we can now do something similar on iOS.

## Property Wrappers

Resolver now supports resolving properties using the new property wrapper syntax in Swift 5.1.

```swift
class BasicInjectedViewController: UIViewController {
    @Injected var service: XYZService
}
```
Just add the Injected property wrapper and your dependencies will be resolved automatically and instantiated immediately, ready and waiting for use.

**Note that you still need to [register](Registration.md) any class or classes that you need to resolve.**

Also note that as long as you compile with Swift 5.1, **property wrappers work on earlier versions of iOS (11, 12)**. They're not just limited to iOS 13.

The Injected property wrapper will automatically instantiate objects using the current Resolver root container, exactly as if you'd done `var service: XYZService = Resolver.resolve()`. See instructions below on how to specify a different container.

###  Lazy Injection

Resolver also has a LazyInjected property wrapper. Unlike using Injected, lazily injected services are not resolved until the code attempts to access the wrapped service.
```swift
class NamedInjectedViewController: UIViewController {
    @LazyInjected var service: XYZNameService
    func load() {
        service.load() // service will be resolved at this point in time
    }
}
```
Note that LazyInjected is a mutating property wrapper. As such it can only be used in class instances or in structs when the struct is mutable.

###  Weak Lazy Injection

Resolver also has a WeakLazyInjected property wrapper. Like LazyInjected, services are not resolved until the code attempts to access the wrapped service.
```swift
class NamedInjectedViewController: UIViewController {
    @WeakLazyInjected var service: XYZNameService
    func load() {
        service.load() // service will be resolved at this point in time
    }
}
```
Note that LazyInjected is a mutating property wrapper. As such it can only be used in class instances or in structs when the struct is mutable.

### Named injection

You can use named service resolution using the `name`  property wrapper initializer as shown below.

```swift
class NamedInjectedViewController: UIViewController {
    @Injected(name: "fred") var service: XYZNameService
}
```
You can also update the name in code and 'on the fly' using @LazyInjected.
```swift
class NamedInjectedViewController: UIViewController {
    @LazyInjected var service: XYZNameService
    var which: Bool
    override func viewDidLoad() {
        super.viewDidLoad()
        $service.name = which ? "fred" : "barney"
    }
}
```
If you go this route just make sure you specify the name *before* accessing the injected service for the first time.

###  Optional injection

An annotation is available that supports optional resolving. If the service is not registered, then the value will be nil, otherwise it will be not nil:
```swift
class InjectedViewController: UIViewController {
    @OptionalInjected var service: XYZService?
    func load() {
        service?.load()
    }
}
```

### Injection With Protocols

Injecting a protocol works with all of the injection property wrappers.
```swift
protocol Loader {
    func load()
}

class InjectedViewController: UIViewController {
    @njected var loader: Loader
    func load() {
        loader.load()
    }
}
```
Registration of the class providing the protocol instance is performed exactly the same. See [Protocols](Protocols.md) for more.

### Custom Containers

You can specify and resolve custom containers using Injected. Just define your custom container...

```swift
extension Resolver {
    static var custom = Resolver()
}
```
And specify it as part of the Injected property wrapper initializer.
```swift
class ContainerInjectedViewController: UIViewController {
    @Injected(container: .custom) var service: XYZNameService
}
```
As with named injection, with LazyInjected you can also dynamically specifiy the desired container.
```swift
class NamedInjectedViewController: UIViewController {
    @LazyInjected var service: XYZNameService
    var which: Bool
    override func viewDidLoad() {
        super.viewDidLoad()
        $service.container = which ? "main" : "test"
    }
}
```

### More Information

I've written quite a bit more on developing the Injected property wrapper. You can find more information on Injected and property wrappers in my article, [Swift 5.1 Takes Dependency Injection to the Next Level](https://medium.com/better-programming/taking-swift-dependency-injection-to-the-next-level-b71114c6a9c6) on Medium.


Resolver：注解

另一种常见的依赖注入策略是注解：在代码中添加注释或其他元数据，指示以下服务需要由依赖注入系统解析。

这在Android上通常使用Dagger 2完成，而现在我们也可以在iOS上实现类似的功能。

属性包装器

Resolver现在支持使用Swift 5.1中的新属性包装器语法解析属性。

swift
Copy code
class BasicInjectedViewController: UIViewController {
    @Injected var service: XYZService
}
只需添加Injected属性包装器，你的依赖关系将被自动解析并立即实例化，准备好供使用。

请注意，你仍然需要注册你需要解析的任何类或类。

此外，请注意只要使用Swift 5.1进行编译，属性包装器就适用于较早版本的iOS（11、12）。它们不仅限于iOS 13。

Injected属性包装器将使用当前的Resolver根容器自动实例化对象，就像你执行了var service: XYZService = Resolver.resolve()一样。请参阅下面的说明，了解如何指定不同的容器。

懒加载注入
Resolver还具有LazyInjected属性包装器。与使用Injected不同，懒惰注入的服务直到代码尝试访问封装的服务时才解析。

swift
Copy code
class NamedInjectedViewController: UIViewController {
    @LazyInjected var service: XYZNameService
    func load() {
        service.load() // 在此时点上将解析服务
    }
}
请注意，LazyInjected是一个可变的属性包装器。因此，它只能在类实例中使用，或者在结构体是可变的情况下使用。

弱引用懒加载注入
Resolver还具有WeakLazyInjected属性包装器。与LazyInjected类似，直到代码尝试访问封装的服务时才解析服务。

swift
Copy code
class NamedInjectedViewController: UIViewController {
    @WeakLazyInjected var service: XYZNameService
    func load() {
        service.load() // 在此时点上将解析服务
    }
}
请注意，WeakLazyInjected是一个可变的属性包装器。因此，它只能在类实例中使用，或者在结构体是可变的情况下使用。

命名注入
你可以使用name属性包装器初始化器来进行命名服务解析，如下所示。

swift
Copy code
class NamedInjectedViewController: UIViewController {
    @Injected(name: "fred") var service: XYZNameService
}
你还可以在代码中动态更新名称并实时使用@LazyInjected。

swift
Copy code
class NamedInjectedViewController: UIViewController {
    @LazyInjected var service: XYZNameService
    var which: Bool
    override func viewDidLoad() {
        super.viewDidLoad()
        $service.name = which ? "fred" : "barney"
    }
}
如果选择这种方式，请确保在首次访问注入服务之前指定名称。

可选注入
有一个支持可选解析的注解。如果服务未注册，则该值将为nil，否则它将不为nil：

swift
Copy code
class InjectedViewController: UIViewController {
    @OptionalInjected var service: XYZService?
    func load() {
        service?.load()
    }
}
使用协议进行注入
使用所有注入属性包装器都可以使用协议进行注入。

swift
Copy code
protocol Loader {
    func load()
}

class InjectedViewController: UIViewController {
    @Injected var loader: Loader
    func load() {
        loader.load()
    }
}
提供协议实例的类的注册方式与之前完全相同。有关更多信息，请参阅Protocols。

自定义容器
你可以使用Injected指定和解析自定义容器。只需定义你的自定义容器...

swift
Copy code
extension Resolver {
    static var custom = Resolver()
}
并将其作为Injected属性包装器初始化器的一部分指定。

swift
Copy code
class ContainerInjectedViewController: UIViewController {
    @Injected(container: .custom) var service: XYZNameService
}
与命名注入一样，使用LazyInjected时，你还可以动态指定所需的容器。

swift
Copy code
class NamedInjectedViewController: UIViewController {
    @LazyInjected var service: XYZNameService
    var which: Bool
    override func viewDidLoad() {
        super.viewDidLoad()
        $service.container = which ? "main" : "test"
    }
}
更多信息
我对开发Injected属性包装器写了更多的内容。你可以在我的文章Swift 5.1 Takes Dependency Injection to the Next Level中找到有关Injected和属性包装器的更多信息。
