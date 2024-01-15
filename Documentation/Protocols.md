#  Resolver: Protocols

### Registering a protocol

Remember, Resolver automatically infers the registration type based on the type of object returned by the factory closure.

As such, registering a protocol that's implemented by a specific type of an object is pretty straightforward.

```swift
main.register { XYZCombinedService() as XYZFetching }
```

Here, we're registering how to get an object that implements the XYZFetching protocol.

The registration factory is *creating* an object of type `XYZCombinedService`, but it's *returning* a type of `XYZFetching`, and that's what's being registered.

### Registering an object with multiple protocols

Registering an object with multiple protocols is pretty much the same as the above, except you need to register each protocol separately.

```swift
main.register { XYZCombinedService() as XYZFetching }
main.register { XYZCombinedService() as XYZUpdating }
```

One should note in this example that the factories for XYZFetching and XYZUpdating are each instantiating and returning their own separate, distinct instances of `XYZCombinedService`, even though both interfaces were actually implemented in the same object.

Sometimes this is what you want.

But it's more likely that if both interfaces were implemented in the same object, you'd like to resolve both interfaces to the same object during a given resolution cycle.

### Protocols sharing the same instance

Consider the next example:

```swift
main.register { resolve() as XYZCombinedService as XYZFetching }
main.register { resolve() as XYZCombinedService as XYZUpdating }
main.register { XYZCombinedService() }
```

It looks strange, but it makes sense. In the first line you're asking Resolver to resolve a XYZCombinedService instance, which you're registering and returning as type XYZFetching.

In the second line you're asking Resolver to again resolve a XYZCombinedService instance, which you're registering and returning as type XYZUpdating.

The last line registers how to make an XYZCombinedService().

Now, both the XYZFetching and XYZUpdating protocols are tied to the same object, and given the default [graph scope](Scopes.md), only one instance of XYZCombinedService will be constructed during a specific [resolution cycle](Cycle.md) when both protocols are resovled.

### Protocols sharing the same instance across resolution cycles

The preceding example shares `XYZCombinedService` during a given [resolution cycle](Cycle.md).

But what if we want any instance of `XYZFetching` or `XYZUpdating` to *always* share the same instance?

```swift
main.register { XYZCombinedService() }
    .scope(.shared)
```

We use a [shared scope](Scopes.md).

### Registering multiple protocols using .implements

A simpler way to rewrite the above registration example uses Resolver's `implements` registration option:

```swift
main.register { XYZCombinedService() }
    .implements(XYZFetching.self)
    .implements(XYZUpdating.self)
```

Resolver registers `XYZCombinedService` for you, and then does the same for `XYZFetching` and `XYZUpdating`, pointing all three registrations to the same factory.

Note that the `.self` passed to the `.implements` method simply tells Swift that we want the object type, not the object itself.


Resolver: 协议

注册协议
请记住，Resolver会根据工厂闭包返回的对象类型自动推断注册类型。

因此，注册一个由特定类型的对象实现的协议非常简单。

swift
Copy code
main.register { XYZCombinedService() as XYZFetching }
在这里，我们正在注册如何获取一个实现XYZFetching协议的对象。

注册工厂正在创建一个类型为XYZCombinedService的对象，但它正在返回一个类型为XYZFetching的对象，并且这就是正在注册的内容。

注册具有多个协议的对象
注册具有多个协议的对象与上述相同，只是您需要分别注册每个协议。

swift
Copy code
main.register { XYZCombinedService() as XYZFetching }
main.register { XYZCombinedService() as XYZUpdating }
在这个例子中，XYZFetching和XYZUpdating的工厂每个都在实例化并返回它们自己单独的XYZCombinedService实例，尽管实际上两个接口都是在同一个对象中实现的。

有时这是您想要的。

但更可能的是，如果两个接口都在同一个对象中实现，您可能希望在给定的解析周期内将两个接口解析为同一个对象。

共享相同实例的协议
考虑下一个例子：

swift
Copy code
main.register { resolve() as XYZCombinedService as XYZFetching }
main.register { resolve() as XYZCombinedService as XYZUpdating }
main.register { XYZCombinedService() }
这看起来很奇怪，但是它是有道理的。在第一行中，您要求Resolver解析XYZCombinedService实例，将其注册并返回为XYZFetching类型。

在第二行中，您再次要求Resolver解析XYZCombinedService实例，将其注册并返回为XYZUpdating类型。

最后一行注册了如何创建XYZCombinedService()。

现在，XYZFetching和XYZUpdating协议都与同一个对象相关联，并且在特定的解析周期中解析两个协议时，将构造XYZCombinedService的一个实例。

在解析周期间共享相同实例的协议
前面的例子在给定的解析周期中共享XYZCombinedService。

但是如果我们希望任何XYZFetching或XYZUpdating的实例始终共享相同的实例怎么办？

swift
Copy code
main.register { XYZCombinedService() }
    .scope(.shared)
我们使用一个共享范围。

使用 .implements 注册多个协议
重写上述注册示例的更简单方法是使用Resolver的 implements 注册选项：

swift
Copy code
main.register { XYZCombinedService() }
    .implements(XYZFetching.self)
    .implements(XYZUpdating.self)
Resolver为您注册XYZCombinedService，然后为XYZFetching和XYZUpdating做同样的事情，将所有三个注册指向同一个工厂。

请注意，传递给.implements方法的.self只是告诉Swift我们要对象类型，而不是对象本身
