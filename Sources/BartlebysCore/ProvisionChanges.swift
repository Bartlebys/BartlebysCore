//
//  ProvisionChanges.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public protocol ProvisionChanges {

    /**
     Tags the changed keys
     And Mark that the instance requires to be committed if the auto commit observer is active
     This mechanism can replace KVO if necessary.

     - parameter key:      the key
     - parameter oldValue: the oldValue
     - parameter newValue: the newValue
     */
    func provisionChanges(forKey key:String,oldValue:Any?,newValue:Any?)


    /// Performs the deserialization without invoking provisionChanges
    ///
    /// - parameter changes: the changes closure
    func quietChanges(_  changes:()->())


    /// Performs the deserialization without invoking provisionChanges
    ///
    /// - parameter changes: the changes closure
    func quietThrowingChanges(_ changes:()throws->())rethrows

}
