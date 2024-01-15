#  Resolver: Introduction

## Definitions

Resolver is a Dependency Injection framework for Swift that supports the Inversion of Control design pattern.

Computer Science definitions aside, Dependency Injection pretty much boils down to:

| **Giving an object the things it needs to do its job.**

Dependency Injection allows us to write code that's loosely coupled, and as such, easier to reuse, to mock, and  to test.

## Quick Example

Here's an object that needs  to talk to an NetworkService.

```swift
class MyViewModel {
    let service = NetworkService()
    func load() {
        let data = service.getData()
    }
}
```

This class is considered to be *tightly coupled* to its dependency, NetworkService.

The problem is that MyObject will *always* create it's own service, of type NetworkService, and that's it.

But what if at some point we want MyViewModel to pull its data from a disk instead? What if we want to reuse MyViewModel somewhere else in the code, or in another app, and have it pull different data?

What if we want to mock the results given to MyViewModel for testing?

Or simply have the app run completely on mocked data for QA purposes?

## Injection

Now, consider an object that depends upon an instance of NetworkService being passed to it, using what us DI types term *Property Injection*.

```swift
class MyViewModel {
    var service: NetworkServicing!
    func load() {
        let data = service.getData()
    }
}
```

MyViewModel now depends on the network service being set beforehand, as opposed to directly instantiating a copy of NetworkService itself.

Further, MyViewModel is now using a protocol named NetworkServicing, which in turn defines a  `getData()` method.

Those two changes allow us to meet all of the goals mentioned above.

Pass the right implementation of NetworkServicing to MyViewModel, and the data can be pulled from the network, from a cache, from a test file on disk, or from a pool of mocked data.

Okay, fine. But doesn't this approach just kick the can further down the road?

How do I get MyViewModel and how does MyViewModel get the right version of NetworkServicing? Don't I have to create it and set its property myself?

Well, you could, but the better answer is to use Dependency Injection.

## Registration

Dependency Injection works in two phases: *Registration* and *Resolution*.

Registration consists of registering the classes and objects we're going to need,  as well as providing a *factory* closure to create an instance of one when needed.

```swift
Resolver.register { NetworkService() as NetworkServicing }

Resolver.register { MyViewModel() }.resolveProperties { (_, model) in
    model.service = optional() // note NetworkServicing was defined as an ImplicitlyUnwrappedOptional
}
```

The above looks a bit complex, but it's actually fairly straightforward.

First, we registered a factory (closure) that will create an instance of NetworkService when needed. The type being registered is [automatically inferred](Types.md) using the result type returned by the factory.

Hence we're creating a NetworkService, but we're acutally registering the protocol NetworkServicing.

Similarly, we registered a factory to create MyViewModel's when needed, and we also added a resolveProperties closure to [resolve](Resolving.md) its service property.

## Resolution

Once registered, any object can ask Resolver to provide (resolve) an object of that type.

```swift
var viewModel: MyViewModel = Resolver.resolve()
```

## Why bother?

So we registered a factory, and asked Resolver to resolve it, and it worked... but why go to the extra trouble?

Why we don't just directly instantiate  MyViewModel and be done with it?
```swift
var viewModel = MyViewModel()
viewModel.service = NetworkService()
```
Well, there are several reasons why this is a bad idea, but let's start with two:

First, what happens if NetworkService in turn required other classes or objects to do its job? And what happens if those objects need references to other objects, services, and system resources?

```swift
var viewModel = MyViewModel()
viewModel.service = NetworkService(TokenVendor.token(AppDelegate.seed))
```

You're literally left with needing to construct the objects needed... to build the objects needed... to build the single instance of the object that you actually wanted in the first place.

Those additonal objects are known as *dependencies*.

Second, and worse, the constructing class now knows the internals and requirements for MyViewModel, and for NetworkService, and it also knows about TokenVendor and its requirements.

It's now tightly *coupled* to the behavior and distinct implementations of all of those classes... when all it really wanted to do was talk to a MyViewModel.

## ViewControllers, ViewModel, and Services. Oh, my.

To demonstrate, let's use a more complex example.

Here we have a UIViewController named MyViewController that requires an instance of an XYZViewModel.

```swift
class MyViewController: UIViewController {
    var viewModel: XYZViewModel!
}
```

The XYZViewModel needs an instance of an object that implements a XYZFetching protocol, one that implements XYZUpdating, and the view model also wants access to a XYZService for good measure.

So XYZViewModel wants references to three objects. But in our code, XYZCombinedService implements *both* the XYZFetching and the XYZUpdating protocols *in the same class*. Not to mention that XYZCombinedService also *has its own dependency*, and needs a reference to an XYZSessionService to do its job.

The code makes those dependencies clear.

```swift
class XYZViewModel {
    private var fetcher: XYZFetching
    private var updater: XYZUpdating
    private var service: XYZService

    init(fetcher: XYZFetching, updater: XYZUpdating, service: XYZService) {
        self.fetcher = fetcher
        self.updater = updater
        self.service = service
    }
    // Implmentation
}

class XYZCombinedService: XYZFetching, XYZUpdating {
    private var session: XYZSessionService
    init(_ session: XYZSessionService) {
        self.session = session
    }
    // Implmentation
}

struct XYZService {
    // Implmentation
}

class XYZSessionService {
    // Implmentation
}
```

Note that the initializers for XYZViewModel and XYZCombinedService are each passed the objects they need to do their jobs. To use Dependency Injection lingo, this is known as [Initialization or Constructor Injection](Injection.md#constructor) and it's the recommended approach to object construction.

## Registration

Let's use Resolver to register these classes.

Here we're extending the base Resolver class with the ResolverRegistering protocol, which pretty much just tells Resolver that we've added the registerAllServices() function.

The `registerAllServices` function is automatically called by Resolver the first time it's asked to resolve a service, in effect performing a one-time initialization of the resolution system.

```swift
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
        register { XYZCombinedService(resolve()) }
            .implements(XYZFetching.self)
            .implements(XYZUpdating.self)
        register { XYZService() }
        register { XYZSessionService() }
    }
}
```

So, the above code shows us registering XYZViewModel, the protocols XYZFetching and XYZUpdating, the XYZCombinedService, the XYZService, and the XYZSessionService.

[Learn more about Registration](Registration.md)

## Resolution

Now we've registered all of the objects our app is going to use. But what starts the process? Who resolves first?

Well, MyViewController is the one who wanted a XYZViewModel, so let's rewrite it as follows...

```swift
class MyViewController: UIViewController, Resolving {
    lazy var viewModel: XYZViewModel = resolver.resolve()
}
```

Adopting the Resolving protocol injects the default resolver instance into MyViewController (Interface Injection). Calling resolve on that instance allows it to request a XYZViewModel from Resolver.

Resolver processes the request, finds the right factory to make a XYZViewModel, and tells it to do so. 

The XYZViewModel factory, in turn, triggers the resolution of the types that *it* needs (XYZFetching, XYZUpdating, and XYZService), and so on, down the chain. Eventually, the XYZViewModel factory gets everything it needs, returns the correct instance, and MyViewController gets its view model.

MyViewController doesn't know the internals of XYZViewModel, nor does it know about XYZFetcher's, XYZUpdater's, XYZService's, or XYZSessionService's.

Nor does it need to. It simply asks Resolver for an instance of type T, and Resolver complies.

Learn more about [Resolving](Resolving.md) and the [Resolution Cycle](Cycle.md).

## Mocking

Okay, you might think. That's pretty cool, but earlier you mentioned other benefits, like testing and mocking. What about those?

Consider the following change to the above code:

```swift
extension Resolver {
    static func registerAllServices() {
        register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
        register { XYZCombinedService(resolve()) }
            .implements(XYZFetching.self)
            .implements(XYZUpdating.self)
        register { XYZService() }
        register { XYZSessionService() }

        #if DEBUG
        register { XYZMockSessionService() as XYZSessionService }
        #endif
    }
}
```

This is just one approach, but it illustrates the concept. Now when MyViewController asks for a XYZViewModel, it gets one. The resolved XYZViewModel, in turn has its fetcher, updater, and service.

However, if we're in debug mode the fetcher and updater now have a XYZMockSessionService, which could pull mock data from embedded files instead of going out to the server as normal.

And both MyViewController and XYZViewModel are none the wiser.

## Testing

Same for unit testing. Add something like the following to the unit test code.

```swift
let data: [String : Any] = ["name":"Mike", "developer":true]
Resolver.register { XYZTestSessionService(data) as XYZSessionService }
let viewModel: XYZViewModel = Resolver.resolve()
```

Now your unit and integration tests for XYZViewModel as using XYZTestSessionService, which provides stable, known data to the model.

Do it again.
```swift
let data: [String : Any] = ["name":"Boss", "developer":false]
Resolver.register { XYZTestSessionService(data) as XYZSessionService }
let viewModel: XYZViewModel = Resolver.resolve()
```

And you can now easily test different scenarios.


Resolver: 介绍

定义

Resolver 是 Swift 中支持控制反转设计模式的依赖注入框架。

除了计算机科学的定义外，依赖注入基本上可以理解为：

| 为对象提供执行其工作所需的一切。

依赖注入使我们能够编写松散耦合的代码，因此更容易重用、模拟和测试。

快速示例

这是一个需要与 NetworkService 通信的对象的示例。

swift
Copy code
class MyViewModel {
    let service = NetworkService()
    func load() {
        let data = service.getData()
    }
}
这个类被认为是与其依赖 NetworkService 的紧密耦合。

问题在于 MyObject 将始终创建自己的服务，类型为 NetworkService，并且只能如此。

但是，如果在某个时刻我们希望 MyViewModel 从磁盘上拉取数据呢？如果我们希望在代码的其他地方或另一个应用程序中重用 MyViewModel，并使其拉取不同的数据呢？

如果我们想要为测试目的将给定给 MyViewModel 的结果模拟出来呢？

或者仅仅为了 QA 目的，使应用程序完全运行在模拟数据上呢？

注入

现在，考虑一个对象，它依赖于通过称为属性注入的方式传递给它的 NetworkService 实例。

swift
Copy code
class MyViewModel {
    var service: NetworkServicing!
    func load() {
        let data = service.getData()
    }
}
MyViewModel 现在依赖于预先设置的网络服务，而不是直接实例化 NetworkService 的副本。

此外，MyViewModel 现在使用名为 NetworkServicing 的协议，该协议定义了 getData() 方法。

这两个更改使我们能够实现上面提到的所有目标。

将 NetworkServicing 的正确实现传递给 MyViewModel，即可从网络、缓存、磁盘上的测试文件或模拟数据池中拉取数据。

好吧，但是这种方法难道不是把问题推迟到更远的地方吗？

我如何得到 MyViewModel，MyViewModel 又如何获得正确版本的 NetworkServicing？难道我不必自己创建并设置它的属性吗？

嗯，你可以这样做，但更好的答案是使用依赖注入。

注册

依赖注入分为两个阶段：注册和解析。

注册包括注册我们将需要的类和对象，以及提供在需要时创建一个实例的工厂闭包。

swift
Copy code
Resolver.register { NetworkService() as NetworkServicing }

Resolver.register { MyViewModel() }.resolveProperties { (_, model) in
    model.service = optional() // 注意 NetworkServicing 被定义为隐式解包可选类型
}
上面的代码看起来有点复杂，但实际上相当简单。

首先，我们注册了一个工厂（闭包），该工厂将在需要时创建 NetworkService 的实例。使用工厂返回的结果类型，类型被自动推断。

因此，我们创建了一个 NetworkService，但实际上我们注册的是协议 NetworkServicing。

类似地，我们注册了一个工厂来创建 MyViewModel 的实例，并且我们还添加了一个 resolveProperties 闭包来解析其 service 属性。

解析

一旦注册，任何对象都可以请求 Resolver 提供（解析）该类型的对象。

swift
Copy code
var viewModel: MyViewModel = Resolver.resolve()
为什么麻烦？

所以我们注册了一个工厂，并要求 Resolver 解析它，它奏效了... 但是为什么要多此一举？

我们为什么不直接实例化 MyViewModel 并结束呢？

swift
Copy code
var viewModel = MyViewModel()
viewModel.service = NetworkService()
嗯，有几个原因说明这是个坏主意，但让我们从两个开始：

首先，如果 NetworkService 需要其他类或对象来完成其工作会发生什么？如果这些对象需要引用其他对象、服务和系统资源呢？

swift
Copy code
var viewModel = MyViewModel()
viewModel.service = NetworkService(TokenVendor.token(AppDelegate.seed))
你基本上需要构建构建所需对象的对象... 为了构建你实际上想要的对象的单一实例。

那些额外的对象称为依赖项。

其次，更糟糕的是，构建类现在知道 XYZViewModel 的内部和要求，它还知道 XYZService 的内部和要求，它还知道 TokenVendor 及其要求。

它现在与所有这些类的行为和不同实现紧密耦合在一起... 而它实际上只想与一个 MyViewModel 交谈。

视图控制器、视图模型和服务。哦，我的天啊。

为了演示，让我们使用一个更复杂的示例。

在这里，我们有一个名为 MyViewController 的 UIViewController，它需要一个 XYZViewModel 的实例。

swift
Copy code
class MyViewController: UIViewController {
    var viewModel: XYZViewModel!
}
XYZViewModel 需要一个实现 XYZFetching 协议的对象的实例，一个实现 XYZUpdating 协议的对象的实例，并且视图模型还希望访问 XYZService。

因此，XYZViewModel 希望引用三个对象。但在我们的代码中，XYZCombinedService 在同一类中实现了 XYZFetching 和 XYZUpdating 协议。更不用说 XYZCombinedService 还有自己的依赖性，需要一个 XYZSessionService 的引用才能完成其工作。

代码清晰地显示了这些依赖关系。

swift
Copy code
class XYZViewModel {
    private var fetcher: XYZFetching
    private var updater: XYZUpdating
    private var service: XYZService

    init(fetcher: XYZFetching, updater: XYZUpdating, service: XYZService) {
        self.fetcher = fetcher
        self.updater = updater
        self.service = service
    }
    // 实现
}

class XYZCombinedService: XYZFetching, XYZUpdating {
    private var session: XYZSessionService
    init(_ session: XYZSessionService) {
        self.session = session
    }
    // 实现
}

struct XYZService {
    // 实现
}

class XYZSessionService {
    // 实现
}
请注意，XYZViewModel 和 XYZCombinedService 的初始化器分别传递给它们执行工作所需的对象。按照依赖注入的术语，这称为初始化或构造函数注入，这是对象构建的推荐方法。

注册

让我们使用 Resolver 注册这些类。

在这里，我们使用 Resolver 类扩展 ResolverRegistering 协议，该协议基本上只告诉 Resolver 我们已添加了 registerAllServices() 函数。

registerAllServices 函数在 Resolver 第一次被要求解析服务时自动调用，实际上对解析系统进行一次性初始化。

swift
Copy code
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
        register { XYZCombinedService(resolve()) }
            .implements(XYZFetching.self)
            .implements(XYZUpdating.self)
        register { XYZService() }
        register { XYZSessionService() }
    }
}
所以，上面的代码展示了我们注册了 XYZViewModel、协议 XYZFetching 和 XYZUpdating、XYZCombinedService、XYZService 和 XYZSessionService。

了解更多关于注册

解析

现在我们已经注册了应用程序将要使用的所有对象。但是是什么启动了这个过程？谁先解析？

好吧，MyViewController 是想要 XYZViewModel 的人，所以让我们将其重写为如下...

swift
Copy code
class MyViewController: UIViewController, Resolving {
    lazy var viewModel: XYZViewModel = resolver.resolve()
}
采用 Resolving 协议将默认 resolver 实例注入到 MyViewController 中（接口注入）。在该实例上调用 resolve 允许它请求 Resolver 提供 XYZViewModel。

Resolver 处理请求，找到创建 XYZViewModel 的正确工厂，并告诉它这样做。

XYZViewModel 工厂反过来触发它需要的类型的解析（XYZFetching、XYZUpdating 和 XYZService），依此类推，一直向下。最终，XYZViewModel 工厂获得了它需要的一切，返回了正确的实例，MyViewController 得到了它的视图模型。

MyViewController 不知道 XYZViewModel 的内部，也不知道 XYZFetcher、XYZUpdater、XYZService 或 XYZSessionService 的内部。

它也不需要知道。它只是向 Resolver 请求类型为 T 的实例，Resolver 会遵守。

了解更多关于解析和解析循环。

模拟

好的，你可能会想。这很酷，但前面你提到了其他好处，比如测试和模拟。那些呢？

考虑对上述代码的以下更改：

swift
Copy code
extension Resolver {
    static func registerAllServices() {
        register { XYZViewModel(fetcher: resolve(), updater: resolve(), service: resolve()) }
        register { XYZCombinedService(resolve()) }
            .implements(XYZFetching.self)
            .implements(XYZUpdating.self)
        register { XYZService() }
        register { XYZSessionService() }

        #if DEBUG
        register { XYZMockSessionService() as XYZSessionService }
        #endif
    }
}
这只是一种方法，但它说明了这个概念。现在，当 MyViewController 请求一个 XYZViewModel 时，它会得到一个。解析后的 XYZViewModel 又有它的 fetcher、updater 和 service。

然而，如果我们处于调试模式，fetcher 和 updater 现在会使用 XYZMockSessionService，这可以从嵌入的文件中获取模拟数据，而不是像正常情况下那样从服务器获取数据。

这样，无论是 MyViewController 还是 XYZViewModel 都对此一无所知。

测试

对于单元测试也是一样。在单元测试代码中添加类似以下的内容。

swift
Copy code
let data: [String : Any] = ["name":"Mike", "developer":true]
Resolver.register { XYZTestSessionService(data) as XYZSessionService }
let viewModel: XYZViewModel = Resolver.resolve()
现在，你的 XYZViewModel 的单元测试和集成测试将使用 XYZTestSessionService，它为模型提供稳定、已知的数据。

再做一次。

swift
Copy code
let data: [String : Any] = ["name":"Boss", "developer":false]
Resolver.register { XYZTestSessionService(data) as XYZSessionService }
let viewModel: XYZViewModel = Resolver.resolve()
现在，你可以轻松地测试不同的情景。
