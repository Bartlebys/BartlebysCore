//
//  Int+Padding.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public extension Int {
    
    public func paddedString(_ numberOfDigits: Int = 4) -> String {
        let digitFormat = String(format: "%i", numberOfDigits)
        return String(format: "%0\(digitFormat)d", self)
    }
    
}
