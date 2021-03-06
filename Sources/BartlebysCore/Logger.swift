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
        return "\(self.counter.paddedString()) \(elapsedSeconds) \(Date()) \(self.category)-\(filestr.lastPathComponent).\(self.line).\(self.function): \(self.message)"
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

    // If set to true the entries will be immediately printed
    public static var printEntriesOnDebug: Bool = true

    // If set to true the entries will be relayed if possible to the sys log
    public static var relayToSysLog: Bool = true

    public static var counter: Int = 0

    public static var maxNumberOfEntries = 1_000
    
    public static var logsEntries: [LogEntry] = []
    
    public static var delegate: LoggerDelegate?

    static public func log(_ message: Any, category: LogEntry.Category = .standard, file: String = #file, function: String = #function, line: Int = #line, decorative: Bool = false) {
        syncOnMain {
            let entry: LogEntry = LogEntry()
            entry.elapsedTime = getElapsedTime()
            entry.message = "\(message)"
            entry.category = category
            entry.file = file
            entry.function = function
            entry.line = line
            entry.counter = self.counter
            entry.decorative = decorative

            while self.logsEntries.count > Logger.maxNumberOfEntries{
                let _ = self.logsEntries.removeFirst()
            }

            self.logsEntries.append(entry)

            self.delegate?.log(entry: entry)
            #if DEBUG
            if Logger.printEntriesOnDebug{
                print(entry.toString)
            }
            #endif
            self.counter += 1

            func __syslog(priority: Int32, _ message: String, _ args: CVarArg...) {
                #if os(iOS) || os(tvOS) || os(watchOS)
                    // syslog not supported
                #else
                    withVaList(args) { vsyslog(priority, message, $0) }
                #endif
            }
            if Logger.relayToSysLog{
                __syslog(priority: entry.category.syslogPriority, entry.toString)
            }
        }
    }

}

#if DEBUG
public let IS_RUNNING_IN_DEBUGGER: Bool = true
#else
public let IS_RUNNING_IN_DEBUGGER: Bool = false
#endif
