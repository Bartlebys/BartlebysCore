//
//  OperationsNotifications.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public extension NSNotification.Name {

    public struct ObjectCollection {
        
        public static func saveDidSucceed(_ collectionName: String ) -> (Notification.Name) {
            return Notification.Name(rawValue: "org.barlebys.\(collectionName).didSucceed")
        }

    }
    
    public struct Operation {

        public static func didSucceed(_ operationName:String ) -> (Notification.Name) {
            return Notification.Name(rawValue: "org.barlebys.\(operationName).didSucceed")
        }

        public static func didFail(_ operationName:String ) -> (Notification.Name) {
            return Notification.Name(rawValue: "org.barlebys.\(operationName).didFail")
        }
    }
    
}
