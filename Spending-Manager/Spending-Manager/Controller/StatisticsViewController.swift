import UIKit
import DGCharts

class StatisticsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var showstatics: UIView!
    @IBOutlet weak var tableviewstatics: UITableView!
    
    // MARK: - Properties
    private var barChartView: BarChartView!
    var selectedCategory: Category?
    private var transactionsForCategory: [Transaction] = []
    private let db = AppDatabase.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // ✅ DEBUG: Kiểm tra category có được truyền vào không
//        print("🔍 StatisticsViewController - viewDidLoad")
//        if let category = selectedCategory {
//            print("✅ Đã nhận category: \(category.name) (ID: \(category.id))")
//        } else {
//            print("❌ selectedCategory = nil - Không nhận được dữ liệu!")
//        }
    
        
        setupChart()
        setupTableView()
        
        // Lắng nghe notification khi transaction được cập nhật/xóa
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionUpdate),
            name: .didUpdateTransaction,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🔍 StatisticsViewController - viewWillAppear")
        reloadCategoryData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup Chart
    private func setupChart() {
        barChartView = BarChartView(frame: showstatics.bounds)
        barChartView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        showstatics.addSubview(barChartView)
        
        barChartView.rightAxis.enabled = true
        barChartView.leftAxis.enabled = false
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.rightAxis.drawGridLinesEnabled = false
        barChartView.animate(yAxisDuration: 1.2, easingOption: .easeInOutQuart)
        barChartView.legend.enabled = true
        barChartView.chartDescription.text = "Thống kê chi tiêu theo tháng"
    }

    // MARK: - Setup TableView
    private func setupTableView() {
        tableviewstatics.dataSource = self
        tableviewstatics.delegate = self
        
    }

    // MARK: - Reload Category Data
    func reloadCategoryData() {
        guard let category = selectedCategory else {
            print("⚠️ Không có category được chọn trong reloadCategoryData()")
            transactionsForCategory = []
            barChartView.data = BarChartData()
            tableviewstatics.reloadData()
            return
        }
        
        
        
        // Lấy transaction thuộc category này
        let allTransactions = db.getAllTransactions()
        print("📊 Tổng số transactions: \(allTransactions.count)")
        
        transactionsForCategory = allTransactions.filter { $0.categoryId == category.id }
        print("📊 Transactions cho category \(category.name): \(transactionsForCategory.count)")
        
        if transactionsForCategory.isEmpty {
            print("⚠️ Category \(category.name) chưa có transaction")
            barChartView.data = BarChartData()
        } else {
            print("✅ Tìm thấy \(transactionsForCategory.count) transactions")
            updateChart()
        }
        
        tableviewstatics.reloadData()
    }

    // MARK: - Update Chart
    private func updateChart() {
        guard let category = selectedCategory else {
            print("❌ updateChart: selectedCategory = nil")
            return
        }
        
        let calendar = Calendar.current
        var monthlyTotals: [Int: Double] = [:]
        
        for t in transactionsForCategory {
            let month = calendar.component(.month, from: t.date)
            monthlyTotals[month, default: 0] += t.amount
        }
        
        var entries: [BarChartDataEntry] = []
        for month in 1...12 {
            let total = monthlyTotals[month] ?? 0
            entries.append(BarChartDataEntry(x: Double(month-1), y: total))
        }
        
        let dataSet = BarChartDataSet(entries: entries, label: category.name)
        dataSet.colors = [UIColor.systemBlue]
        dataSet.valueFont = .systemFont(ofSize: 12)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        
        let data = BarChartData(dataSet: dataSet)
        barChartView.data = data
        
        let months = ["1","2","3","4","5","6","7","8","9","10","11","12"]
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: months)
        barChartView.xAxis.granularity = 1
        barChartView.notifyDataSetChanged()
        
        print("✅ Đã load thống kê Category \(category.name): \(monthlyTotals)")
    }

    // MARK: - Notification Handler
    @objc private func handleTransactionUpdate() {
        print("🔔 Nhận notification: didUpdateTransaction")
        reloadCategoryData()
    }
}

// MARK: - TableView DataSource & Delegate
extension StatisticsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = transactionsForCategory.count
        print("📊 TableView numberOfRows: \(count)")
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "TransactionCell",
            for: indexPath
        ) as? transactionViewCell else {
            print("❌ Không thể dequeue transactionViewCell")
            return UITableViewCell()
        }
        
        let transaction = transactionsForCategory[indexPath.row]
        cell.configure(with: transaction, category: selectedCategory)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Notification Name Extension
extension Notification.Name {
    static let didUpdateTransaction = Notification.Name("didUpdateTransaction")
}
