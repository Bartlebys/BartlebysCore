# Datapoints

# CallOperation

- CallOperations are serializable reusable HTTP calls.
- CallOperations are *grouped* by CallSequences

## How to execute a CallOperation

Use: 

```swift
operation.execute()
```
Or Invoke on the datapoint

```swift
func execute<P, R>(_ operation: CallOperation<P, R>)
```

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

By default the bunchsize are set to `1` making Operation running sequentially.
 

# Debugging calls

You cannot easily know when to log or put a break point because the execution policy is determined by the DataPoint.The simplest solution is to add a debugHandler:


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
