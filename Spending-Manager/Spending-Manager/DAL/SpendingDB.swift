//
//  SpendingDB.swift
//  Spending-Manager
//
//  Created by  User on 09/11/2025.
//

import Foundation
import os.log

extension AppDatabase {
    
    // MARK: - Insert Transaction
    func insertTransaction(_ transaction: Transaction) -> Bool {
        var success = false
        if openDB() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = formatter.string(from: transaction.date)
            
            let sql = """
            INSERT INTO \(TRANSACTIONS_TABLE)
            (\(TRANSACTIONS_AMOUNT), \(TRANSACTIONS_CATEGORY_ID), \(TRANSACTIONS_TYPE_ID), \(TRANSACTIONS_NOTE), \(TRANSACTIONS_DATE))
            VALUES (?, ?, ?, ?, ?)
            """
            
            success = db!.executeUpdate(sql, withArgumentsIn: [
                transaction.amount,
                transaction.categoryId,
                transaction.transactionTypeId,
                transaction.note ?? "",
                dateString
            ])
            
            if !success {
                os_log("Insert transaction failed: %@", db!.lastErrorMessage())
            }
            closeDB()
        }
        return success
    }
    
    // MARK: - Update Transaction
    func updateTransaction(_ transaction: Transaction) -> Bool {
        guard let id = transaction.id else { return false }
        var success = false
        if openDB() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = formatter.string(from: transaction.date)
            
            let sql = """
            UPDATE \(TRANSACTIONS_TABLE)
            SET \(TRANSACTIONS_AMOUNT) = ?, \(TRANSACTIONS_CATEGORY_ID) = ?, \(TRANSACTIONS_TYPE_ID) = ?, \(TRANSACTIONS_NOTE) = ?, \(TRANSACTIONS_DATE) = ?
            WHERE \(TRANSACTIONS_ID) = ?
            """
            
            success = db!.executeUpdate(sql, withArgumentsIn: [
                transaction.amount,
                transaction.categoryId,
                transaction.transactionTypeId,
                transaction.note ?? "",
                dateString,
                id
            ])
            
            if !success {
                os_log("Update transaction failed: %@", db!.lastErrorMessage())
            }
            closeDB()
        }
        return success
    }
    
    // MARK: - Delete Transaction
    func deleteTransaction(byId id: Int) -> Bool {
        var success = false
        if openDB() {
            let sql = "DELETE FROM \(TRANSACTIONS_TABLE) WHERE \(TRANSACTIONS_ID) = ?"
            success = db!.executeUpdate(sql, withArgumentsIn: [id])
            if !success {
                os_log("Delete transaction failed: %@", db!.lastErrorMessage())
            }
            closeDB()
        }
        return success
    }
    
    // MARK: - Fetch All Transactions
    func getAllTransactions() -> [Transaction] {
        var list: [Transaction] = []
        if openDB() {
            let sql = "SELECT * FROM \(TRANSACTIONS_TABLE) ORDER BY \(TRANSACTIONS_DATE) DESC"
            if let rs = db!.executeQuery(sql, withArgumentsIn: []) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                while rs.next() {
                    let dateStr = rs.string(forColumn: TRANSACTIONS_DATE) ?? ""
                    let date = formatter.date(from: dateStr) ?? Date()
                    
                    let t = Transaction(
                        id: Int(rs.int(forColumn: TRANSACTIONS_ID)),
                        amount: rs.double(forColumn: TRANSACTIONS_AMOUNT),
                        categoryId: Int(rs.int(forColumn: TRANSACTIONS_CATEGORY_ID)),
                        transactionTypeId: Int(rs.int(forColumn: TRANSACTIONS_TYPE_ID)),
                        note: rs.string(forColumn: TRANSACTIONS_NOTE),
                        date: date
                    )
                    list.append(t)
                }
                rs.close()
            } else {
                os_log(" Fetch transactions failed: %@", db!.lastErrorMessage())
            }
            closeDB()
        }
        return list
    }
    
    // MARK: - Fetch by Category
    func getTransactions(byCategoryId categoryId: Int) -> [Transaction] {
        var list: [Transaction] = []
        if openDB() {
            let sql = "SELECT * FROM \(TRANSACTIONS_TABLE) WHERE \(TRANSACTIONS_CATEGORY_ID) = ?"
            if let rs = db!.executeQuery(sql, withArgumentsIn: [categoryId]) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                while rs.next() {
                    let dateStr = rs.string(forColumn: TRANSACTIONS_DATE) ?? ""
                    let date = formatter.date(from: dateStr) ?? Date()
                    
                    let t = Transaction(
                        id: Int(rs.int(forColumn: TRANSACTIONS_ID)),
                        amount: rs.double(forColumn: TRANSACTIONS_AMOUNT),
                        categoryId: Int(rs.int(forColumn: TRANSACTIONS_CATEGORY_ID)),
                        transactionTypeId: Int(rs.int(forColumn: TRANSACTIONS_TYPE_ID)),
                        note: rs.string(forColumn: TRANSACTIONS_NOTE),
                        date: date
                    )
                    list.append(t)
                }
                rs.close()
            }
            closeDB()
        }
        return list
    }
    
    // MARK: - Insert Sample Transactions
    func insertSampleTransactions() {
        let samples: [Transaction] = [
            Transaction(amount: 150000, categoryId: 1, transactionTypeId: 2, note: "Mua đồ ăn trưa", date: Date()),
            Transaction(amount: 500000, categoryId: 3, transactionTypeId: 2, note: "Thanh toán tiền điện", date: Date()),
            Transaction(amount: 2000000, categoryId: 2, transactionTypeId: 1, note: "Nhận lương freelance", date: Date()),
            Transaction(amount: 100000, categoryId: 4, transactionTypeId: 2, note: "Uống cà phê", date: Date()),
            Transaction(amount: 7500000, categoryId: 5, transactionTypeId: 1, note: "Nhận lương tháng 11", date: Date())
        ]
        
        for t in samples {
            _ = insertTransaction(t)
        }
        os_log("Sample transactions inserted successfully.")
    }
}
