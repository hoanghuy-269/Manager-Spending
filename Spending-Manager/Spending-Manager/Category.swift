//
//  Category.swift
//  Spending-Manager
//
//  Created by  User on 02/11/2025.
//

import Foundation
class Category{
    var id : Int?
    var name : String
    var transactionTypeId : Int
    var icon : String?
    
    init(id: Int?=nil, name: String, transactionTypeId: Int, icon: String?) {
        self.id = id
        self.name = name
        self.transactionTypeId = transactionTypeId
        self.icon = icon
    }
}
