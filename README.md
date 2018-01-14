
[![Swift 4](https://img.shields.io/badge/Swift-4.0-orange.svg)](https://swift.org)  [![Platform](https://img.shields.io/badge/platforms-macOS%20∙%20iOS%20∙%20watchOS%20∙%20tvOS∙%20Linux-blue.svg)](https://developer.apple.com/platforms/) ![](https://travis-ci.org/Bartlebys/BartlebysCore.svg?branch=master)


# What is Bartleby's Core?

BarlebysCore is a framework written in Swift4, available for macOS, iOS, tvOS et Linux, that allows to : 

1. insure the persistency Generic Collection of Swift 4 Objects.
2. create serializable reusable HTTP Operation 
3. deal efficiently with runtime [Object Relations resolution](https://github.com/Bartlebys/BartlebysCore/blob/master/Documents/RelationsBetweenModels.md)

BartlebysCore's goal is to keep things simples and "Swifty" by Design.
**BartlebysCore** is the core Engine of [**BartlebyKit**](https://github.com/Bartlebys/BartlebyKit) but is suitable for various usages.

If your data can be totally loaded in Memory, Bartleby's Core is probably a good solution for your App. It will allow to use simple functional programming approach to manipulate your data synchronously very efficiently, and integrate easily with your RESTFul API.

# Installation

You can use the Swift Package Manager, a git submodule, or Carthage to install BartlbysCore Framework.

## Using the swift Package manager

You can check the [SPM sample](https://github.com/Bartlebys/SPMCoreSample)


## Linking BartlebysCore as a Submodule in Xcode


### 1. as an external target

1. You create a submodule in a repository `git submodule add -b master https://github.com/Bartlebys/BartlebysCore`
2. Drop the `BartlebysCore/Projects/BartlebysCore/BartlebysCore.xcodeproj` file in your Xcode workspace
3. Add `BartlebysCore.framework` as Linked Frameworks and libraries from the target general Tab. 
 
### 2. integrated to your sources

This approach may improve performance and can be suitable is you want to aggregate all the sources.

1. You create a submodule in a repository `git submodule add -b master https://github.com/Bartlebys/BartlebysCore`
2. Drop the source into your Workspace directly.
3. You should add `-DUSE_EMBEDDED_MODULES` in the target Build Settings tab > Other swift flags. 


If you want to use mixed approach you should import BartlebysCore as :

```swift
#if !USE_EMBEDDED_MODULES
    import BartlebysCore
#endif   
```

## You can also use Carthage.

Add in your Cartfile:

```
github "Bartlebys/BartlebysCore/"
```

# DataPoint

The objects are stored in a [DataPoint](https://github.com/Bartlebys/BartlebysCore/blob/master/Sources/BartlebysCore/DataPoint.swift) that: 

1. references, load and saves the collections.
2. allow aliases, and relations resolution.
3. deals with RestFull HTTP operations (on & Off Line).

A Datapoint is equivalent to a Document that holds a consistent Data Graph.

A `Datapoint` can use volatile storage to persist in memory only, or by default relies on a File Storage that handles efficiently persistency.


# How to implement your own Model?

1. You can create a Class that Inheritates from [Model.swift](https://github.com/Bartlebys/BartlebysCore/blob/master/Sources/BartlebysCore/Model.swift) override `Codable`, override bunch of the `Collectable` and implement the  `Tolerent` patch method.
2. Or You Can generate Model from JSON schema / Swagger / OpenApi / CoreData Models using [Flexions](https://github.com/Bartlebys/BartlebysCore/tree/master/BartlebysCore.flexions) (Detailed explanations on the generative tools to come soon)


In fact, Bartleby's Core Models are standard Swift instances, and their Collections are generic. Working with in memory Object Graph insures efficient real time computation. 

## How to instantiate a Model?

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


# Documents

- How to deal with Relations between Entities? BartlebysCore's approaches are described in [RelationsBetweenModels.md](Documents/RelationsBetweenModels.md)

![Bartleby's](Documents/bartlebys.jpg)


# Bartleby's Core License

Bartleby's stack is Licensed under the [Apache License version 2.0](LICENSE)
By [Benoit Pereira da Silva] (https://Pereira-da-Silva.com) 


