
# Basics

## How to instantiate a model?

You can instantiate a Model using a factory method

```
let metrics1:Metrics = dataPoint.newInstance()
let metrics2 = dataPoint.newInstance() as Metrics
let metrics3 = dataPoint.new(type: Metrics.self)
```

Or instantiating an Object and appending it to its collection.

```
let metrics4 = Metrics()
dataPoint.metrics.append(metrics4)
```