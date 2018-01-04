//
//  Logger.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 06/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

extension LogEntry{

    /// Text Formatted log description
    open override var description: String {
        let filestr: NSString = file as NSString
        let elapsedSeconds = Int(self.elapsedTime).paddedString(8)
        return "\(self.counter.paddedString()) \(elapsedSeconds) \(self.category)-\(filestr.lastPathComponent).\(self.line).\(self.function): \(self.message)"
    }
}


public protocol LoggerDelegate {
    func log(entry: LogEntry)
}

public struct Logger {
    
    static var counter: Int = 0
    
    public static var logsEntries: [LogEntry] = []
    
    public static var delegate: LoggerDelegate?

    static public func log(_ message: String, category: LogEntry.Category = .standard, file: String = #file, function: String = #function, line: Int = #line) {
        
        let entry: LogEntry = LogEntry()
        entry.elapsedTime = getElapsedTime()
        entry.message = message
        entry.category = category
        entry.file = file
        entry.function = function
        entry.line = line
        entry.counter = counter

        logsEntries.append(entry)

        if let delegate = self.delegate {
            delegate.log(entry: entry)
        }
        
        self.counter += 1
    }
    
}
