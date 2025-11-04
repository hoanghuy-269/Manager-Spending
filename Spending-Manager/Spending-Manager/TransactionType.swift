//
//  TransactionType.swift
//  Spending-Manager
//
//  Created by  User on 02/11/2025.
//

import Foundation
class TransactionType{
    var id : Int?
    var name : String
    
    init(id: Int?=nil, name: String) {
        self.id = id
        self.name = name
    }
}
