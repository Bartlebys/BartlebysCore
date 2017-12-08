//
//  Credentials.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 07/12/2017.
//  Copyright © 2017 MusicWork. All rights reserved.
//

import Foundation

open class Credentials:Codable{

    public var username: String
    public var password: String

    public init(username: String, password: String){
        self.username = username
        self.password = password
    }
}
