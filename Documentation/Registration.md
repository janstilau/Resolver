#  Resolver: Registration

## Introduction

As mentioned in the introduction, in order for Resolve to *resolve* a request for a paticular service you first need to register a factory that knows how to instantiate an instance of the service.

```swift
Resolver.register { NetworkService() }
```

Resolver will then automatically use that factory whenever it's asked to resolve an instance of  `NetworkService`.

```swift
class MyViewModel {
    @Injected var network: NetworkService
}
```
Pretty straightforward, right? We need to register our services. 

But where do we put those all of those registrations?

Well, it's a common practice with Resolver, Swinject, and other DI systems to add addtional "injection" files to your project to support the dependencies needed by a particular part of the code base.

Let's start by adding the master injection file for the entire application.

## Add the AppDelegate Injection File

Add a file named `AppDelegate+Injection.swift` to your project and add the following code:

```swift
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

    }
}
```

If you're using frameworks, CocoaPods or Carthage, you'll need the `import Resolver` line. If you added Resolver.swift directly to your project, just delete that line.

Resolver automatically calls the `registerAllServices` function the very first time it's asked to resolve a particular service. But as is, it's not very useful until you actually register some classes.

Note that we add our registration functionality directly into the Resolver namespace.  This gives our registration factories direct access to the registration and resolution functions contained within that namespace. (e.g. `register`, `resolve`, etc..)

## Add Injection Files<a name=files></a>

As mentioned above, we add addtional "injection" files to our projects to support the dependencies needed by a particular part of the code base.

Let's say you have a group in your project folder named "NetworkServices", and you want to register some of those services for use by Resolver.

#### 1. Add your own registration file.

Go to the NetworkServices folder and add a swift file named: `NetworkServices+Injection.swift`, then add the following to that file...

```swift
#import Resolver

extension Resolver {
    public static func registerMyNetworkServices() {

    }
}
```

#### 2. Update the master file.

Now, go back to your  `AppDelegate+Injection.swift` file and add a reference to `registerMyNetworkServices`.

```swift
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        registerMyNetworkServices()
    }
}
```

Resolver will automatically call `registerAllServices`, and that function in turn calls each of your own registration functions.

#### 3. Add your own registrations.

Now, housekeeping completed, return to  `NetworkServices+Injection.swift` and add your own registrations.

Just as an example:

```swift
import Resolver

extension Resolver {

    public static func registerMyNetworkServices() {

        // Register protocols XYZFetching and XYZUpdating and create implementation object
        register { XYZCombinedService() }
            .implements(XYZFetching.self)
            .implements(XYZUpdating.self)

        // Register XYZNetworkService and return instance in factory closure
        register { XYZNetworkService(session: resolve()) }

        // Register XYZSessionService and return instance in factory closure
        register { XYZSessionService() }
    }
    
}
```

That's it. Resolver uses  Swift [type inference](Types.md) to automatically determine and register the type of object being returned by the registration factory.

And in the case of `XYZNetworkService`, Resolver is used to infer the type of the session parameter that's needed to initialize a `XYZNetworkService`.

This works with classes, structs, and protocols, though there are a few special cases and considerations for [protocols](Protocols.md).

You can also register [value types](Names.md), though that too has a few special considerations.



Resolver: 注册

简介

如介绍中所提到的，为了让 Resolver 能够解析对特定服务的请求，您首先需要注册一个工厂，该工厂知道如何实例化该服务的实例。

swift
Copy code
Resolver.register { NetworkService() }
Resolver将在每次需要解析NetworkService实例时自动使用该工厂。

swift
Copy code
class MyViewModel {
    @Injected var network: NetworkService
}
相当简单，对吧？我们需要注册我们的服务。

但是我们把所有这些注册放在哪里呢？

嗯，使用 Resolver、Swinject 和其他 DI 系统时，向项目中添加额外的“注入”文件以支持代码库中特定部分需要的依赖关系是一种常见的做法。

让我们首先添加整个应用程序的主注入文件。

添加 AppDelegate 注入文件

在项目中添加一个名为 AppDelegate+Injection.swift 的文件，并添加以下代码：

swift
Copy code
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {

    }
}
如果使用的是框架、CocoaPods 或 Carthage，您将需要添加 import Resolver 行。如果直接将 Resolver.swift 添加到项目中，请删除该行。

Resolver在第一次被要求解析特定服务时自动调用 registerAllServices 函数。但是，目前它并没有太大用处，直到您实际注册了一些类。

请注意，我们将我们的注册功能直接添加到 Resolver 命名空间中。这使得我们的注册工厂可以直接访问该命名空间中包含的注册和解析功能（例如 register、resolve 等）。

添加注入文件<a name=files></a>

如上所述，我们向项目中添加额外的“注入”文件以支持代码库中特定部分需要的依赖关系。

假设您的项目文件夹中有一个名为 "NetworkServices" 的组，并且您希望注册 Resolver 使用的一些服务。

1. 添加您自己的注册文件。
转到 NetworkServices 文件夹并添加一个名为：NetworkServices+Injection.swift 的 Swift 文件，然后将以下内容添加到该文件中...

swift
Copy code
#import Resolver

extension Resolver {
    public static func registerMyNetworkServices() {

    }
}
2. 更新主文件。
现在，返回到 AppDelegate+Injection.swift 文件，并引用 registerMyNetworkServices。

swift
Copy code
extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        registerMyNetworkServices()
    }
}
Resolver将自动调用 registerAllServices，而该函数又依次调用您自己的注册函数。

3. 添加您自己的注册。
现在，所有设置已经完成，返回到 NetworkServices+Injection.swift 并添加您自己的注册。

只是作为一个例子：

swift
Copy code
import Resolver

extension Resolver {

    public static func registerMyNetworkServices() {

        // 注册协议 XYZFetching 和 XYZUpdating，并创建实现对象
        register { XYZCombinedService() }
            .implements(XYZFetching.self)
            .implements(XYZUpdating.self)

        // 注册 XYZNetworkService 并在工厂闭包中返回实例
        register { XYZNetworkService(session: resolve()) }

        // 注册 XYZSessionService 并在工厂闭包中返回实例
        register { XYZSessionService() }
    }
    
}
就是这样。 Resolver 使用 Swift 类型推断 来自动确定并注册由注册工厂返回的对象的类型。

对于 XYZNetworkService，Resolver 用于推断初始化 XYZNetworkService 所需的 session 参数的类型。

这适用于类、结构和协议，尽管对于 协议 有一些特殊情况和注意事项。

您还可以注册 值类型，不过这也有一些特殊的考虑因素。
