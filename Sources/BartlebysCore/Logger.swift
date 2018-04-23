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
    open var toString: String {
        let filestr: NSString = NSString(string: self.file)
        let elapsedSeconds = Int(self.elapsedTime).paddedString(8)
        return "\(self.counter.paddedString()) \(elapsedSeconds) \(self.category)-\(filestr.lastPathComponent).\(self.line).\(self.function): \(self.message)"
    }

}

extension LogEntry.Category{

    public var syslogPriority:Int32 {
        switch self {
        case .critical:
            return LOG_CRIT
        case .warning :
            return LOG_WARNING
        case .temporary:
            return LOG_DEBUG
        default:
            return LOG_INFO
        }
    }

}


public protocol LoggerDelegate {
    func log(entry: LogEntry)
}

public struct Logger {
    
    static var counter: Int = 0

    static var maxNumberOfEntries = 1_000
    
    public static var logsEntries: [LogEntry] = []
    
    public static var delegate: LoggerDelegate?

    
    static public func log(_ message: Any, category: LogEntry.Category){
        self.log(message, category: category, decorative: false)
    }

    static public func log(_ message: Any, category: LogEntry.Category = .standard, file: String = #file, function: String = #function, line: Int = #line,decorative:Bool = false) {
        DispatchQueue.main.async{
            let entry: LogEntry = LogEntry()
            entry.elapsedTime = getElapsedTime()
            entry.message = "\(message)"
            entry.category = category
            entry.file = file
            entry.function = function
            entry.line = line
            entry.counter = counter
            entry.decorative = decorative

            while self.logsEntries.count > Logger.maxNumberOfEntries{
                let _ = self.logsEntries.removeFirst()
            }

            self.logsEntries.append(entry)

            if let delegate = self.delegate {
                delegate.log(entry: entry)
            }

            self.counter += 1

            func __syslog(priority : Int32, _ message : String, _ args : CVarArg...) {
                #if os(iOS) || os(tvOS) || os(watchOS)
                    // syslog not supported
                #else
                    withVaList(args) { vsyslog(priority, message, $0) }
                #endif
            }
            __syslog(priority: entry.category.syslogPriority, entry.toString)
        }


    }

}
