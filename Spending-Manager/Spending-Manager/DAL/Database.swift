//
//  Database.swift
//  Spending-Manager
//
//  Created by  User on 02/11/2025.
//

//
//  AppDatabase.swift
//  Spending-Manager
//

import Foundation

class AppDatabase {
    static let shared = AppDatabase()
    
    private let DB_NAME = "expense.sqlite"
    private let DB_PATH: String?
    let db: FMDatabase?
    
    // --- Table names ---
    let TRANSACTION_TABLE = "TransactionTypes"
    let CATEGORY_TABLE = "Categories"
    let TRANSACTIONS_TABLE = "Transactions"
    
    // --- TransactionTypes columns ---
    let TRANSACTION_ID = "_id"
    let TRANSACTION_NAME = "name"
    
    // --- Categories columns ---
    let CATEGORY_ID = "_id"
    let CATEGORY_NAME = "name"
    let CATEGORY_TYPE_ID = "transactionTypeId"
    let CATEGORY_ICON = "icon"
    
    // --- Transactions columns ---
    let TRANSACTIONS_ID = "_id"
    let TRANSACTIONS_AMOUNT = "amount"
    let TRANSACTIONS_TYPE_ID = "transactionTypeId"
    let TRANSACTIONS_CATEGORY_ID = "categoryId"
    let TRANSACTIONS_NOTE = "note"
    let TRANSACTIONS_DATE = "date"
    
    // MARK: - Init
    private init() {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        DB_PATH = directories.first! + "/" + DB_NAME
        db = FMDatabase(path: DB_PATH)
        
        if db != nil {
            createTables()
        }
    }
    
    // MARK: - Open / Close DB
    func openDB() -> Bool { db?.open() ?? false }
    func closeDB() { db?.close() }
    
    // MARK: - Create Tables
    private func createTables() {
        if openDB() {
            // TransactionTypes table
            let sql1 = """
            CREATE TABLE IF NOT EXISTS \(TRANSACTION_TABLE)(
                \(TRANSACTION_ID) INTEGER PRIMARY KEY AUTOINCREMENT,
                \(TRANSACTION_NAME) TEXT
            )
            """
            db!.executeStatements(sql1)
            
            // Categories table
            let sql2 = """
            CREATE TABLE IF NOT EXISTS \(CATEGORY_TABLE)(
                \(CATEGORY_ID) INTEGER PRIMARY KEY AUTOINCREMENT,
                \(CATEGORY_NAME) TEXT,
                \(CATEGORY_TYPE_ID) INTEGER,
                \(CATEGORY_ICON) TEXT
            )
            """
            db!.executeStatements(sql2)
            
            // Transactions table
            let sql3 = """
            CREATE TABLE IF NOT EXISTS \(TRANSACTIONS_TABLE)(
                \(TRANSACTIONS_ID) INTEGER PRIMARY KEY AUTOINCREMENT,
                \(TRANSACTIONS_AMOUNT) DOUBLE,
                \(TRANSACTIONS_CATEGORY_ID) INTEGER,
                \(TRANSACTIONS_TYPE_ID) INTEGER,
                \(TRANSACTIONS_NOTE) TEXT,
                \(TRANSACTIONS_DATE) TEXT
            )
            """
            db!.executeStatements(sql3)
            
            closeDB()
        }
    }
    func getCategoryName(by id: Int) -> String {
        var name = "Danh mục \(id)"
        if openDB() {
            let sql = "SELECT \(CATEGORY_NAME) FROM \(CATEGORY_TABLE) WHERE \(CATEGORY_ID) = ? LIMIT 1"
            if let rs = db!.executeQuery(sql, withArgumentsIn: [id]) {
                if rs.next() {
                    name = rs.string(forColumn: CATEGORY_NAME) ?? name
                }
                rs.close()
            }
            closeDB()
        }
        return name
    }
    
    func getCategoryById(_ id: Int) -> Category? {
        var category: Category?
        
        if openDB() {
            let sql = """
            SELECT \(CATEGORY_ID), \(CATEGORY_NAME), \(CATEGORY_TYPE_ID), \(CATEGORY_ICON)
            FROM \(CATEGORY_TABLE)
            WHERE \(CATEGORY_ID) = ?
            LIMIT 1
            """
            
            if let rs = db!.executeQuery(sql, withArgumentsIn: [id]) {
                if rs.next() {
                    let id = Int(rs.int(forColumn: CATEGORY_ID))
                    let name = rs.string(forColumn: CATEGORY_NAME) ?? "Không rõ"
                    let typeId = Int(rs.int(forColumn: CATEGORY_TYPE_ID))
                    let icon = rs.string(forColumn: CATEGORY_ICON)
                    
                    category = Category(id: id, name: name, transactionTypeId: typeId, icon: icon)
                }
                rs.close()
            }
            closeDB()
        }
        
        return category
    }


}
