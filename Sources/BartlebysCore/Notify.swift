//
//  Notify.swift
//  BartlebyKit macOS
//
//  Created by Benoit Pereira da silva on 06/01/2018.
//

import Foundation


public struct Notify<T:Collectable>{

    /// Returns a generic selectionChanged Notification Name
    /// e.g = NotificationCenter.default.post(name: Notify<ManagedModel>.selectionChanged(), object: nil)
    ///
    /// - Returns: the Notification Name
    public static func selectionChanged()-> Notification.Name{
        return Notification.Name(rawValue: "org.bartlebys.notification.\(T.typeName).selection.Changed")
    }


    /// Post the selection Notification on the Default notification center
    /// e.g: Notify<ManagedModel>.postSelectionChanged()
    public static func postSelectionChanged(){
        NotificationCenter.default.post(name: Notify<T>.selectionChanged(), object: nil)
    }

}
