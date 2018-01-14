//
//  Selection.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


public protocol Selection {

    associatedtype T : Collectable, Codable

    // The currently selected items
    var selectedItems:[T]?{ get set }

    // A facility to access to the first selected item
    var firstSelectedItem:T? { get }
}
