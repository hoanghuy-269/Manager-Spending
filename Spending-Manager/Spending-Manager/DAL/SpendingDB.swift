//
//  SpendingDB.swift
//  Spending-Manager
//
//  Created by  User on 09/11/2025.
//

import Foundation
import os.log
import UIKit

// ====== CRUD CÓ SẴN CỦA BẠN ======
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
    /*
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
    }*/
}

// ====== BỔ SUNG: Helpers ngày giờ & API Lịch ======
private extension AppDatabase {
    var viCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "vi_VN")
        c.firstWeekday = 2
        return c
    }
    func startOfDay(_ date: Date) -> Date { viCalendar.startOfDay(for: date) }
    func endOfDay(_ date: Date) -> Date { viCalendar.date(byAdding: .day, value: 1, to: startOfDay(date))! }

    func toDBString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: date)
    }
    func parseDBDate(_ str: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.date(from: str) ?? Date()
    }
}

// Hiển thị list ngày
struct EntryItem {
    enum Kind { case income, expense }
    let iconName: String
    let iconColor: UIColor
    let title: String
    let amount: Int
    let kind: Kind
}

// Tổng hợp 1 ngày
struct DaySummary {
    let day: Int
    var income: Int
    var expense: Int
    var entries: [EntryItem]
}

// MARK: - Lọc theo khoảng thời gian
extension AppDatabase {
    func getTransactions(between start: Date, and end: Date) -> [Transaction] {
        var list: [Transaction] = []
        if openDB() {
            let s = toDBString(start)
            let e = toDBString(end)
            let sql = """
            SELECT *
            FROM \(TRANSACTIONS_TABLE)
            WHERE \(TRANSACTIONS_DATE) >= ? AND \(TRANSACTIONS_DATE) < ?
            ORDER BY \(TRANSACTIONS_DATE) ASC
            """
            if let rs = db!.executeQuery(sql, withArgumentsIn: [s, e]) {
                while rs.next() {
                    let dateStr = rs.string(forColumn: TRANSACTIONS_DATE) ?? ""
                    let t = Transaction(
                        id: Int(rs.int(forColumn: TRANSACTIONS_ID)),
                        amount: rs.double(forColumn: TRANSACTIONS_AMOUNT),
                        categoryId: Int(rs.int(forColumn: TRANSACTIONS_CATEGORY_ID)),
                        transactionTypeId: Int(rs.int(forColumn: TRANSACTIONS_TYPE_ID)),
                        note: rs.string(forColumn: TRANSACTIONS_NOTE),
                        date: parseDBDate(dateStr)
                    )
                    list.append(t)
                }
                rs.close()
            }
            closeDB()
        }
        return list
    }
}

// MARK: - Tổng hợp 1 ngày (3 ô + list)
extension AppDatabase {
    func getDaySummary(for date: Date) -> DaySummary {
        let s = startOfDay(date)
        let e = endOfDay(date)
        let day = viCalendar.component(.day, from: date)

        var income = 0
        var expense = 0
        var entries: [EntryItem] = []

        if openDB(), let db = db {
            let sql = """
            SELECT t.\(TRANSACTIONS_AMOUNT) AS amount,
                   t.\(TRANSACTIONS_TYPE_ID) AS typeId,
                   IFNULL(c.\(CATEGORY_NAME), '') AS catName,
                   IFNULL(c.\(CATEGORY_ICON), '') AS catIcon
            FROM \(TRANSACTIONS_TABLE) t
            LEFT JOIN \(CATEGORY_TABLE) c ON c.\(CATEGORY_ID) = t.\(TRANSACTIONS_CATEGORY_ID)
            WHERE t.\(TRANSACTIONS_DATE) >= ? AND t.\(TRANSACTIONS_DATE) < ?
            ORDER BY t.\(TRANSACTIONS_DATE) ASC
            """
            if let rs = db.executeQuery(sql, withArgumentsIn: [toDBString(s), toDBString(e)]) {
                while rs.next() {
                    let amount = Int(rs.double(forColumn: "amount"))
                    let typeId = Int(rs.int(forColumn: "typeId"))
                    let catName = (rs.string(forColumn: "catName") ?? "Giao dịch")
                    let catIcon = (rs.string(forColumn: "catIcon")?.isEmpty == false)
                                    ? rs.string(forColumn: "catIcon")!
                                    : iconForCategory(catName)

                    let kind: EntryItem.Kind = (typeId == 2) ? .income : .expense
                    let color: UIColor = colorForCategory(catName, fallback: (kind == .income ? .systemGreen : .systemOrange))

                    if kind == .income { income += amount } else { expense += amount }
                    entries.append(EntryItem(iconName: catIcon, iconColor: color, title: catName, amount: amount, kind: kind))
                }
                rs.close()
            }
            closeDB()
        }
        return DaySummary(day: day, income: income, expense: expense, entries: entries)
    }

     func iconForCategory(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("ăn") || n.contains("food") { return "fork.knife.circle" }
        if n.contains("hằng ngày") || n.contains("daily") { return "drop.circle" }
        if n.contains("lương") || n.contains("salary") { return "wallet.pass" }
        if n.contains("nhà") || n.contains("rent") { return "house.circle" }
        return "square.grid.2x2"
    }
     func colorForCategory(_ name: String, fallback: UIColor) -> UIColor {
        let n = name.lowercased()
        if n.contains("ăn") || n.contains("food") { return .systemOrange }
        if n.contains("hằng ngày") || n.contains("daily") { return .systemGreen }
        if n.contains("lương") || n.contains("salary") { return .systemGreen }
        if n.contains("nhà") || n.contains("rent") { return .systemPink }
        return fallback
    }
     func colorForTransactionType(_ typeId: Int?) -> UIColor {
            guard let typeId = typeId else { return .systemGray }
            // Giả sử typeId = 1 là thu nhập, 2 là chi tiêu
            return (typeId == 1) ? .systemGreen : .systemOrange
        }
}

// MARK: - Markers theo THÁNG (mini Thu/Chi trong ô lịch)
extension AppDatabase {
    func getMonthMarkers(year: Int, month: Int) -> [Int: (income: Int, expense: Int)] {
        var result: [Int: (Int, Int)] = [:]
        if openDB(), let db = db {
            let y = String(format: "%04d", year)
            let m = String(format: "%02d", month)

            let sql = """
            SELECT CAST(strftime('%d', \(TRANSACTIONS_DATE)) AS INTEGER) AS d,
                   SUM(CASE WHEN \(TRANSACTIONS_TYPE_ID) = 2 THEN \(TRANSACTIONS_AMOUNT) ELSE 0 END) AS incomeSum,
                   SUM(CASE WHEN \(TRANSACTIONS_TYPE_ID) = 1 THEN \(TRANSACTIONS_AMOUNT) ELSE 0 END) AS expenseSum
            FROM \(TRANSACTIONS_TABLE)
            WHERE strftime('%Y', \(TRANSACTIONS_DATE)) = ?
              AND strftime('%m', \(TRANSACTIONS_DATE)) = ?
            GROUP BY d
            ORDER BY d
            """
            if let rs = db.executeQuery(sql, withArgumentsIn: [y, m]) {
                while rs.next() {
                    let d   = Int(rs.int(forColumn: "d"))
                    let inc = Int(rs.double(forColumn: "incomeSum"))
                    let exp = Int(rs.double(forColumn: "expenseSum"))
                    result[d] = (inc, exp)
                }
                rs.close()
            }
            closeDB()
        }
        return result
    }
}
