//
//  Int+Padding.swift
//  BartlebyCore
//
//  Created by Laurent Morvillier on 20/11/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

public extension Int {
    
    public func paddedString(_ numberOfDigits: Int = 4) -> String {
        let digitFormat = String(format: "%i", numberOfDigits)
        return String(format: "%0\(digitFormat)d", self)
    }
    
    
}
