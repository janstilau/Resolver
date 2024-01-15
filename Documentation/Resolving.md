#  Resolver: Resolving

## Resolve using Resolver

Once registered, any object can reach out to Resolver to provide (resolve) an instance of the requested type.

```swift
class MyViewController: UIViewController {
    var xyz: XYZViewModel = Resolver.resolve()
}
```

Used in this fashion, Resolver is acting as a *Service Locator*.

There are pros and cons to the Service Locator approach, the primary two being writing less code vs having your view controllers and other objects "know" about about your Service Locator (i.e. Resolver.)

Note that Resolver's static resolution methods are searching Resolver's **root** container, which is usually the **main** container. [See Containers.](Containers.md)

## Resolve using the Resolving protocol

Any object can implement the Resolving protocol, as shown in the following two examples:

```swift
class MyViewController: UIViewController, Resolving {
    lazy var viewModel: XYZViewModel = resolver.resolve()
}

class ABCExample: Resolving {
    lazy var service: ABCService = resolver.resolve()
}
```

Implementing the Resolving protocol injects the default Resolver into that class as a variable. In this case, calling resolve on that instance allows MyViewController to request a XYZViewModel from Resolver.

All resolution methods available in Resolver (e.g. `resolve()`, `optional()`) are available from the injected variable.


## Resolve using Interface Injection

If you're a bit more of a Dependency Injection purist, you can wrap Resolver as follows.

Add the following to your section's [xxxxx+Injection.swift file](Registration.md#files):

```swift
extension MyViewController: Resolving {
    func makeViewModel() -> XYZViewModel { return resolver.resolve() }
}
```

And now the code contained in  `MyViewController` becomes:

```swift
class MyViewController: UIViewController {
    lazy var viewModel = makeViewModel()
}
```

All the view controller knows is that a function was provided that gives it the view model that it wants.

Note that we're using an injected function to set our variable. It's *possbile* to do:

```swift
extension MyViewController: Resolving {
    var myViewModel: XYZViewModel { return resolver.resolve() }
}
```

But that would resolve a new instance of XYZViewModel each and every time myViewModel is referenced in the code, and that's probably not what you want. (Unless XYZViewModel is completely stateless.)

## Lazy

Note in the last few examples the parameter being resolved was designated as `lazy`.

This delays initialization of the object until its needed, but it also avoids a Swift compiler error. Consider the following:

```swift
class MyViewController: UIViewController, Resolving {
    var viewModel: XYZViewModel = resolver.resolve() // Error
}
```

This will generate a Swift compiler error: *Cannot use instance member 'resolver' within property initializer; property initializers run before 'self' is available.*

Or to put it another way, Swift can't use variables or call functions before all variables are known to be initialized. Adding `lazy` fixes the problem, and also gives us the flexibility to do things like the following:

```swift
class ViewController: UIViewController, Resolving {
    var editMode: Bool = true // set by calling segue
    lazy var viewModel: XYZViewModelProtocol = resolver.resolve(name: editMode ? "edit" : "add")
}
```

Here, the `lazy var` ensures that the viewModel resolution doesn't occur until after the viewController and its properties are instantiated and after `prepareForSegue` has had a chance to correctly set `editMode`.

Named Instances are valuable tools to have around. [Learn more..](Names.md)

## Optionals

Resolver can also automatically resolve optionals... with one minor change.

```swift
var abc: ABCService? = resolver.optional()
var xyz: XYZService! = resolver.optional()
```

Due to the way Swift type inference works, we need to give Resolver a clue that the type we're attempting to resolve is an optional, hence we use `resolver.optional()` and not `resolver.resolve()`.

Note the second line of code. You should also remember that Explicitly Unwrapped Optionals are still optionals at heart, and as such also need the hint.

**If a resolution is failing and you know you've registered the class, check to make sure your variable or parameter isn't an Optional or an Explicitly Unwrapped Optional!**

[Read more about Optionals.](Optionals.md)


## ResolverStoryboard

You can also have Resolver *automatically* resolve view controllers instantiated from Storyboards. (Well, automatically from the view controller's standpoint, anyway.)

[See: Storyboard support.](Storyboards.md)


Resolver: 解析

使用 Resolver 进行解析

一旦注册，任何对象都可以调用 Resolver 以提供（解析）所请求类型的实例。

swift
Copy code
class MyViewController: UIViewController {
    var xyz: XYZViewModel = Resolver.resolve()
}
以这种方式使用，Resolver 就像一个 服务定位器。

服务定位器方法有优缺点，主要的两个优缺点是写更少的代码与让您的视图控制器和其他对象“了解”您的服务定位器（即 Resolver）。

请注意，Resolver 的静态解析方法正在搜索 Resolver 的 根 容器，通常是 main 容器。查看容器。

使用 Resolving 协议进行解析

任何对象都可以实现 Resolving 协议，如下两个示例所示：

swift
Copy code
class MyViewController: UIViewController, Resolving {
    lazy var viewModel: XYZViewModel = resolver.resolve()
}

class ABCExample: Resolving {
    lazy var service: ABCService = resolver.resolve()
}
实现 Resolving 协议将默认的 Resolver 注入该类作为变量。在这种情况下，调用该实例上的 resolve 允许 MyViewController 从 Resolver 请求 XYZViewModel。

所有 Resolver 中可用的解析方法（例如 resolve()、optional()）都可以从注入的变量中使用。

使用接口注入进行解析

如果您更倾向于依赖注入纯粹主义者，可以如下包装 Resolver。

在您的部分的 xxxxx+Injection.swift 文件 中添加以下内容：

swift
Copy code
extension MyViewController: Resolving {
    func makeViewModel() -> XYZViewModel { return resolver.resolve() }
}
现在包含在 MyViewController 中的代码变成了：

swift
Copy code
class MyViewController: UIViewController {
    lazy var viewModel = makeViewModel()
}
视图控制器只知道提供了一个给它所需视图模型的函数。

请注意，我们使用注入的函数设置了我们的变量。这是可能的，做：

swift
Copy code
extension MyViewController: Resolving {
    var myViewModel: XYZViewModel { return resolver.resolve() }
}
但这将在代码中引用 myViewModel 时每次解析 XYZViewModel 的新实例，这可能不是您想要的（除非 XYZViewModel 完全是无状态的）。

延迟加载

请注意，在最后几个示例中，要解析的参数被标记为 lazy。

这将对象的初始化延迟到其需要时，但也避免了 Swift 编译器错误。考虑以下情况：

swift
Copy code
class MyViewController: UIViewController, Resolving {
    var viewModel: XYZViewModel = resolver.resolve() // 错误
}
这将生成一个 Swift 编译器错误：Cannot use instance member 'resolver' within property initializer; property initializers run before 'self' is available. 或者换句话说，Swift 无法在所有变量都已知初始化之前使用变量或调用函数。添加 lazy 修复了问题，还使我们有了以下灵活性：

swift
Copy code
class ViewController: UIViewController, Resolving {
    var editMode: Bool = true // 通过调用 segue 设置
    lazy var viewModel: XYZViewModelProtocol = resolver.resolve(name: editMode ? "edit" : "add")
}
在这里，lazy var 确保在 viewController 及其属性被实例化之后，并且prepareForSegue 有机会正确设置 editMode 之后，才会发生 viewModel 的解析。

命名实例是有价值的工具。了解更多..

可选项

Resolver 也可以自动解析可选项... 只需进行一点点的更改。

swift
Copy code
var abc: ABCService? = resolver.optional()
var xyz: XYZService! = resolver.optional()
由于 Swift 类型推断的工作方式，我们需要给 Resolver 一个提示，告诉它我们正在尝试解析的类型是一个可选项，因此我们使用 resolver.optional() 而不是 resolver.resolve()。

请注意代码的第二行。您还应该记住，显式解包的可选项在本质上仍然是可选项，因此也需要这个提示。

如果解析失败并且您知道已注册了该类，请确保您的变量或参数不是可选项或显式解包的可选项！
