//
//  SequenceOfTasks.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 20/04/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// You can use a sequenece of tasks

public enum TaskCompletionState{
    case success
    case failure(withError:Error)
    case cancelled
}

public enum TaskCompletionError:Error{
    case unexistingIndex
    case undefined
    case message(message:String)
}

/// We use a class an passes the items by references.
public class SequenceOfTasks<T:Any> {

    /// The associated items list
    fileprivate var _items: [T]

    /// The current index
    public fileprivate(set) var index:Int = 0

    // The delay between to tasks.
    // If set to 0 we do not use GCD
    // Else we dispatch Async on the execution queue.
    fileprivate var _delay: TimeInterval

    /// The execution queue
    public var queue:DispatchQueue = DispatchQueue.main

    /// If set to true the sequence will be cancelled on the first failure
    public var cancelOnFailure:Bool = false

    /// Should the task be executed automatically?
    /// If not you can call
    public var chainTheTasksAutomatically: Bool = true

    public fileprivate(set) var states:[TaskCompletionState] = [TaskCompletionState]()

    public fileprivate(set) var taskHandler:(_ item: inout T,_ index:Int, _ sequence: SequenceOfTasks<T> ) -> (TaskCompletionState)

    public fileprivate(set) var onCompletion:((_ success:Bool)->())


    /// The designated constructor.
    ///
    /// - Parameters:
    ///   - items: the items to be sequentially processed
    ///   - taskHandler: the handler that is called on each item
    ///   - onCompletion: the completion handler
    ///   - delayBetweenTasks: the execution delay between two tasks.
    public init( items: inout [T],
                 taskHandler:@escaping(_ item: inout T, _ index: Int, _ sequence: SequenceOfTasks<T>) -> (TaskCompletionState),
                 onCompletion:@escaping(_ success: Bool) -> () ,
                 delayBetweenTasks: TimeInterval = 0) {
        self._items = items
        self.taskHandler = taskHandler
        self.onCompletion = onCompletion
        self._delay = delayBetweenTasks
    }



    /// Starts the sequence
    public func start(){
        if self._items.count > 0{
            let _ = self._runTask(at: 0)
        }else{
            self._endOfTheSequence()
        }
    }


    /// Cancels the sequence will trigger a non successful completion.
    public func cancel(){
        while self.index < self._items.count{
            self.index += 1
            self.states.append(TaskCompletionState.cancelled)
        }
        self.onCompletion(false)
    }



    /// Runs the discreet task at a given index and stores its completion state.
    ///
    /// - Parameter index: the index.
    fileprivate func _runTask(at index:Int){
        if index == self._items.count{
            self._endOfTheSequence()
        }else{

            let taskState: TaskCompletionState

            if index < self._items.count {
                taskState = self.taskHandler(&self._items[index],index, self)
            }else{
                // can occur on external mutation of the referenced items list.
                taskState = .failure(withError: TaskCompletionError.unexistingIndex)
            }

            self.states.append(taskState)
            switch taskState{
            case .success,.cancelled:
                break
            case .failure(withError:_):
                // Should we cancel?
                if self.cancelOnFailure{
                    self.cancel()
                    return
                }
            }
            if self.chainTheTasksAutomatically{
                if self._delay == 0 {
                    let _ = self.runNextTask()
                }else{
                    let delayInNanoS =  UInt64(self._delay * 1_000_000_000)
                    let deadLine = DispatchTime.init(uptimeNanoseconds:delayInNanoS)
                    self.queue.asyncAfter(deadline: deadLine) {
                        let _ = self.runNextTask()
                    }
                }
            }
        }
    }


    /// Runs the next task.
    /// - Returns: true if there was a task.
    public func runNextTask() -> Bool{
        self.index += 1
        self._runTask(at: self.index)
        return self.index < self._items .count
    }


    /// Called to conclude the sequence.
    fileprivate func _endOfTheSequence(){
        if let state = self.states.first{
            switch state{
            case .success:
                var isConsistent = true
                for s in self.states{
                    switch s{
                    case .failure(_):
                        isConsistent = false
                    default:
                        break
                    }
                }
                if isConsistent{
                    self.onCompletion(true)
                }else{
                    self.onCompletion(false)
                }
            case .failure(_):
                self.onCompletion(false)
            case .cancelled:
                self.onCompletion(false)
            }
        }else{
            self.onCompletion(true)
        }
    }

}
