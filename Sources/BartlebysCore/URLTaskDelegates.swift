//
//  Dat.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 08/08/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation


// A bunch of wrapper to support Progress while using closures on Download / Upload tasks.
// This implementation tries to fill the gap with the current implementation
// With retro compatibility support. @Todo (Work in progress)
//
// DownloadDelegate Usage sample :
//
//  let request = URLRequest(url: downloadURL)
//  let configuration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "your ID")
//  let taskDelegate: DownloadDelegate = DownloadDelegate.init(progression: { (progress) in
//      // Handle the progress
//  }, completion: { (url, response, error) in
//      // Handle the completion
//  })
//
//  let session: URLSession = URLSession.init(configuration: configuration, delegate: taskDelegate, delegateQueue: OperationQueue.main)
//  let downloadTask: URLSessionDownloadTask  = session.downloadTask(with: request)
//  downloadTask.resume()
//
open class TaskDelegate: NSObject, URLSessionDelegate{

    public fileprivate(set) var taskProgress: Progress = Progress(totalUnitCount: 0)

    /// The progression closure
    fileprivate var _onProgression:(Progress)->()

    public init(progression: @escaping(Progress)->()){
        self._onProgression = progression
        super.init()
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {}

}


// MARK: -  DownloadDelegate

public enum DownloadDelegateError:Error{
    case typeMissmatch
}



open class DownloadDelegate: TaskDelegate, URLSessionDownloadDelegate{


    fileprivate var _onCompletion: (URL?, URLResponse?, Error?)->()


    /// The designated constructor
    ///
    /// - Parameters:
    ///   - progression: the progression closure
    ///   - completion: the completion closure
    ///         - temporaryURL: When a download successfully completes, the NSURL will point to a file that must be read or copied during the invocation of the completion routine.  The file will be removed automatically.
    ///         - response: the response
    ///          - error: the error
    public init(progression: @escaping(Progress)->(), completion: @escaping (URL?, URLResponse?, Error?)->() ){
        self._onCompletion = completion
        super.init(progression: progression)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL){
        self._onCompletion(location,downloadTask.response,downloadTask.error)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64){
        self.taskProgress.totalUnitCount = totalBytesExpectedToWrite
        self.taskProgress.completedUnitCount = totalBytesWritten
        self._onProgression(self.taskProgress)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64){
        self.taskProgress.totalUnitCount = expectedTotalBytes
        self.taskProgress.completedUnitCount = fileOffset
        self._onProgression(self.taskProgress)
    }

}


// MARK: -  UploadDelegate

public enum UploadDelegateError:Error{
    case typeMissmatch
}

// @todo
open class UploadDelegate: TaskDelegate, URLSessionTaskDelegate{


   // ileprivate var _onCompletion:

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64){
        self.taskProgress.totalUnitCount = totalBytesExpectedToSend
        self.taskProgress.completedUnitCount = bytesSent
        self._onProgression(self.taskProgress)
    }


}


