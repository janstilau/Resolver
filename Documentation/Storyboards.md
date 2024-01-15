#  Resolver: Storyboards

NOTE: As of Swift 5.1, we can now perform annotation using Property Wrappers. (See [Annotation](https://github.com/hmlongco/Resolver/blob/master/Documentation/Annotation.md).)

```swift
class MyViewController: UIViewController {
    @Injected var viewModel: XYZViewModel
}
```
I highly recommend this approach over the other methods shown below.

## Property Injection

Resolver supports automatic UIViewController property injection using the StoryboardResolving protocol, but using it requires two steps.

Let's assume the following view controller, which needs a XYZViewModel in order to function.

```swift
class MyViewController: UIViewController {
    var viewModel: XYZViewModel!
}
```
### Step 1: Add the resolution factory method.

Add the following to your section's [xxxxx+Injection.swift file](Registration.md#files):

```swift
extension MyViewController: StoryboardResolving {
    func resolveViewController(_ resolver: Resolver) {
        self.viewModel = resolver.optional()
    }
}
```

Note that we're using `.optional()` here, since XYZViewModel is an *ImplicitlyUnwrappedOptional*.

### Step 2: Tell the Storyboard that your view controller needs to be resolved.

Go to your storyboard and add a Boolean "resolving" attribute to your view controller's Identity Inspector.

<img src="Storyboards.png">

During view controller construction the resolving attribute added by the StoryboardResolving protocol will be set.

The resolving attribute handler will then call the protocol's resolveViewController method, which in turn does whatever's needed to properly setup your view controller.

From its perspective, all of its properties just magically appear, ready and waiting to use.

## An alternative approach using Interface Injection

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

Try the two different approaches, and use the one that feels best. I tend to prefer the alternative approach, as it has fewer moving parts.

### Other Dependency Injection Systems

Some Dependency Injection systems like [SwinjectStoryboard](https://github.com/Swinject/SwinjectStoryboard) still require some variant of Step 1, but can do without Step 2.

Here's the equivalent Step 1 code in SwinjectStoryboard.

```swift
extension SwinjectStoryboard {
    class func setupMyStoryboard() {
        defaultContainer.storyboardInitCompleted(MyViewController.self) { (r, vc: MyViewController) in
            vc.viewModel = r.resolve(XYZViewModel.self)
        }
    }
}
```

As evident, there's more code involved, not to mention that SwinjectStoryboard also adds a bunch of Objective-C code to do method-swizzling on UIStoryboard in order to inject itself into the initialization process.

SwinjectStoryboard also prevents you from directly using UIStoryboard to instantiate UIViewControllers on your own, requiring you to substitue its own SwinjectStoryboard class instead.

The later clunkiness was one thing that prompted Resolver.


Resolver: Storyboards

注意：截至 Swift 5.1，我们现在可以使用属性包装器进行注入。 (查看 Annotation.)

swift
Copy code
class MyViewController: UIViewController {
    @Injected var viewModel: XYZViewModel
}
我强烈建议使用这种方法，而不是下面显示的其他方法。

属性注入

Resolver 支持使用 StoryboardResolving 协议进行自动 UIViewController 属性注入，但使用它需要两个步骤。

让我们假设以下视图控制器，它需要一个 XYZViewModel 以便正常工作。

swift
Copy code
class MyViewController: UIViewController {
    var viewModel: XYZViewModel!
}
步骤 1：添加解析工厂方法。
在您的部分的 xxxxx+Injection.swift 文件 中添加以下内容：

swift
Copy code
extension MyViewController: StoryboardResolving {
    func resolveViewController(_ resolver: Resolver) {
        self.viewModel = resolver.optional()
    }
}
请注意，这里我们使用了 .optional()，因为 XYZViewModel 是一个 ImplicitlyUnwrappedOptional。

步骤 2：告诉 Storyboard 您的视图控制器需要被解析。
转到您的 storyboard，并在 Identity Inspector 中为您的视图控制器添加一个布尔属性 "resolving"。

<img src="Storyboards.png">
在视图控制器构造过程中，StoryboardResolving 协议添加的解析属性将被设置。

然后，解析属性处理程序将调用协议的 resolveViewController 方法，该方法反过来执行任何需要适当设置您的视图控制器的操作。

从视图控制器的角度来看，所有的属性都只是神奇般地出现，随时可以使用。

另一种使用 Interface Injection 的方法

在您的部分的 xxxxx+Injection.swift 文件 中添加以下内容：

swift
Copy code
extension MyViewController: Resolving {
    func makeViewModel() -> XYZViewModel { return resolver.resolve() }
}
然后，包含在 MyViewController 中的代码变为：

swift
Copy code
class MyViewController: UIViewController {
    lazy var viewModel = makeViewModel()
}
视图控制器只知道提供了一个函数，该函数提供了它想要的视图模型。

尝试两种不同的方法，使用感觉最好的那种。我倾向于使用替代方法，因为它有更少的移动部分。

其他依赖注入系统
一些依赖注入系统（如 SwinjectStoryboard）仍然需要进行类似步骤 1 的变体，但可以省略步骤 2。

以下是 SwinjectStoryboard 中等效的步骤 1 代码。

swift
Copy code
extension SwinjectStoryboard {
    class func setupMyStoryboard() {
        defaultContainer.storyboardInitCompleted(MyViewController.self) { (r, vc: MyViewController) in
            vc.viewModel = r.resolve(XYZViewModel.self)
        }
    }
}
显然，涉及更多代码，更不用说 SwinjectStoryboard 还添加了一堆 Objective-C 代码来在 UIStoryboard 上执行方法替换，以便在初始化过程中注入自己。

SwinjectStoryboard 还阻止您直接使用 UIStoryboard 自行实例化 UIViewControllers，要求您替代其自己的 SwinjectStoryboard 类。

后来的这种笨拙性是促使 Resolver 的原因之一。
