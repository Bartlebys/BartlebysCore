//
//  ManagedModel+Commitable.swift
//  BartlebysCore macOS
//
//  Created by Benoit Pereira da silva on 02/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


extension ManagedModel:Committable{

    // MARK: Commit

    // You can in specific situation mark that an instance should be committed by calling this method.
    // For example after a bunch of un supervised changes.
    open func needsToBeCommitted(){
        try? self.parentCollection?.stage(self)
    }

    // Marks the entity as committed and increments it provisionning counter
    open func hasBeenCommitted(){
        self.commitCounter += 1
    }


    // MARK: Changes

    /// Perform changes without commit
    ///
    /// - parameter changes: the changes
    open func doNotCommit(_ changes:()->()){
        let autoCommitIsEnabled = self._autoCommitIsEnabled
        self._autoCommitIsEnabled=false
        changes()
        self._autoCommitIsEnabled = autoCommitIsEnabled
    }


}
