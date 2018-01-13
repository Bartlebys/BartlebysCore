
[![Swift 4](https://img.shields.io/badge/Swift-4.0-orange.svg)](https://swift.org)  [![Platform](https://img.shields.io/badge/platforms-macOS%20∙%20iOS%20∙%20watchOS%20∙%20tvOS∙%20Linux-blue.svg)](https://developer.apple.com/platforms/) 

# What is BartlebysCore?


BarlebysCore is a small framework written in Swift4 available for macOS, iOS, tvOS et Linux, that allows to : 

1. Load and save Generic Collection of Swift 4 Codable Objects.
2. Create serializable reusable HTTP Operation 
3. Proposes efficient ways to deal with [Object Relations](https://github.com/Bartlebys/BartlebysCore/blob/master/Documents/RelationsBetweenModels.md)

BartlebysCore's goal is to keep things simples and "Swifty" by Design.
**BartlebysCore** is the core Engine of [**BartlebyKit**](https://github.com/Bartlebys/BartlebyKit) but it suitable for various usages.

# DataPoint

The objects are stored in DataPoint that: 

1. references the collections 
2. allow aliases, and relations resolution
3. deals with RestFull HTTP operations (on & Off Line)

## How to instantiate a `Model`?

You can instantiate a Model using a factory method

```
// Syntax #1
let metrics1:Metrics = dataPoint.newInstance()

// Syntax #2
let metrics2 = dataPoint.newInstance() as Metrics

// Syntax #3
let metrics3 = dataPoint.new(type: Metrics.self)
```

Or instantiating an Object and appending it to its collection.

```
// Decomposed approach 
let metrics4 = Metrics()
dataPoint.metrics.append(metrics4)
```

# How to implement your own Model?

1. You can create a Class that Inheritates from [Model.swift](https://github.com/Bartlebys/BartlebysCore/blob/master/Sources/BartlebysCore/Model.swift) and implement `Codable & Collectable & Tolerent` protocols.
2. Or You Can generate Model from JSON schema / Swagger / OpenApi / CoreData Models using [Flexions](https://github.com/Bartlebys/BartlebysCore/tree/master/BartlebysCore.flexions) (Detailed explanations to come soon)

- BartlebysCore Models are standard Swift instance.
- The Collections are generic.

# Integration

## Using the swift Package manager

```swift build```


## Linking BartlebysCore as a Submodule

*Complete instruction are coming soon*
### 1. as an external target
### 2. integrated to your own sources (higher performance)




# Documents

- How to deal with Relations between Entities? BartlebysCore's approaches are described in [RelationsBetweenModels.md](Documents/RelationsBetweenModels.md)
