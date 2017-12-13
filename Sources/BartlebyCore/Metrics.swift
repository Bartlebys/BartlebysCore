//
//  Metrics.swift
//  Bartleby
//
// THIS FILE AS BEEN GENERATED BY BARTLEBYFLEXIONS for Benoit Pereira da Silva https://pereira-da-silva.com/contact
// DO NOT MODIFY THIS FILE YOUR MODIFICATIONS WOULD BE ERASED ON NEXT GENERATION!
//
// Copyright (c) 2016  https://bartlebys.org  All rights reserved.
//

// MARK: Bartleby's Core: a value object used to record metrics
open class Metrics:ManagedModel{

	//The action name e.g: UpdateUser
	@objc dynamic open var operationName:String = "NO_NAME"

	//The elasped time since app started up.
	@objc dynamic open var elapsed:Double = 0

	//The time interval in seconds from the time the request started to the time the request completed.
	@objc dynamic open var requestDuration:Double = 0

	// The time interval in seconds from the time the request completed to the time response serialization completed.
	@objc dynamic open var serializationDuration:Double = 0

	//The time interval in seconds from the time the request started to the time response serialization completed.
	@objc dynamic open var totalDuration:Double = 0

	//the verification method
	public enum StreamOrientation:String{
		case upStream = "upStream"
		case downStream = "downStream"
	}
	open var streamOrientation:StreamOrientation = .upStream


    // MARK: - Codable


    public enum MetricsCodingKeys: String,CodingKey{
		case operationName
		case elapsed
		case requestDuration
		case serializationDuration
		case totalDuration
		case streamOrientation
    }

    required public init(from decoder: Decoder) throws{
		try super.init(from: decoder)
        try self.quietThrowingChanges {
			let values = try decoder.container(keyedBy: MetricsCodingKeys.self)
			self.operationName = try values.decode(String.self,forKey:.operationName)
			self.elapsed = try values.decode(Double.self,forKey:.elapsed)
			self.requestDuration = try values.decode(Double.self,forKey:.requestDuration)
			self.serializationDuration = try values.decode(Double.self,forKey:.serializationDuration)
			self.totalDuration = try values.decode(Double.self,forKey:.totalDuration)
			self.streamOrientation = Metrics.StreamOrientation(rawValue: try values.decode(String.self,forKey:.streamOrientation)) ?? .upStream
        }
    }

    override open func encode(to encoder: Encoder) throws {
		try super.encode(to:encoder)
		var container = encoder.container(keyedBy: MetricsCodingKeys.self)
		try container.encode(self.operationName,forKey:.operationName)
		try container.encode(self.elapsed,forKey:.elapsed)
		try container.encode(self.requestDuration,forKey:.requestDuration)
		try container.encode(self.serializationDuration,forKey:.serializationDuration)
		try container.encode(self.totalDuration,forKey:.totalDuration)
		try container.encode(self.streamOrientation.rawValue ,forKey:.streamOrientation)
    }


    // MARK: - Initializable

    required public init() {
        super.init()
    }

    // MARK: - UniversalType

    override  open class var typeName:String{
        return "Metrics"
    }

    override  open class var collectionName:String{
        return "metrics"
    }

    override  open var d_collectionName:String{
        return Metrics.collectionName
    }
}
