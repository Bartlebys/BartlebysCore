# Modeling

Bartleby's Json Modeling was initially inspired by Swagger.
It will converge as much as possible with [JSON Schema](http://json-schema.org/example2.html). Entities definitions are essential building block of flexions. They are injected into templates and meta-template by the Flexers. Understanding Entity Modeling is important.

## BartlebysCore.flexions

- You can find Bartleby's core generated entities models in [BartlebysCore.flexions/App/descriptors/definitions](../BartlebysCore.flexions/App/descriptors/definitions/) 

The entity

```json
{
  "name": "Metrics", 
  "metadata": {},
  "definition": {
    "explicitType":"Model",
    "description": "Bartleby's Core: a value object used to record metrics",  
    ...

```

The properties

```json
    "properties": {
      "operationName":{
        "type": "string",
        "description": "The action name e.g: UpdateUser",
        "default": "$Default.NO_NAME",
        "required":true,
        "supervisable": false,
        "dynamic" : true
      },
      "elapsed":{
        "description":"The elasped time since app started up.",
        "type":"double",
        "default":0,
        "supervisable": false,
        "dynamic" : true
      },
      "requestDuration":{
        "description":"The time interval in seconds from the time the request started to the time the request completed.",
        "type":"double",
        "default":"0",
        "supervisable": false,
        "dynamic" : true
      },
      "serializationDuration":{
        "description":" The time interval in seconds from the time the request completed to the time response serialization completed.",
        "type":"double",
        "default":"0",
        "supervisable": false,
        "dynamic" : true
      },
      "totalDuration":{
        "description":"The time interval in seconds from the time the request started to the time response serialization completed.",
        "type":"double",
        "default":"0",
        "supervisable": false,
        "dynamic" : true
      }
      ,"streamOrientation": {
        "type": "enum",
        "instanceOf": "string",
        "enumPreciseType": "Metrics.StreamOrientation",
        "description": "the verification method",
        "enum": [
          "upStream",
          "downStream"
        ],
        "default": ".upStream",
        "supervisable": false,
        "dynamic" : true
      }
	...
```


# What should be the ExplicitType of my Entity?

You should use a `Model` if your entity will be owned by its Collection and referenced by the datapoint. That's the more common choice. But sometimes you may for safety prefer to adopt `CodableObject` as explicit type. 

You can create your own BaseModel that inheritate from Bartlebyscore's`Object`, `CodableObject` or `Model` . E.g: When using BartlebyKit you should often `ManagedModel` that inheritates from `Model`.


## Model

```json
{
    "name": "KeyedData",
    "definition": {
    "explicitType": "Model",
    ...
```

## CodableObject

```json
{
    "name": "DaySchedule",
    "definition": {
    "explicitType": "CodableObject",
    ...
```


# Samples


## An `Organism`

```json 
{
    "name": "Organism",
    "definition": {
        "description": "An Organism",
        "type": "Model",
        "properties": {
            "domain":{
                "description": "The biological domain ",
                "type": "enum",
                "instanceOf": "string",
                "emumPreciseType": "Organism.Domain",
                "enum": [
                    "bacteria",
                    "archaea",
                    "eukaryota"
                ],
                "mutable":false,
                "serializable":false,
                "dynamic":false
            },
            "kingdom": {
                "description": "The kingdom",
                "type": "String",
                "default":"‎animalia"
            },
            "phylum‎": {
                "description": "Its phylum",
                "type": "string",
                "default":"‎chordata"
            },
            "class": {
                "description": "Its class",
                "type": "‎mammalia"
            },
            "order‎": {
              "description": "Its Order‎",
              "type": "String"
            },
            "family": {
              "description": "Damily",
              "type": "String"
            },
            "genus": {
              "description": "Genus",
              "type": "String"
            },
            "species": {
              "description": "species ",
              "type": "String"
            },
            "extincted": {
               "description": "extincted ",
               "type": "boolean"
           }
        },
        "metadata": {
            "urdMode": false,
            "persistsLocallyOnlyInMemory": false,
            "persistsDistantly": true,
            "undoable":false,
            "groupable":true
        }
    }
}

```


## Entities Metadata 

The metadata model is extensible.

```json
	 "metadata": {
        "urdMode": false,
        "persistsLocallyOnlyInMemory": false,
        "persistsDistantly": false,
        "undoable":false,
        "groupable":true
    }
```
            

### Currently used keys:

+ urdMode (to specify to the generator if it should generate  a URD or CRUD stack. It can be used in templates by calling ```$entityRepresentation->usesUrdMode()```
+ persistsLocallyOnlyInMemory ( is saved locally?)
+ persistsDistantly (create a CRUD stack)
+ undoable  ( undo manager support )
+ groupable (groupable on auto commit)



# Properties 

## dynamic 
mark as dynamic 

## serializable

In this case we don't want the property proxy to serialized

```json
  "proxy": {
      "explicitType": "ManagedObject",
       "description": "",
        "dynamic": false,
         "serializable":false
  },
```


## supervisable

If a property is marked as supervisable any change will mark its parent as changed.

```json
"fruit": {
    ...
    "supervisable":false
},
```

## codingKey

Defines if a property should be serialized using a key that diverges from its name

```json
	"property": {
	    ...
	    "codingKey":"serialized_property_name"
	},
```


## cryptable

If a property is marked as cryptable on serialization it should be crypted.

```json
	"password": {
	    ...
	    "cryptable":true
	},
```

## Properties explicitType 

You can specify an explicit type (that is not necessarly generated) by specifying the type "object".

```json
 "Card": {
	"description": "The associatedCard",
    "type": "object",
    "explicitType":"Card"
},
```

## Properties dictionaries

You can use the **dictionary** type, for parameters & properties

```json
	"parameters":[
		{
			"in": "body",
			"name": "sort",
			"description": "the sort (MONGO DB)",
			"required": true,
			"type": "dictionary"
		}
	]
```

# Tip and Tricks 

You can add **default native functions** if your generated targets can afford it!


### native functions

```json
      "startDate": {
         "type": "date",
       	"definition": "the starting date",
          "default": "NSDate()"
	}             
```
