#  Resolver: Named Instances

## Why Name a Registration?

Because named registrations and resolutions let you change the behavior of the app and determine just which service or value should be resolved for a given type.

Dependency Injection is powerful tool, but named registrations take the entire concept to an entriely different level.

## Registering a Name

Resolver 1.3 adds a `Name` space to Resolver similar to that of `Notificiations.Name`.  Registering a name lets you use Xcode's autocompletion feature for registrations and to resolve named instances and also ensures that you don't accidentally use "fred" in one place, "Fred" in another, and "Freddy" somewhere else.

You define your own names by extending `Resolver.Name` as follows:

```swift
extension Resolver.Name {
    static let fred = Self("Fred")
    static let barney = Self("Barney")
}
```
Once defined your names can be used in the `name` parameter  when registering services. Here we define two instances of the same protocol, distinguished by name.
```swift
register(name: .fred) { XYZServiceFred() as XYZServiceProtocol }
register(name: .barney) { XYZServiceBarney() as XYZServiceProtocol }
```
Once defined and registered, names can be used during the resolution process to pick just which version of the service you desire.
```swift
let service: XYZServiceProtocol = resolve(name: .fred)
// or
@Injected(name: .barney) var service: XYZServiceProtocol
```

## Using Named Value Types

In addition to services you can also register value types and parameters for later resolution. However, since Resolver registers objects and values based on type inference, the only way to tell one `String` from another `String` is to name it.

We start once again by defining the names we want to use, in this case `appKey` and `token`.

```swift
extension Resolver.Name {
    static let appKey = Self("appKey")
    static let token = Self("token")
}
```
We then register some strings using our `.appKey` and `token` names.
```swift
register(name: .appKey) { "12345" }
register(name: .token) { "123e4567-e89b-12d3-a456-426614174000" }
```
Which can then be used when we resolve our services. The following code shows how a factory resolves a String parameter named `.appKey`, which passes the resulting string value to the `XYZSessionService` initialization function.
```swift
register { XYZSessionService(key: resolve(name: .appKey)) }
```

This is a good way to get authentication keys, application keys, and other values to the objects that need them. 

## Mocking Data

We can also use names to control access to mocked data. Consider the following set of registrations.

```swift
extension Resolver.Name {
    static let data = Self("data")
    static let mock = Self("mock")
}

register(name: .data) { XYXService() as XYZServicing }
register(name: .mock) { XYXMockService() as XYZServicing }

register { resolve(name: .name(fromString: Bundle.main.infoDictionary!["mode"] as! String)) as XYZServicing }

```

Here we've registered the XYZServicing protocol three times:  once with the name space `.data`, and then again version with the name space `.mock`. The third registration, however, has no name. 

Instead, it gets a string from the app's info.plist and asks Resolver to resolve an instance with the proper type and with the proper name.

Let's see it in use by a client.

```swift
@Injected var service: XYZServicing
```

The client just asks Resolver for an instance of `XYZServicing`.

Behind the scenes, however, and depending upon how the app is compiled and how the "mode" value is set in the app's plist, one build will get actual data, while the other build will get mock data.

And as long as XYXMockService complies with the XYZServicing protocol, the client doesn't care.

Nor should it.

One final note here is that we registered `Resolver.Name` instances, but in our factory we converted `mode` into a `Name` based on the value of the string we pulled from the plist. Just be careful when you're doing this and make sure your passed strings actually match names actually registered in the app.

## Changing Behavior On The Fly

Finally, consider the next pair of registrations:

```swift
extension Resolver.Name {
    static let add = Self("add")
    static let edit = Self("edit")
}

register(name: .add) { XYZViewModelAdding() as XYZViewModelProtocol }
register(name: .edit) { XYZViewModelEditing() as XYZViewModelProtocol }
```

Here we're registering two instances of the same protocol, `XYZViewModelProtocol`.

But one view model appears to be specific to adding things, while the other's behavior leans more towards editing.


```swift
class ViewController: UIViewController, Resolving {
    var editMode: Bool = true // set, perhaps, by calling segue
    lazy var viewModel: XYZViewModelProtocol = resolver.resolve(name: editMode ? .edit : .add)!
}
```

Now the view controller gets the proper view model for the job. The `lazy var` ensures that the viewModel resolution doesn't occur until after the viewController is instantiated and `prepareForSegue` has had a chance to correctly set `editMode`.

If you're using Resolver's property wrappers for injection, you can also do the same with `@LazyInjected`.

```swift
class NamedInjectedViewController: UIViewController {
    var editMode: Bool // set, perhaps, by calling segue
    @LazyInjected var viewModel: XYZViewModelProtocol
    override func viewDidLoad() {
        super.viewDidLoad()
        $viewModel.name = editMode ? .edit : .add
        viewModel.load()
    }
}
```
Again, just make sure you set the property name *before* using the wrapped `viewModel` for the first time.

## Using String Literals and String Variables

Name spaces are better than simple string literals. Use them.

That said, you should be aware that `Name` supports the `ExpressibleByStringLiteral` protocol, which means that you can also use a string *literal* to register and resolve your instances (e.g. `resolve(name: "Fred")`). 

String *variables*, however, are *not* automatically converted. If you're trying to translate a string variable to a `Name`, you either need to initialize it directly `Resolver.Name(myString)`, or do as we did in a previous example using the `.name(fromString: myString)` syntax.

```swift
    viewModel = resolver.optional(name: .name(fromString: type))
```

Be aware that string literal support exists primarily for backwards compatibility with earlier versions of Resolver and that raw string paramaters will probably become deprecated in a future instance of Resolver. 

*Name spaces are based on a PR concept submitted by [Artem K./DesmanLead](https://github.com/DesmanLead).*


解析器：命名实例

为什么要为注册命名？

因为命名的注册和解析让您能够更改应用程序的行为，并确定在给定类型的情况下应解析哪个服务或值。

依赖注入是一种强大的工具，但命名的注册将整个概念提升到一个完全不同的水平。

注册一个名称

Resolver 1.3 在 Resolver 中添加了一个 Name 空间，类似于 Notificiations.Name。注册名称使您能够在注册和解析命名实例时使用Xcode的自动完成功能，并确保您不会在一个地方意外使用 "fred"，在另一个地方使用 "Fred"，而在另一个地方使用 "Freddy"。

通过扩展 Resolver.Name 来定义您自己的名称，如下所示：

swift
Copy code
extension Resolver.Name {
    static let fred = Self("Fred")
    static let barney = Self("Barney")
}
一旦定义了您的名称，就可以在注册服务时使用 name 参数。在这里，我们定义了两个相同协议的实例，通过名称进行区分。

swift
Copy code
// 注册了同样的抽象接口, 但是通过了名称进行了区分. 
register(name: .fred) { XYZServiceFred() as XYZServiceProtocol }
register(name: .barney) { XYZServiceBarney() as XYZServiceProtocol }
一旦定义并注册，名称可以在解析过程中使用，以选择您所需的服务版本。

swift
Copy code
let service: XYZServiceProtocol = resolve(name: .fred)
// 或者
@Injected(name: .barney) var service: XYZServiceProtocol
使用命名值类型

除了服务之外，您还可以注册值类型和参数以供以后解析。然而，由于 Resolver 基于类型推断注册对象和值，要区分一个 String 和另一个 String 的唯一方法是给它们命名。

我们首先通过扩展 Resolver.Name 来定义我们要使用的名称，即 appKey 和 token。

swift
Copy code
extension Resolver.Name {
    static let appKey = Self("appKey")
    static let token = Self("token")
}
然后，我们使用我们的 .appKey 和 token 名称注册一些字符串。

swift
Copy code
register(name: .appKey) { "12345" }
register(name: .token) { "123e4567-e89b-12d3-a456-426614174000" }
然后，在解析服务时，可以使用这些名称。以下代码显示了一个工厂如何解析名为 .appKey 的字符串参数，并将生成的字符串值传递给 XYZSessionService 的初始化函数。

swift
Copy code
register { XYZSessionService(key: resolve(name: .appKey)) }
这是将身份验证密钥、应用程序密钥和其他值传递给需要它们的对象的良好方法。

模拟数据

我们还可以使用名称来控制对模拟数据的访问。考虑以下一组注册。

swift
Copy code
extension Resolver.Name {
    static let data = Self("data")
    static let mock = Self("mock")
}

register(name: .data) { XYXService() as XYZServicing }
register(name: .mock) { XYXMockService() as XYZServicing }

register { resolve(name: .name(fromString: Bundle.main.infoDictionary!["mode"] as! String)) as XYZServicing }
在这里，我们已经注册了 XYZServicing 协议三次：一次使用名称空间 .data，然后再次使用名称空间 .mock。然而，第三个注册没有名称。

相反，它从应用程序的 info.plist 获取一个字符串，并要求 Resolver 根据正确的类型和名称解析一个实例。

让我们看看客户端如何使用它。

swift
Copy code
@Injected var service: XYZServicing
客户端只是向 Resolver 请求 XYZServicing 的实例。

然而，在幕后，取决于应用程序是如何编译以及在应用程序的 plist 中如何设置 "mode" 值，一个构建将获取实际数据，而另一个构建将获取模拟数据。

只要 XYXMockService 符合 XYZServicing 协议，客户端就不关心。

也不应该关心。

这里最后需要注意的是，我们注册了 Resolver.Name 实例，但在我们的工厂中，我们将 mode 转换为基于我们从 plist 中提取的字符串值的 Name。在执行此操作时要小心，并确保传递的字符串实际上与在应用程序中实际注册的名称匹配。

动态更改行为

最后，考虑下面这一对注册：

swift
Copy code
extension Resolver.Name {
    static let add = Self("add")
    static let edit = Self("edit")
}

register(name: .add) { XYZViewModelAdding() as XYZViewModelProtocol }
register(name: .edit) { XYZViewModelEditing() as XYZViewModelProtocol }
在这里，我们注册了两个相同协议的实例，XYZViewModelProtocol。

但一个视图模型似乎是专门用于添加事物，而另一个的行为更偏向编辑。

swift
Copy code
class ViewController: UIViewController, Resolving {
    var editMode: Bool = true // 可能通过调用 segue 来设置
    lazy var viewModel: XYZViewModelProtocol = resolver.resolve(name: editMode ? .edit : .add)!
}
现在，视图控制器获取了适用于该工作的正确视图模型。lazy var 确保在实例化 viewController 之后和 prepareForSegue 有机会正确设置 editMode 之后，才进行 viewModel 解析。

如果您使用 Resolver 的属性包装器进行注入，您还可以使用 @LazyInjected 实现相同的效果。

swift
Copy code
class NamedInjectedViewController: UIViewController {
    var editMode: Bool // 可能通过调用 segue 来设置
    @LazyInjected var viewModel: XYZViewModelProtocol
    override func viewDidLoad() {
        super.viewDidLoad()
        $viewModel.name = editMode ? .edit : .add
        viewModel.load()
    }
}
再次强调，请确保在首次使用包装的 viewModel
