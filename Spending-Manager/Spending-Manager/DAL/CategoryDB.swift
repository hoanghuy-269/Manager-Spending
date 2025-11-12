//
//  CategoryDB.swift
//  Spending-Manager
//
//  Created by  User on 09/11/2025.
//

import Foundation
import UIKit
import os.log

extension AppDatabase {
    
    
    // MARK: - Insert
    func insertCategory(_ category: Category) -> Bool {
        var ok = false
        if openDB() {
            // Kiểm tra trùng tên
            let checkSql = "SELECT COUNT(*) FROM \(CATEGORY_TABLE) WHERE \(CATEGORY_NAME) = ? AND \(TRANSACTIONS_TYPE_ID) = ?"
            if let rs = db?.executeQuery(checkSql, withArgumentsIn: [category.name, category.transactionTypeId]) {
                if rs.next() {
                    let count = rs.int(forColumnIndex: 0)
                    if count > 0 {
                        // Đã tồn tại tên này -> không thêm
                        print("Tên danh mục đã tồn tại: \(category.name)")
                        rs.close()
                        closeDB()
                        return false
                    }
                }
                rs.close()
            }

            // Nếu không trùng thì thêm mới
            let sql = "INSERT INTO \(CATEGORY_TABLE) (\(CATEGORY_NAME), \(TRANSACTIONS_TYPE_ID), \(CATEGORY_ICON)) VALUES (?, ?, ?)"
            if db!.executeUpdate(sql, withArgumentsIn: [category.name, category.transactionTypeId, category.icon ?? ""]) {
                category.id = Int(db!.lastInsertRowId)
                ok = true
            }

            closeDB()
        }
        return ok
    }

    
    // MARK: - Update
    func updateCategory(_ category: Category) -> Bool {
        var ok = false
        if openDB() {
            let sql = "UPDATE \(CATEGORY_TABLE) SET \(CATEGORY_NAME) = ?, \(TRANSACTIONS_TYPE_ID) = ?, \(CATEGORY_ICON) = ? WHERE \(CATEGORY_ID) = ?"
            if db!.executeUpdate(sql, withArgumentsIn: [category.name, category.transactionTypeId, category.icon ?? "", category.id ?? 0]) {
                ok = true
            }
            closeDB()
        }
        return ok
    }
    
    // MARK: - Delete
    func deleteCategory(withId id: Int) -> Bool {
        var ok = false
        if openDB() {
            let sql = "DELETE FROM \(CATEGORY_TABLE) WHERE \(CATEGORY_ID) = ?"
            if db!.executeUpdate(sql, withArgumentsIn: [id]) {
                ok = true
            }
            closeDB()
        }
        return ok
    }
    
    // MARK: - Get By ID
    func getCategoryById(_ id: Int?) -> Category? {
        guard let id = id else { return nil }
        var category: Category?
        if openDB() {
            let sql = "SELECT \(CATEGORY_ID), \(CATEGORY_NAME), \(TRANSACTIONS_TYPE_ID), \(CATEGORY_ICON) FROM \(CATEGORY_TABLE) WHERE \(CATEGORY_ID) = ?"
            if let rs = db!.executeQuery(sql, withArgumentsIn: [id]) {
                if rs.next() {
                    let categoryId = Int(rs.int(forColumn: CATEGORY_ID))
                    let name = rs.string(forColumn: CATEGORY_NAME) ?? ""
                    let transactionTypeId = Int(rs.int(forColumn: TRANSACTIONS_TYPE_ID))
                    let icon = rs.string(forColumn: CATEGORY_ICON)
                    category = Category(id: categoryId, name: name, transactionTypeId: transactionTypeId, icon: icon)
                }
            }
            closeDB()
        }
        return category
    }
    
    // MARK: - Get All
    func getCategoriesByTransactionTypeId(_ transactionTypeId: Int) -> [Category] {
        var result: [Category] = []
        if openDB() {
            let sql = """
            SELECT \(CATEGORY_ID), \(CATEGORY_NAME), \(TRANSACTIONS_TYPE_ID), \(CATEGORY_ICON)
            FROM \(CATEGORY_TABLE)
            WHERE \(TRANSACTIONS_TYPE_ID) = ?
            """
            if let rs = db!.executeQuery(sql, withArgumentsIn: [transactionTypeId]) {
                while rs.next() {
                    let id = Int(rs.int(forColumn: CATEGORY_ID))
                    let name = rs.string(forColumn: CATEGORY_NAME) ?? ""
                    let transactionTypeId = Int(rs.int(forColumn: TRANSACTIONS_TYPE_ID))
                    let icon = rs.string(forColumn: CATEGORY_ICON)
                    let category = Category(
                        id: id,
                        name: name,
                        transactionTypeId: transactionTypeId,
                        icon: icon
                    )
                    result.append(category)
                }
            }
            closeDB()
        }
        return result
    }
    func insertDefaultSampleCategoriesIfNeeded() {
        // Kiểm tra nếu đã có category (ví dụ: lấy count)
        if openDB() {
            let sqlCheck = "SELECT COUNT(*) as cnt FROM \(CATEGORY_TABLE)"
            var shouldInsert = false
            if let rs = db!.executeQuery(sqlCheck, withArgumentsIn: []) {
                if rs.next() {
                    let cnt = Int(rs.int(forColumn: "cnt"))
                    shouldInsert = (cnt == 0) // chỉ chèn nếu chưa có category nào
                } else {
                    shouldInsert = true
                }
            } else {
                shouldInsert = true
            }
            closeDB()

            if shouldInsert {
                let samples: [(String, String, Int)] = [
                    ("Ăn uống", "cart", TransactionTypeId.chiTieu.rawValue),
                    ("Mua sắm", "cart", TransactionTypeId.chiTieu.rawValue),
                    ("Di chuyển", "car", TransactionTypeId.chiTieu.rawValue),
                    ("Giải trí", "cart", TransactionTypeId.chiTieu.rawValue),
                    ("Hóa đơn", "doc.text", TransactionTypeId.chiTieu.rawValue),
                    ("Lương", "banknote", TransactionTypeId.thuNhap.rawValue),
                    ("Thưởng", "gift", TransactionTypeId.thuNhap.rawValue),
                    ("Bán hàng", "bag", TransactionTypeId.thuNhap.rawValue)
                ]
                for s in samples {
                    let cat = Category(id: 0, name: s.0, transactionTypeId: s.2, icon: s.1)
                    _ = insertCategory(cat)
                }
                print("Inserted sample categories")
            } else {
                print("ℹ️ Categories already exist — skip inserting samples")
                
            }
        }
    }

}
