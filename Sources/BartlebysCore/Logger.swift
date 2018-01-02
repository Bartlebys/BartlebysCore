//
//  Logger.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public struct Logger {
    
    static var counter: Int = 0
    
    static var printable: [Categories] = [.standard, .temporary, .critical]
    
    public enum Categories : String {
        case standard = "std"
        case critical // E.g: Code section that that should never be reached
        case temporary
    }
    
    static public func log(_ message: Any, category: Categories = .standard, file: String = #file, function: String = #function, line: Int = #line) {
        
        guard Logger.printable.contains(category) else {
            return
        }
        
        let filestr: NSString = file as NSString
        print("\(counter.paddedString()) \(category.rawValue)-\(filestr.lastPathComponent)(\(line).\(function): \(message)")
        
        self.counter += 1
    }
    

    
}
