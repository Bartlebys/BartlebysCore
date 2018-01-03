//
//  Logger.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

public struct LogEntry : CustomStringConvertible {
    
    var elapsedTime: Double = 0
    var message: Any
    var category: Logger.Categories = .standard
    var file: String
    var function: String
    var line: Int
    var counter: Int
    
    public var description: String {
        let filestr: NSString = file as NSString
        return "\(self.counter.paddedString()) \(self.category.rawValue)-\(filestr.lastPathComponent).\(self.line).\(self.function): \(self.message)"
    }
    
}

public struct Logger {
    
    static var counter: Int = 0
    
    static var printable: [Categories] = [.standard, .temporary, .critical]
    
    public static var logsEntries: [LogEntry] = []
    
    public enum Categories : String {
        case standard = "std"
        case critical // E.g: Code section that that should never be reached
        case temporary
    }
    
    static public func log(_ message: Any, category: Categories = .standard, file: String = #file, function: String = #function, line: Int = #line) {
        
        guard Logger.printable.contains(category) else {
            return
        }
        
        let entry: LogEntry = LogEntry(elapsedTime: getElapsedTime(), message: message, category: category, file: file, function: function, line: line, counter: self.counter)
        
        logsEntries.append(entry)
        print(entry.description)
        
        self.counter += 1
    }
    
}
