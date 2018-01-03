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
        let elapsedSeconds = Int(self.elapsedTime).paddedString(8)
        return "\(self.counter.paddedString()) \(elapsedSeconds) \(self.category.rawValue)-\(filestr.lastPathComponent).\(self.line).\(self.function): \(self.message)"
    }
    
}

public protocol LoggerDelegate {
    func log(entry: LogEntry)
}

public struct Logger {
    
    static var counter: Int = 0
    
    static var printable: [Categories] = [.standard, .temporary, .critical]
    
    public static var logsEntries: [LogEntry] = []
    
    static var delegate: LoggerDelegate?

    public enum Categories : String {
        case standard = "std"
        case critical // E.g: Code section that that should never be reached
        case temporary
    }
    
    static public func log(_ message: Any, category: Categories = .standard, file: String = #file, function: String = #function, line: Int = #line) {
        
        let entry: LogEntry = LogEntry(elapsedTime: getElapsedTime(), message: message, category: category, file: file, function: function, line: line, counter: self.counter)
        logsEntries.append(entry)

        if let delegate = self.delegate {
            delegate.log(entry: entry)
        }
        
        self.counter += 1
    }
    
}
