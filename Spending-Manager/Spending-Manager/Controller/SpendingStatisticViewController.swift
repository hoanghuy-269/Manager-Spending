import UIKit
import DGCharts

class SpendingStatisticViewController: UIViewController {
    @IBOutlet weak var PiecharVIew: UIView!
    @IBOutlet weak var previousMonth: UIButton!
    @IBOutlet weak var nextMonth: UIButton!
    @IBOutlet weak var displayDate: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
   
    @IBOutlet weak var tongthuchivathunhap: UILabel!
    @IBOutlet weak var tongthunhap: UILabel!
    @IBOutlet weak var tongchitieu: UILabel!
    
    private var pieChart: PieChartView!
    private var isShowingChiTieu = true
    private var currentMonth: Date = Date()
    private let formatter = DateFormatter()
    private let db = AppDatabase.shared
    private var transactions: [Transaction] = []
    private var transactionsForCurrentMonth: [Transaction] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPieChart()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "MMMM yyyy"
        

        updateMonthLabel()
        tableView.dataSource = self
        tableView.delegate = self
        
        // Đặt segment đầu tiên được chọn (Chi Tiêu)
        segmentedControl.selectedSegmentIndex = 0
    }
    
    // MARK: - Segment Changed
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        // Index 0 = Chi Tiêu, Index 1 = Thu Nhập
        isShowingChiTieu = (sender.selectedSegmentIndex == 0)
        reloadChartDataForCurrentMonth()
    }
    
    // MARK: - Setup biểu đồ
    func setupPieChart() {
        pieChart = PieChartView(frame: PiecharVIew.bounds)
        pieChart.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        PiecharVIew.addSubview(pieChart)
    }

    // MARK: - Tháng hiển thị
    func updateMonthLabel() {
        displayDate.text = formatter.string(from: currentMonth)
        reloadChartDataForCurrentMonth()
    }

    @IBAction func nextMonthTapped(_ sender: UIButton) {
        changeMonth(by: 1)
    }

    @IBAction func previousMonthTapped(_ sender: UIButton) {
        changeMonth(by: -1)
    }

    func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
            updateMonthLabel()
        }
    }

    // MARK: - Lọc dữ liệu theo tháng & loại
    func reloadChartDataForCurrentMonth() {
        let allTransactions = db.getAllTransactions()

        // Lọc theo tháng hiện tại
        let calendar = Calendar.current
        let filteredByMonth = allTransactions.filter { t in
            return calendar.isDate(t.date, equalTo: currentMonth, toGranularity: .month)
        }
        
        // **Gọi hàm tính toán và hiển thị tổng thu/chi**
        calculateAndDisplayTotals(allTransactionsInMonth: filteredByMonth)

        // Lọc theo loại (thu nhập hoặc chi tiêu) để vẽ chart
        let filtered = filteredByMonth.filter { t in
            isShowingChiTieu ? t.transactionTypeId == 2 : t.transactionTypeId == 1
        }

        // Lưu để hiển thị ra bảng
        transactionsForCurrentMonth = filtered

        // Gom nhóm theo categoryId để vẽ chart
        var grouped: [Int: Double] = [:]
        for t in filtered {
            grouped[t.categoryId, default: 0] += t.amount
        }

        var entries: [PieChartDataEntry] = []
        for (catId, total) in grouped {
            // Load category name trực tiếp từ database
            let categoryName = db.getCategoryName(by: catId)
            entries.append(PieChartDataEntry(value: total, label: categoryName))
        }

        updateChart(with: entries)
        tableView.reloadData()
    }
    
    // MARK: - Tính toán và Hiển thị Tổng
    func calculateAndDisplayTotals(allTransactionsInMonth: [Transaction]) {
        // transactionTypeId = 1 là Thu Nhập
        let totalIncome = allTransactionsInMonth
            .filter { $0.transactionTypeId == 1 }
            .map { $0.amount }
            .reduce(0, +)

        let totalExpense = allTransactionsInMonth
            .filter { $0.transactionTypeId == 2 }
            .map { $0.amount }
            .reduce(0, +)

        let netBalance = totalIncome - totalExpense

        
        // Hàm format tiền tệ (cần đảm bảo có hàm này, nếu chưa có, nên tạo)
        let incomeString = formatCurrency(totalIncome)
        let expenseString = formatCurrency(totalExpense)
        let balanceString = formatCurrency(netBalance)
        
        // Cập nhật các Label
        tongthunhap.text = incomeString
        tongchitieu.text = expenseString
        tongthuchivathunhap.text = balanceString
        
        // (Tùy chọn) Đổi màu cho tổng thu/chi ròng
        tongthuchivathunhap.textColor = netBalance >= 0 ? .systemGreen : .systemRed
    }


    func updateChart(with entries: [PieChartDataEntry]) {
        let dataSet = PieChartDataSet(entries: entries)
        dataSet.colors = ChartColorTemplates.material()
        dataSet.valueTextColor = .label
        dataSet.valueFont = .systemFont(ofSize: 14)

        let data = PieChartData(dataSet: dataSet)
        pieChart.data = data
    }
}



extension SpendingStatisticViewController {
    func formatCurrency(_ amount: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        
        nf.locale = Locale(identifier: "vi_VN")
        
        // KHÔNG hiển thị phần thập phân cho VND
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        
        return nf.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

}


// MARK: - TableView DataSource & Delegate
extension SpendingStatisticViewController: UITableViewDataSource, UITableViewDelegate {
    // ... (Phần TableView không thay đổi)
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactionsForCurrentMonth.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Xử lý safe unwrap
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as? transactionViewCell else {
            return UITableViewCell()
        }
        
        let transaction = transactionsForCurrentMonth[indexPath.row]
        
        // Load category trực tiếp từ database
        let category = db.getCategoryById(transaction.categoryId)
        
        // Gọi configure với category
        cell.configure(with: transaction, category: category)
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowStatisticsSegue" {
            
            // 1. Ép kiểu sender thành UITableViewCell
            if let cell = sender as? transactionViewCell {
                
                // 2. Lấy IndexPath từ cell
                if let indexPath = tableView.indexPath(for: cell) {
                    
                    // 3. Lấy dữ liệu transaction và category
                    let transaction = transactionsForCurrentMonth[indexPath.row]
                    let selectedCategory = db.getCategoryById(transaction.categoryId)
                    
                    
                    // 5. Truyền sang StatisticsViewController
                    if let statisticsVC = segue.destination as? StatisticsViewController {
                        statisticsVC.selectedCategory = selectedCategory
                       
                    }
                    
                } else {
                    print(" Lỗi: Không tìm thấy IndexPath cho Cell")
                }
                
            } else {
                print("Lỗi: Sender không phải transactionViewCell")
              
            }
        }
    }
}
