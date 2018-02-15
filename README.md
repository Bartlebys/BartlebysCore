
[![Swift 4](https://img.shields.io/badge/Swift-4.0-orange.svg)](https://swift.org)  [![Platform](https://img.shields.io/badge/platforms-macOS%20∙%20iOS%20∙%20watchOS%20∙%20tvOS∙%20Linux-blue.svg)](https://developer.apple.com/platforms/) 


# What is Bartleby's Core?

BarlebysCore is a framework written in Swift4, available for macOS, iOS, tvOS et Linux, that allows to :

1. Insure the persistency Objects Collection, and `FilePersistent` Objects.
2. Create serializable HTTP Operation (with off line support)
3. Deal efficiently with runtime [Object Relations resolution](https://github.com/Bartlebys/BartlebysCore/blob/master/Documents/RelationsBetweenModels.md)

BartlebysCore's goal is to keep things simples and "Swifty" by Design.
**BartlebysCore** is the core Engine of [**BartlebyKit**](https://github.com/Bartlebys/BartlebyKit) but is suitable for various usages.

If your data can be totally loaded in Memory, Bartleby's Core is probably a good solution for your App. It will allow to use simple functional programming approach to manipulate your data synchronously very efficiently, and integrate easily with your RESTFul API.


# Installation

You can use the Swift Package Manager, a git submodule, or Carthage to install **BartlebysCore Framework**.
You can clone [BartlebyKit](https://github.com/BartlebyBartlebyKit) and run `./install.sh`. It will synchronise update the submodules a offer a configured workspace.

## Using the swift Package manager

You can check the [SPM sample](https://github.com/Bartlebys/SPMCoreSample) **CURRENTLY A USELESS PLACEHOLDER**


## Linking BartlebysCore as a Submodule in Xcode

You need to create a workspace with

### 1. as an external target

1. You create submodules in a repository `git submodule add -b master https://github.com/Bartlebys/BartlebysCore` 
2. Drop the `BartlebysCore/Projects/BartlebysCore/BartlebysCore.xcodeproj` file in your Xcode workspace
3. Add `BartlebysCore.framework` as Linked Frameworks and libraries from the target general Tab.

### 2. integrated to your sources

This approach may improve performance and can be suitable is you want to aggregate all the sources.

1. You create submodules in a repository `git submodule add -b master https://github.com/Bartlebys/BartlebysCore` 
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
github "Bartlebys/BartlebysCore"
```

# Documents

- DataPoint? [ DataPoint](Documents/DataPoint.md)
- How to deal with Relations between Entities? [RelationsBetweenModels.md](Documents/RelationsBetweenModels.md)
- [FAQ](Documents/FAQ.md)

![Bartleby's](Documents/assets/bartlebys.jpg)


# Bartleby's Core License

Bartleby's stack is Licensed under the [Apache License version 2.0](LICENSE)
By [Benoit Pereira da Silva] (https://Pereira-da-Silva.com)


