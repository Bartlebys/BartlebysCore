//
//  ManagedModel+Description.swift
//  BartlebyCore
//
//  Created by Benoit Pereira da silva on 05/12/2017.
//  Copyright © 2017 Benoit Pereira da Silva https://bartlebys.org. All rights reserved.
//

import Foundation

extension Model{

    // CustomStringConvertible

    open override var description: String {
        do{
            let data =  try JSON.prettyEncoder.encode(self)
            if let json = String(data:data,encoding:.utf8){
                return json
            }
        }catch{
            return "\(error)"
        }
        return "Description is not available"
    }

}
