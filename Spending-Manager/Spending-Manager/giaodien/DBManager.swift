import Foundation
import SQLite3

final class DBManager {
    static let shared = DBManager()

    let dbURL: URL
    private(set) var db: OpaquePointer?

    private init() {
        let fm = FileManager.default
        let dbName = "spending.sqlite"
        let doc = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        dbURL = doc.appendingPathComponent(dbName)

        // Có file mẫu trong bundle thì copy ra Documents lần đầu
        if !fm.fileExists(atPath: dbURL.path),
           let bundleURL = Bundle.main.url(forResource: "spending", withExtension: "sqlite") {
            try? fm.copyItem(at: bundleURL, to: dbURL)
        }
        open()
    }

    deinit { close() }

    func open() {
        if db != nil { return }
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(db))
            print("SQLite open error: \(msg)")
        }
    }

    func close() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
}
