# Datapoints

# CallOperation

- CallOperations are serializable reusable HTTP calls.
- CallOperations are *grouped* by CallSequences

## How to execute a CallOperation

Use: 

```swift
operation.execute()
```
Or Invoke on the datapoint.session 

```swift
func execute<P, R>(_ operation: CallOperation<P, R>)
```

**Do not use `datapoint.session.runCall<P, R>` or `operation.runIfProvisioned()`** directly 



# CallSequences

Each call sequence runs in parallel. By default we add :

- data
- downloads
- uploads

But you can easily create your own Call Sequence.


You can configure a call Sequence by calling `upsertCallSequence(...)` generally during the preparation phase. E.g:

```swift
self.upsertCallSequence(CallSequence(name: CallSequence.downloads, bunchSize: 5))
```

By setting the *downloads* bunch size to `5` you allow to run download call operations by bunch of `5`. The call order will be preserved (with no guarantee of the result order)

By default the bunchsize are set to `1` making Operation running sequentially if you use the `datapoint.session.executeLater` method.
 