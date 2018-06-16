# Relations between Models

`BartlebysCore` proposes two approaches to deal with Relations between entities: 

- Aliases 
- Relationships

Both methods enable fast runtime resolution. 

## 1. Aliases

Aliases have been designed to enable to simply link references. 

### Characteristics:

- Aliases are flexible: 
	- [AliasOf](../Sources/BartlebysCore/AliasOf.swift) is generic
	- [Alias](../Sources/BartlebysCore/Alias.swift)' type is erased
- They are not dynamic, they are defined at modeling & compile time
- They do not implement automatic cascading erasing logic

### AliasResolution

[AliasesResolution.swift](../Sources/BartlebysCore/AliasesResolution.swift) expose resolution API implemented in [Model+AliasesResolution.swift](../Sources/BartlebysCore/Model+AliasesResolution.swift).

- Resolution may be strict while using `func instance<T : Codable >(from alias:Aliased) throws -> T`
- or permissive when using optional approaches `func optionalInstance<T : Codable >(from alias:Aliased) -> T?`

## 2. Relationships

Relationships has been designed for Distributed Collaborative applications.

### Characteristics:

- Relationships are Dynamic (they are defined at runtime and persists)
- They resist to concurential pressure, while preserving consistency. `EntityA` can own hundreds of Entities `[B]` and multiple agents can asynchronously add and remove Relationships
- They implements a predictible cascading erasing logic
- They do support `1-1` `1-N` `N-1` `N-N`

### There are three types of relationships :

1. "owns": A owns B
2. "ownedBy": B is owned by A
3. "free": C is freely related to D 


```Swift
public enum Relationship:String{

    /// Serialized into the Object
    case free = "free"
    case ownedBy = "ownedBy"

    /// "owns" is Computed at runtime during registration to determine the the Subject
    /// Ownership is computed asynchronously for better resilience to distributed pressure
    case owns = "owns"

}
```

### RelationsResolution

[RelationsResolution.swift](../Sources/BartlebysCore/RelationsResolution.swift) expose a rich dynamic resolution API implemented in [Model+RelationsResolution.swift](../Sources/BartlebysCore/Model+RelationsResolution.swift)



### Erasure rules

When a piece of code call `erase()` on a Model it is deleted (and it owners relationships are cleaned) 

#### Erasure Cascading rules

`if A owns B that owns C, deleting A would delete B and C.`

1. When an owner is deleted all its owned entities are erased (if no other co-owner is alive)
2. When an owned entity is deleted its owner survives.
3. When two entities are freely related deletion of one has no impact on this other.


#### CleanUp "procedures"

You can override `DataPoint.willErase` method to cleanup external dependencies on erasure e.g: files associated with an entity, BartlebyKit.BSFS

### Notes
- Check: [Model+Erasure](../Sources/BartlebysCore/Model+Erasure.swift) for implementation details.
- Each object has a unique creator. It can give ACL privileges in Children Framework like `BartlebyKit` but is not related to Bartleby Relationships mechanism!
