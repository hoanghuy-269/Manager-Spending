//
//  Transaction.swift
//  Spending-Manager
//
//  Created by  User on 02/11/2025.
//

import Foundation
class Transaction{
    var id : Int?
    var amount : Double
    var categoryId: Int
    var transactionTypeId : Int
    var note : String?
    var date : Date
    
    init(id: Int?=nil, amount: Double, categoryId: Int, transactionTypeId: Int, note: String?=nil, date: Date) {
        self.id = id
        self.amount = amount
        self.categoryId = categoryId
        self.transactionTypeId = transactionTypeId
        self.note = note
        self.date = date
    }
}
