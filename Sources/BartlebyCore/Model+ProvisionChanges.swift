//
//  ManagedModel+ProvisionChanges.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 13/11/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation


extension Model:ProvisionChanges{

    open func provisionChanges(forKey key:String,oldValue:Any?,newValue:Any?){
    }

    public var wantsQuietChanges:Bool{
        return self._quietChanges
    }


    /// Performs the deserialization without invoking provisionChanges
    ///
    /// - parameter changes: the changes closure
    public func quietChanges(_  changes:()->()){
        self._quietChanges=true
        changes()
        self._quietChanges=false
    }


    /// Performs the deserialization without invoking provisionChanges
    ///
    /// - parameter changes: the changes closure
    public func quietThrowingChanges(_ changes:()throws->())rethrows{
        self._quietChanges=true
        try changes()
        self._quietChanges=false
    }
    
}

