import Foundation
import UIKit

// Tổng hợp cho 1 ngày
struct DaySummary {
    let day: Int
    var income: Int
    var expense: Int
    var entries: [EntryItem]
}

final class TransactionRepository {

    private let adb = AppDatabase.shared

    private var vnCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "vi_VN")
        c.firstWeekday = 2
        return c
    }

    // MARK: - Đọc THEO NGÀY: 3 ô + list
    /// Giả định cột `Transactions.date` lưu **epoch giây** dưới dạng TEXT (hoặc số).
    func fetchDaySummary(date: Date) -> DaySummary {
        let start = vnCalendar.startOfDay(for: date)
        let end   = vnCalendar.date(byAdding: .day, value: 1, to: start)!
        let sEpoch = Int(start.timeIntervalSince1970)
        let eEpoch = Int(end.timeIntervalSince1970)
        let dNum   = vnCalendar.component(.day, from: date)

        var income = 0
        var expense = 0
        var list: [EntryItem] = []

        guard adb.openDB(), let db = adb.db else {
            return DaySummary(day: dNum, income: 0, expense: 0, entries: [])
        }
        defer { adb.closeDB() }

        let t = adb.TRANSACTIONS_TABLE
        let c = adb.CATEGORY_TABLE

        // CAST(date AS INTEGER) để an toàn cho kiểu TEXT/NUMERIC
        let sql = """
        SELECT \(t).\(adb.TRANSACTIONS_AMOUNT)            AS amount,
               \(t).\(adb.TRANSACTIONS_TYPE_ID)          AS typeId,
               IFNULL(\(c).\(adb.CATEGORY_NAME), '')     AS catName,
               IFNULL(\(c).\(adb.CATEGORY_ICON), '')     AS catIcon
        FROM \(t)
        LEFT JOIN \(c) ON \(c).\(adb.CATEGORY_ID) = \(t).\(adb.TRANSACTIONS_CATEGORY_ID)
        WHERE CAST(\(t).\(adb.TRANSACTIONS_DATE) AS INTEGER) >= ? AND CAST(\(t).\(adb.TRANSACTIONS_DATE) AS INTEGER) < ?
        ORDER BY CAST(\(t).\(adb.TRANSACTIONS_DATE) AS INTEGER) ASC;
        """

        if let rs = db.executeQuery(sql, withArgumentsIn: [sEpoch, eEpoch]) {
            while rs.next() {
                let amount  = Int(rs.double(forColumn: "amount"))
                let typeId  = Int(rs.int(forColumn: "typeId"))
                let catName = rs.string(forColumn: "catName") ?? "Giao dịch"
                let catIcon = (rs.string(forColumn: "catIcon")?.isEmpty == false) ? rs.string(forColumn: "catIcon")! : iconForCategory(name: catName)

                let kind: EntryItem.Kind = (typeId == 1) ? .income : .expense
                let color: UIColor = colorForCategory(name: catName, fallback: (kind == .income ? .systemGreen : .systemOrange))

                if kind == .income { income += amount } else { expense += amount }
                list.append(EntryItem(iconName: catIcon, iconColor: color, title: catName, amount: amount, kind: kind))
            }
            rs.close()
        }

        return DaySummary(day: dNum, income: income, expense: expense, entries: list)
    }

    // MARK: - Markers THÁNG: mini số trong ô
    func fetchMonthMarkers(year: Int, month: Int) -> [Int: (income: Int, expense: Int)] {
        var result: [Int: (Int, Int)] = [:]
        guard adb.openDB(), let db = adb.db else { return result }
        defer { adb.closeDB() }

        let t = adb.TRANSACTIONS_TABLE
        // Dùng datetime(unixepoch) với CAST để an toàn kiểu TEXT
        let sql = """
        SELECT CAST(strftime('%d', datetime(CAST(\(t).\(adb.TRANSACTIONS_DATE) AS INTEGER), 'unixepoch')) AS INTEGER) AS d,
               SUM(CASE WHEN \(t).\(adb.TRANSACTIONS_TYPE_ID) = 1 THEN \(t).\(adb.TRANSACTIONS_AMOUNT) ELSE 0 END) AS incomeSum,
               SUM(CASE WHEN \(t).\(adb.TRANSACTIONS_TYPE_ID) <> 1 THEN \(t).\(adb.TRANSACTIONS_AMOUNT) ELSE 0 END) AS expenseSum
        FROM \(t)
        WHERE strftime('%Y', datetime(CAST(\(t).\(adb.TRANSACTIONS_DATE) AS INTEGER), 'unixepoch')) = ?
          AND strftime('%m', datetime(CAST(\(t).\(adb.TRANSACTIONS_DATE) AS INTEGER), 'unixepoch')) = ?
        GROUP BY d
        ORDER BY d;
        """

        let y = String(format: "%04d", year)
        let m = String(format: "%02d", month)

        if let rs = db.executeQuery(sql, withArgumentsIn: [y, m]) {
            while rs.next() {
                let d   = Int(rs.int(forColumn: "d"))
                let inc = Int(rs.double(forColumn: "incomeSum"))
                let exp = Int(rs.double(forColumn: "expenseSum"))
                result[d] = (inc, exp)
            }
            rs.close()
        }
        return result
    }

    // MARK: - Icon/Color gợi ý theo tên Category
    private func iconForCategory(name: String) -> String {
        let n = name.lowercased()
        if n.contains("ăn") || n.contains("food") { return "fork.knife.circle" }
        if n.contains("hằng ngày") || n.contains("daily") { return "drop.circle" }
        if n.contains("lương") || n.contains("salary") { return "wallet.pass" }
        if n.contains("nhà") || n.contains("rent") { return "house.circle" }
        return "square.grid.2x2"
    }
    private func colorForCategory(name: String, fallback: UIColor) -> UIColor {
        let n = name.lowercased()
        if n.contains("ăn") || n.contains("food") { return .systemOrange }
        if n.contains("hằng ngày") || n.contains("daily") { return .systemGreen }
        if n.contains("lương") || n.contains("salary") { return .systemGreen }
        if n.contains("nhà") || n.contains("rent") { return .systemPink }
        return fallback
    }
}
