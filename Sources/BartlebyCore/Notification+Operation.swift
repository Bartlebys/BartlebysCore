//
//  OperationsNotifications.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public extension NSNotification.Name {

    public struct Operation {

        public static func didSucceed(_ operationName:String ) -> (Notification.Name){
            return Notification.Name(rawValue: "com.music-work.\(operationName).didSucceed")
        }

        public static func didFail(_ operationName:String ) -> (Notification.Name){
            return Notification.Name(rawValue: "com.music-work.\(operationName).didFail")
        }
    }
    
}
