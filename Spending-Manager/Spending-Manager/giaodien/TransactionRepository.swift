import Foundation
import SQLite3
import UIKit

struct DaySummary {
    let day: Int
    var income: Int
    var expense: Int
    var entries: [EntryItem]
}

final class TransactionRepository {

    private var db: OpaquePointer? { DBManager.shared.db }
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    @inline(__always)
    private func bindText(_ stmt: OpaquePointer?, idx: Int32, _ value: String) {
        value.withCString { sqlite3_bind_text(stmt, idx, $0, -1, SQLITE_TRANSIENT) }
    }
    @inline(__always) private func colInt(_ s: OpaquePointer?, _ i: Int32) -> Int { Int(sqlite3_column_int64(s, i)) }
    @inline(__always) private func colDouble(_ s: OpaquePointer?, _ i: Int32) -> Double { sqlite3_column_double(s, i) }
    @inline(__always) private func colText(_ s: OpaquePointer?, _ i: Int32) -> String {
        guard let c = sqlite3_column_text(s, i) else { return "" }
        return String(cString: c)
    }

    private var vnCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "vi_VN")
        c.firstWeekday = 2
        return c
    }

    // MARK: Theo NGÀY (đổ 3 ô + list)
    func fetchDaySummary(date: Date) -> DaySummary {
        guard let db = db else {
            let d = vnCalendar.component(.day, from: date)
            return DaySummary(day: d, income: 0, expense: 0, entries: [])
        }

        let start = vnCalendar.startOfDay(for: date)
        let end   = vnCalendar.date(byAdding: .day, value: 1, to: start)!
        let sEpoch = Int(start.timeIntervalSince1970)
        let eEpoch = Int(end.timeIntervalSince1970)
        let dNum   = vnCalendar.component(.day, from: date)

        let sql = """
        SELECT t.amount,
               t.transactionTypeId,      -- 1 = income, khác 1 = expense
               c.name  AS categoryName,
               c.icon  AS categoryIcon
        FROM Transaction t
        JOIN Category c ON c.id = t.categoryId
        WHERE t.date >= ? AND t.date < ?
        ORDER BY t.date ASC;
        """

        var stmt: OpaquePointer?
        var income = 0, expense = 0
        var list: [EntryItem] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int64(stmt, 1, sqlite3_int64(sEpoch))
            sqlite3_bind_int64(stmt, 2, sqlite3_int64(eEpoch))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let amount  = Int(colDouble(stmt, 0))
                let typeId  = colInt(stmt, 1)
                let catName = colText(stmt, 2).isEmpty ? "Giao dịch" : colText(stmt, 2)
                let catIcon = colText(stmt, 3).isEmpty ? "square.grid.2x2" : colText(stmt, 3)

                let kind: EntryItem.Kind = (typeId == 1) ? .income : .expense
                let color: UIColor = colorForCategory(name: catName, fallback: (kind == .income ? .systemGreen : .systemOrange))

                if kind == .income { income += amount } else { expense += amount }
                list.append(EntryItem(iconName: iconForCategory(name: catName),
                                      iconColor: color,
                                      title: catName,
                                      amount: amount,
                                      kind: kind))
            }
        } else {
            print("Prepare day error:", String(cString: sqlite3_errmsg(db)))
        }
        return DaySummary(day: dNum, income: income, expense: expense, entries: list)
    }

    // MARK: Markers THÁNG (đổ mini số trong ô lịch)
    func fetchMonthMarkers(year: Int, month: Int) -> [Int: (income: Int, expense: Int)] {
        guard let db = db else { return [:] }
        var result: [Int: (Int, Int)] = [:]

        let sql = """
        SELECT CAST(strftime('%d', datetime(t.date, 'unixepoch')) AS INTEGER) AS d,
               SUM(CASE WHEN t.transactionTypeId = 1 THEN t.amount ELSE 0 END) AS incomeSum,
               SUM(CASE WHEN t.transactionTypeId <> 1 THEN t.amount ELSE 0 END) AS expenseSum
        FROM Transaction t
        WHERE strftime('%Y', datetime(t.date, 'unixepoch')) = ?
          AND strftime('%m', datetime(t.date, 'unixepoch')) = ?
        GROUP BY d
        ORDER BY d;
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            let y = String(format: "%04d", year)
            let m = String(format: "%02d", month)
            bindText(stmt, idx: 1, y)
            bindText(stmt, idx: 2, m)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let d   = colInt(stmt, 0)
                let inc = Int(colDouble(stmt, 1))
                let exp = Int(colDouble(stmt, 2))
                result[d] = (inc, exp)
            }
        } else {
            print("Prepare month markers error:", String(cString: sqlite3_errmsg(db)))
        }
        return result
    }

    // MARK: Icon/Color theo tên category (tuỳ biến)
    private func iconForCategory(name: String) -> String {
        switch name.lowercased() {
        case _ where name.localizedCaseInsensitiveContains("ăn"):
            return "fork.knife.circle"
        case _ where name.localizedCaseInsensitiveContains("hằng ngày"):
            return "drop.circle"
        case _ where name.localizedCaseInsensitiveContains("lương"):
            return "wallet.pass"
        case _ where name.localizedCaseInsensitiveContains("nhà"):
            return "house.circle"
        default:
            return "square.grid.2x2"
        }
    }

    private func colorForCategory(name: String, fallback: UIColor) -> UIColor {
        switch name.lowercased() {
        case _ where name.localizedCaseInsensitiveContains("ăn"):
            return .systemOrange
        case _ where name.localizedCaseInsensitiveContains("hằng ngày"):
            return .systemGreen
        case _ where name.localizedCaseInsensitiveContains("lương"):
            return .systemGreen
        case _ where name.localizedCaseInsensitiveContains("nhà"):
            return .systemPink
        default:
            return fallback
        }
    }
}

