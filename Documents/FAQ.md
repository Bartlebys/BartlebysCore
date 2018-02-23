# How to instantiate a Model?

You can instantiate and register a Model using the DataPoint factory method

```swift
// Syntax #1
let metrics1:Metrics = dataPoint.newInstance()

// Syntax #2
let metrics2 = dataPoint.newInstance() as Metrics

// Syntax #3
let metrics3 = dataPoint.new(type: Metrics.self)
```

Or instantiating an Object and appending it to its collection.

```swift
// Decomposed approach
let metrics4 = Metrics()
dataPoint.metrics.append(metrics4)
```

# Does Bartleby's Core support CocoaBindings?

**YES** on macOS but you need to opt in by adding in other swift flag `-DUSE_COCOA_BINDINGS` in build settings.

*Flexions* generates by default a `Dynamic` and a `Common` model and choose at compile time witch to use, you should always use the `TypeAlias`.

Let's imagine you have an Entity named `MyModel`:

```swift
// Created by flexions during generation
#if os(macOS) && USE_COCOA_BINDINGS
public typealias MyModel = DynamicMyModel
#else
public typealias MyModel = CommonMyModel
#endif
```
