//
//  SequenceOfTasks.swift
//  BartlebysCore
//
//  Created by Benoit Pereira da silva on 20/04/2018.
//  Copyright © 2018 Bartleby. All rights reserved.
//

import Foundation

// You can use a sequence of tasks process asynchronously tasks.

public enum TaskCompletionState{
    case success
    case failure(withError:Error)
    case cancelled
}

public enum TaskCompletionError:Error{
    case unexistingIndex
    case message(message:String)
}

/// We use a class and passe the items by references.
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

    public fileprivate(set) var isPaused: Bool = false

    public fileprivate(set) var states:[TaskCompletionState] = [TaskCompletionState]()

    public var totalCount: Int { return self._items.count }

    public var completedCount: Int { return self.index - 1 }

    /// The referenced task handling closure used to proceed asynchronously a discreet task.
    /// on task completion you must call sequence.taskCompleted()
    fileprivate  var _taskHandler:(_ item: T, _ sequence: SequenceOfTasks<T>)->()

    /// The reference sequence completion closure
    public fileprivate(set) var onSequenceCompletion:((_ success:Bool)->())


    // MARK: - API

    /// The constructor.
    ///
    /// - Parameters:
    ///   - items: the items to be sequentially processed
    ///   - taskHandler: the discreet task handler (call sequence.taskCompleted() on completion)
    ///   - onSequenceCompletion: : the completion handler called when all the tasks of the sequence has been executed.
    ///   - delayBetweenTasks: the execution delay between the end of the current tasks and its successor.
    public init( items: inout [T],
                 taskHandler: @escaping(_ item: T, _ sequence: SequenceOfTasks<T>)->(),
                 onSequenceCompletion: @escaping(_ success: Bool) -> () ,
                 delayBetweenTasks: TimeInterval = 0) {
        self._items = items
        self._taskHandler = taskHandler
        self.onSequenceCompletion = onSequenceCompletion
        self._delay = delayBetweenTasks
    }


    /// Starts the sequence
    public func start(){
        if !self.isPaused {
            if self._items.count > 0{
                let _ = self._runTask(at: self.index)
            }else{
                self._endOfTheSequence()
            }
        }
    }

    /// Resumes the sequence
    public func resume(){
        self.isPaused = false
        self.start()
    }

    /// Pauses the sequence
    public func pause(){
        self.isPaused = true
    }


    /// Cancels the sequence
    /// and triggers a non successful completion.
    public func cancel(){
        while self.index < self._items.count{
            self.index += 1
            self.states.append(TaskCompletionState.cancelled)
        }
        self.onSequenceCompletion(false)
    }


    /// Should be called on any task completion.
    ///
    /// - Parameter state: the completion state.
    public func taskCompleted(_ state:TaskCompletionState){
        self._onTaskCompletion(state)
    }

    /// Runs the next task.
    /// - Returns: true if there was a task.
    public func runNextTask() -> Bool{
        self.index += 1
        self._runTask(at: self.index)
        return self.index < self._items .count
    }


    // MARK: - Task running logic

    /// Runs the discreet task at a given index and stores its completion state.
    ///
    /// - Parameter index: the index.
    fileprivate func _runTask(at index:Int){
        if index == self._items.count{
            self._endOfTheSequence()
        }else{
            if index < self._items.count {
                self._taskHandler(self._items[index], self)
            }else{
                // can occur on external mutation of the referenced items list.
                self._onTaskCompletion(.failure(withError: TaskCompletionError.unexistingIndex))
            }
        }
    }

    fileprivate func _onTaskCompletion(_ taskState:TaskCompletionState){
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
        if self.chainTheTasksAutomatically && self.isPaused == false{
            if self._delay == 0 {
                self.queue.async {
                    let _ = self.runNextTask()
                }
            }else{
                let delayInNanoS =  UInt64(self._delay * 1_000_000_000)
                let deadLine = DispatchTime.init(uptimeNanoseconds:delayInNanoS)
                self.queue.asyncAfter(deadline: deadLine) {
                    let _ = self.runNextTask()
                }
            }
        }
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
                    self.onSequenceCompletion(true)
                }else{
                    self.onSequenceCompletion(false)
                }
            case .failure(_):
                self.onSequenceCompletion(false)
            case .cancelled:
                self.onSequenceCompletion(false)
            }
        }else{
            self.onSequenceCompletion(true)
        }
    }

}
