//
//  TransactionTypeDB.swift
//  Spending-Manager
//
//  Created by  User on 02/11/2025.
//

import Foundation
import UIKit
import os.log

extension AppDatabase {
    
    // MARK: - Insert
    func insertTransactionType(_ t: TransactionType) -> Bool {
        var ok = false
        if openDB() {
            let sql = "INSERT INTO \(TRANSACTION_TABLE) (\(TRANSACTION_NAME)) VALUES (?)"
            if db!.executeUpdate(sql, withArgumentsIn: [t.name]) {
                t.id = Int(db!.lastInsertRowId)
                ok = true
            }
            closeDB()
        }
        return ok
    }
    
    // MARK: - Get All
        func getAllTransactionTypes() -> [TransactionType] {
            var result: [TransactionType] = []
            if openDB() {
                let sql = "SELECT \(TRANSACTION_ID), \(TRANSACTION_NAME) FROM \(TRANSACTION_TABLE)"
                if let rs = db!.executeQuery(sql, withArgumentsIn: []) {
                    while rs.next() {
                        let id = Int(rs.int(forColumn: TRANSACTION_ID))
                        let name = rs.string(forColumn: TRANSACTION_NAME) ?? ""
                        let t = TransactionType(id: id, name: name)
                        result.append(t)
                    }
                }
                closeDB()
            }
            return result
        }
    func insertDefaultTransactionTypes() {
        let existing = getAllTransactionTypes()
        if existing.isEmpty {
            let expense = TransactionType(id: nil, name: "Chi tiêu")
            let income = TransactionType(id: nil, name: "Thu nhập")
            _ = insertTransactionType(expense)
            _ = insertTransactionType(income)
        }
    }
}

