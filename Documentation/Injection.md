#  Resolver: Injection Strategies

## Terminology

There are five primary ways of performing dependency injection using Resolver:

1. [Interface Injection](#interface)
2. [Property Injection](#property)
3. [Constructor Injection](#constructor)
4. [Method Injection](#method)
5. [Service Locator](#locator)
6. [Annotation](#annotation) (NEW)

The names and numbers come from the *Inversion of Control* design pattern. For a more thorough discussion, see the classic arcticle by [Martin Fowler](https://martinfowler.com/articles/injection.html).

Here I'll simply provide a brief description and an example of implementing each using Resolver.

## <a name=interface></a>1. Interface Injection

#### Definition

The first injection technique is to define a interface for the injection, and injecting that interface into the class or object using Swift extensions.

#### The Class

```swift
class XYZViewModel {

    lazy var fetcher: XYZFetching = getFetcher()
    lazy var service: XYZService = getService()

    func load() -> Data {
        return fetcher.getData(service)
    }

}
```

#### The Dependency Injection Code

```swift
extension XYZViewModel: Resolving {
    func getFetcher() -> XYZFetching { return resolver.resolve() }
    func getService() -> XYZService { return resolver.resolve() }
}

func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
```

Note that you still want to call `resolve()` within `getFetcher()` and `getService()` , otherwise you're back to tightly-coupling the dependent classes and bypassing the resolution registration system.

#### Pros

* Lightweight.
* Hides dependency injection system from class.
* Useful for classes like UIViewController where you don't have access during the initialization process.

#### Cons

* Writing an accessor function for every service that needs to be injected.

## <a name=property></a>2. Property Injection

#### Definition

Property Injection exposes its dependencies as properties, and it's up to the Dependency Injection system to make sure everything is setup prior to any methods being called.

#### The Class

```swift
class XYZViewModel {

    var fetcher: XYZFetching!
    var service: XYZService!

    func load() -> Data {
        return fetcher.getData(service)
    }

}
```

#### The Dependency Injection Code

```swift
func setupMyRegistrations {
    register { XYZViewModel() }
        .resolveProperties { (resolver, model) in
            model.fetcher = resolver.optional() // Note property is an ImplicitlyUnwrappedOptional
            model.service = resolver.optional() // Ditto
        }
}


func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
```

#### Pros

* Clean.
* Also fairly lightweight.

#### Cons

* Exposes internals as public variables.
* Harder to ensure that an object has been given everything it needs to do its job.
* More work on the registration side of the fence.

## <a name=constructor></a>3. Constructor Injection

#### Definition

A Constructor is the Java term for a Swift Initializer, but the idea is the same: Pass all of the dependencies an object needs through its initialization function.

#### The Class

```swift
class XYZViewModel {

    private var fetcher: XYZFetching
    private var service: XYZService

    init(fetcher: XYZFetching, service: XYZService) {
        self.fetcher = fetcher
        self.service = service
    }

    func load() -> Image {
        let data = fetcher.getData(token)
        return service.decompress(data)
   }

}
```

#### The Dependency Injection Code

```swift
func setupMyRegistrations {
    register { XYZViewModel(fetcher: resolve(), service: resolve()) }
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
```

#### Pros

* Ensures that the object has everything it needs to do its job, as the object can't be constructed otherwise.
* Hides dependencies as private or internal.
* Less code needed for the registration factory.

#### Cons

* Requires object to have initializer with all parameters needed.
* More boilerplace code needed in the object initializer to transfer parameters to object properties.

## <a name=method></a>4. Method Injection

#### Definition

This is listed for competeness, even though it's not a pattern that uses Resolver directly.

Method Injection is pretty much what it says, injecting the object needed into a given method.

#### The Class

```swift
class XYZViewModel {

    func load(fetcher: XYZFetching, service: XYZFetching) -> Data {
        return fetcher.getData(service)
    }

}
```

#### The Dependency Injection Code

You've already seen it. In the load function, the service object is passed into the fetcher's getData method.

#### Pros

* Allows callers to configure the behavior of a method on the fly.
* Allows callers to construct their own behaviors and pass them into the method.

#### Cons

* Exposes those behaviors to all of the classes that use it.

#### Note

In Swift, passing a closure into a method could also be considered a form of Method Injection.

## <a name=locator></a>5. Service Locator

#### Definition

A Service Locator is basically a service that locates the resources and dependencies an object needs.

Technically, Service Locator is its own Design Pattern, distinct from Dependency Injection, but Resolver supports both and the Service Locator pattern is particularly useful when supporting view controllers and other classes where the initialization process is outside of your control. (See [Storyboards](https://github.com/hmlongco/Resolver/blob/master/Documentation/Storyboards.md).)

#### The Class

```swift
class XYZViewModel {

    var fetcher: XYZFetching = Resolver.resolve()
    var service: XYZService = Resolver.resolve()

    func load() -> Data {
        return fetcher.getData(service)
    }

}
```

#### The Dependency Injection Code

```swift
func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
```

#### Pros

* Less code.
* Useful for classes like UIViewController where you don't have access during the initialization process.

#### Cons

* Exposes the dependency injection system to all of the classes that use it.

## <a name=annotation></a>6. Annotation

#### Definition

Annotation uses comments or other metadata to indication that dependency injection is required. As of Swift 5.1, we can now perform annotation using Property Wrappers. (See [Annotation](https://github.com/hmlongco/Resolver/blob/master/Documentation/Annotation.md).)

#### The Class

```swift
class XYZViewModel {

    @Injected var fetcher: XYZFetching
    @Injected var service: XYZService

    func load() -> Data {
        return fetcher.getData(service)
    }

}
```

#### The Dependency Injection Code

```swift
func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
```

#### Pros

* Less code.
* Hides the specifics of the injection system. One could easily make an Injected property wrapper to support any DI system.
* Useful for classes like UIViewController where you don't have access during the initialization process.

#### Cons

* Exposes the fact that a dependency injection system is used.

## Additonal Resources

This just skims the surface. For a more in-depth look at the pros and cons, see: [Inversion of Control Containers and the Dependency Injection pattern ~ Martin Fowler](https://martinfowler.com/articles/injection.html).

Resolver：注入策略

术语

使用Resolver执行依赖注入的五种主要方式是：

接口注入
属性注入
构造函数注入
方法注入
服务定位器
注解（新）
这些名称和数字来自于控制反转设计模式。有关更详细的讨论，请参见Martin Fowler的经典文章。

在这里，我将简要介绍并提供使用Resolver实现每种方式的示例。

<a name=interface></a>1. 接口注入

定义
第一种注入技术是为注入定义一个接口，并使用Swift扩展将该接口注入到类或对象中。

类
swift
Copy code
class XYZViewModel {

    lazy var fetcher: XYZFetching = getFetcher()
    lazy var service: XYZService = getService()

    func load() -> Data {
        return fetcher.getData(service)
    }

}
依赖注入代码
swift
Copy code
extension XYZViewModel: Resolving {
    func getFetcher() -> XYZFetching { return resolver.resolve() }
    func getService() -> XYZService { return resolver.resolve() }
}

func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
请注意，你仍然希望在getFetcher()和getService()内部调用resolve()，否则你将重新将依赖的类耦合在一起并绕过解析注册系统。

优点
轻量级。
将依赖注入系统隐藏在类中。
对于像UIViewController这样在初始化过程中无法访问的类非常有用。
缺点
为每个需要注入的服务编写一个访问器函数。
<a name=property></a>2. 属性注入

定义
属性注入将其依赖项公开为属性，Resolver负责在调用任何方法之前设置好一切。

类
swift
Copy code
class XYZViewModel {

    var fetcher: XYZFetching!
    var service: XYZService!

    func load() -> Data {
        return fetcher.getData(service)
    }

}
依赖注入代码
swift
Copy code
func setupMyRegistrations {
    register { XYZViewModel() }
        .resolveProperties { (resolver, model) in
            model.fetcher = resolver.optional() // 注意属性是一个ImplicitlyUnwrappedOptional
            model.service = resolver.optional() // 同上
        }
}


func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
优点
干净。
也相当轻量级。
缺点
将内部暴露为公共变量。
更难确保对象已获得执行其工作所需的一切。
在注册方面需要更多的工作。
<a name=constructor></a>3. 构造函数注入

定义
构造函数是Java术语，用于Swift初始化器，但思想是相同的：通过其初始化函数传递对象需要的所有依赖项。

类
swift
Copy code
class XYZViewModel {

    private var fetcher: XYZFetching
    private var service: XYZService

    init(fetcher: XYZFetching, service: XYZService) {
        self.fetcher = fetcher
        self.service = service
    }

    func load() -> Image {
        let data = fetcher.getData(token)
        return service.decompress(data)
   }

}
依赖注入代码
swift
Copy code
func setupMyRegistrations {
    register { XYZViewModel(fetcher: resolve(), service: resolve()) }
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
优点
确保对象具有执行其工作所需的一切，因为否则无法构造对象。
将依赖项隐藏为私有或内部。
在注册工厂中需要更少的代码。
缺点
要求对象具有包含所有参数的初始化器。
在对象初始化器中需要更多的样板代码来将参数传递给对象属性。
<a name=method></a>4. 方法注入

定义
虽然它不是直接使用Resolver的一种模式，但列在这里是为了完整性。

方法注入基本上就是它所说的，将所需的对象注入到给定的方法中。

类
swift
Copy code
class XYZViewModel {

    func load(fetcher: XYZFetching, service: XYZFetching) -> Data {
        return fetcher.getData(service)
    }

}
依赖注入代码
你已经看到了。在load函数中，将服务对象传递给fetcher的getData方法。

优点
允许调用者动态配置方法的行为。
允许调用者构建自己的行为并将其传递到方法中。
缺点
将这些行为暴露给使用它的所有类。
注意
在Swift中，将闭包传递到方法中也可以被视为一种方法注入形式。

<a name=locator></a>5. 服务定位器

定义
服务定位器基本上是一个查找对象所需资源和依赖项的服务。

从技术上讲，服务定位器是自己的设计模式，与依赖注入不同，但Resolver支持两者，当支持视图控制器和其他类时，初始化过程不在你的控制之内时，服务定位器模式尤其有用。 （参见Storyboards。）

类
swift
Copy code
class XYZViewModel {

    var fetcher: XYZFetching = Resolver.resolve()
    var service: XYZService = Resolver.resolve()

    func load() -> Data {
        return fetcher.getData(service)
    }

}
依赖注入代码
swift
Copy code
func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
优点
代码更少。
对于像UIViewController这样在初始化过程中无法访问的类非常有用。
缺点
将依赖注入系统暴露给使用它的所有类。
<a name=annotation></a>6. 注解

定义
注解使用注释或其他元数据来表示需要依赖注入。从Swift 5.1开始，我们现在可以使用属性包装器执行注解。 （参见注解。）

类
swift
Copy code
class XYZViewModel {

    @Injected var fetcher: XYZFetching
    @Injected var service: XYZService

    func load() -> Data {
        return fetcher.getData(service)
    }

}
依赖注入代码
swift
Copy code
func setupMyRegistrations {
    register { XYZFetcher() as XYZFetching }
    register { XYZService() }
}
优点
代码更少。
隐藏了注入系统的具体情况。可以轻松制作一个Injected属性包装器，以支持任何DI系统。
对于像UIViewController这样在初始化过程中无法访问的类非常有用。
缺点
暴露了使用依赖注入系统的事实。
附加资源

这只是皮毛。有关更详细的优缺点，请参见：Inversion of Control Containers and the Dependency Injection pattern ~ Martin Fowler。
