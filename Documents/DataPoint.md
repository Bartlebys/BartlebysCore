# What is a Datapoint ?


1. references, load and saves collections of Models.
2. allow aliases, and relations resolution.
3. deals with online and offline HTTP operations

A Datapoint is equivalent to a Document.

A `Datapoint` can use volatile storage to persist in memory only, or by default relies on a File Storage that handles efficiently persistency.

[DataPoint.swift](https://github.com/Bartlebys/BartlebysCore/blob/master/Sources/BartlebysCore/DataPoint.swift):

# What is a CallOperation ?

- CallOperations are serializable reusable HTTP calls.
- CallOperations are *grouped* by CallSequences 
- CallOperations are executed by their parent DataPoint.

## How to execute a CallOperation?

Use: 

```swift
operation.execute()
```

It will Invoke the datapoint's execution method.

```swift
func execute<P, R>(_ operation: CallOperation<P, R>)
```

## CallOperations are segmented by CallSequences

Each call sequence runs in parallel. By default Bartleby's core creates 3 call sequences :

- data
- downloads
- uploads

### You can easily create your own Call Sequence.


1. You just need configure a call Sequence by calling `upsertCallSequence(...)` generally during the preparation phase. E.g: ` self.upsertCallSequence(CallSequence(name: CallSequence.history, bunchSize: 1))`

2. and to declare the call sequence name of your operation on creation `operation.sequenceName = CallSequence.history` 


By setting the *downloads* bunch size to `5` you allow to run history call operations by bunch of `5`. 

#### Notes:

- By default the bunchsize are set to `1` making Operation running sequentially.
- if the bunchsize > 1  The call order will be preserved (with no guarantee of the result order)
 

## How to Debug a CallOperation execution?

You cannot easily know when to log or put a break point because the execution policy is determined by the DataPoint. The simplest solution is to add a debugHandler:


Let's imagine we are executing an operation that gets resorts.
	
```swift
	 
	let getResorts:CallOperation<VoidPayload, Resort> = ... 
	getResorts.debugHandler = { operation, response, error in

        if let error = error{
            // Analyze the error
            print(error)
        }

        // Inspect the operation
        print(operation.uid)

        if let response = response{

            // Access to the fully Typed result
            if let response = response as? DataResponse<Resort>{
                if let firstResort = response.result.first{
                    print("First resort: \(firstResort)\n")
                }
            }

            // use response.prettyJSON or response.rawString
            if let contentPrettyJSON = response.prettyJSON{
                print(contentPrettyJSON)
            }

            if let metrics = response.metrics{
                // You can check the metrics.
                print(metrics)
            }
            
        }

	}
	getResorts.execute()
```

### Notes :

- the handler is called on live execution and not when runing from a Serialized state.
- you can put a breakpoint in the operation.debugHandler.
