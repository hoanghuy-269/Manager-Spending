//
//  MontlySpendingViewController.swift
//  Spending-Manager
//

import UIKit

/// Màn hình "Lịch" – chịu trách nhiệm:
/// - Vẽ lưới lịch (UICollectionView)
/// - Hiển thị 3 ô Thu nhập/Chi tiêu/Tổng
/// - Hiển thị danh sách giao dịch theo ngày (UITableView)
/// - Điều hướng tháng, chọn ngày từ date picker và nạp dữ liệu từ DB
final class MontlySpendingViewController: UIViewController,
    UICollectionViewDataSource, UICollectionViewDelegate,
    UITableViewDataSource, UITableViewDelegate {

    // View giao diện thuần code (đã tách ở CalendarScreenInterface)
    private var ui: CalendarScreenInterface!

    // MARK: - Trạng thái lịch
    private var days: [Int?] = []                   // Ma trận ngày (bao gồm nil để lấp đầy ô trống)
    private var currentMonthDate = Date()           // Con trỏ tháng hiện tại (sử dụng ngày-1 của tháng)
    private var selectedDay: Int? = nil             // Ngày đang chọn trong tháng hiện tại

    // MARK: - Dữ liệu để hiển thị
    private var monthMarkers: [Int: (income: Int, expense: Int)] = [:] // Tổng thu/chi từng NGÀY trong tháng (hiển thị mini text trong ô)
    private var entries: [EntryItem] = []          // Danh sách giao dịch của NGÀY đang chọn

    // MARK: - Vòng đời view

    /// Tạo root view = CalendarScreenInterface (tránh hai lớp view chồng nhau)
    override func loadView() {
        ui = CalendarScreenInterface()
        view = ui
    }

    /// Gắn delegate/dataSource, seed dữ liệu mẫu (Debug), nạp tháng hiện tại, gán action cho các nút
    override func viewDidLoad() {
        super.viewDidLoad()

        // Kết nối datasource/delegate
        ui.collectionView.dataSource = self
        ui.collectionView.delegate = self
        ui.tableView.dataSource = self
        ui.tableView.delegate = self

        // 💡 Seed dữ liệu mẫu khi DB trống (chỉ dùng lúc Debug)
        #if DEBUG
        if AppDatabase.shared.getAllTransactions().isEmpty {
            AppDatabase.shared.insertSampleTransactions()
        }
        #endif

        // Khởi động với tháng hiện tại
        currentMonthDate = Date()
        rebuildDays(for: currentMonthDate)

        // Chọn mặc định = hôm nay (nếu đang đứng trong đúng tháng/năm hiện tại)
        let today = Date()
        let compMonth = vnCalendar.component(.month, from: today)
        let compYear  = vnCalendar.component(.year,  from: today)
        if vnCalendar.component(.month, from: currentMonthDate) == compMonth &&
            vnCalendar.component(.year, from: currentMonthDate) == compYear {
            let d = vnCalendar.component(.day, from: today)
            if let _ = days.firstIndex(where: { $0 == d }) { showDay(d) }
        }

        // Điều hướng tháng & mở DatePicker chọn ngày
        ui.prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        ui.nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        ui.monthLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(monthTapped)))
    }

    // MARK: - Calendar helpers (thiết lập lịch Việt Nam)

    /// Lịch Gregorian, locale vi_VN, tuần bắt đầu T2
    private var vnCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "vi_VN")
        c.firstWeekday = 2
        return c
    }

    /// Lấy ngày đầu tiên của tháng (00:00)
    private func startOfMonth(_ d: Date) -> Date {
        vnCalendar.date(from: vnCalendar.dateComponents([.year,.month], from: d))!
    }

    /// Số ngày trong tháng
    private func daysInMonth(_ d: Date) -> Int {
        vnCalendar.range(of: .day, in: .month, for: startOfMonth(d))!.count
    }

    /// Chuỗi tiêu đề tháng dạng "MM/YYYY"
    private func titleMonth(_ d: Date) -> String {
        let m = String(format: "%02d", vnCalendar.component(.month, from: d))
        let y = vnCalendar.component(.year, from: d)
        return "\(m)/\(y)"
    }

    /// Chuỗi thứ rút gọn theo vi_VN
    private func weekdayShort(_ d: Date) -> String {
        ["CN","T.2","T.3","T.4","T.5","T.6","T.7"][vnCalendar.component(.weekday, from: d)-1]
    }

    /// Định dạng tiền có dấu chấm nhóm + hậu tố "đ"
    private func money(_ v: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.groupingSeparator = "."
        return (f.string(from: NSNumber(value: v)) ?? "0") + "đ"
    }

    // MARK: - Xây ma trận ngày + tải markers của THÁNG

    /// Tạo mảng `days` cho tháng đang xem, chèn `nil` để canh lề theo T2..CN, đồng thời nạp tổng thu/chi từng ngày (markers)
    private func rebuildDays(for date: Date) {
        // Tạo ma trận ngày (bao gồm phần đệm đầu/đuôi để đủ bội số 7)
        let first = startOfMonth(date)
        let count = daysInMonth(date)
        let w = vnCalendar.component(.weekday, from: first)  // 1..7 (CN..T7)
        let mondayBased = ((w + 5) % 7) + 1                  // 1..7 (T2..CN)
        let leading = mondayBased - 1

        var arr: [Int?] = Array(repeating: nil, count: leading)
        arr.append(contentsOf: (1...count).map { $0 })
        let rem = arr.count % 7
        if rem != 0 { arr += Array(repeating: nil, count: 7 - rem) }
        days = arr

        // Lấy markers tháng từ DB (để hiển thị con số nhỏ trong từng ô ngày)
        let y = vnCalendar.component(.year, from: date)
        let m = vnCalendar.component(.month, from: date)
        monthMarkers = AppDatabase.shared.getMonthMarkers(year: y, month: m)

        // Reset chọn ngày & UI
        selectedDay = nil
        ui.setMonthTitle(titleMonth(date))
        ui.collectionView.reloadData()

        // Xoá summary/list cũ
        entries = []
        ui.setSummary(income: "0đ", expense: "0đ", total: "0đ")
        ui.setListHeader(left: "", right: "")
        ui.tableView.reloadData()
    }

    // MARK: - Đổ dữ liệu cho NGÀY đang chọn

    /// Nạp tổng thu/chi + danh sách giao dịch của một NGÀY và cập nhật UI liên quan
    private func showDay(_ day: Int) {
        guard day >= 1 else { return }
        selectedDay = day

        // Tạo Date cụ thể của ngày trong tháng hiện tại
        var comps = vnCalendar.dateComponents([.year,.month], from: currentMonthDate)
        comps.day = day
        let date = vnCalendar.date(from: comps)!

        // Lấy tổng hợp ngày từ DB (thu, chi, entries)
        let sum = AppDatabase.shared.getDaySummary(for: date)
        let total = sum.income - sum.expense

        // Cập nhật 3 ô tổng hợp
        ui.setSummary(income: money(sum.income),
                      expense: money(sum.expense),
                      total:   money(total))

        // Cập nhật list giao dịch ngày
        entries = sum.entries

        // Header list: "dd/MM (T.x)" bên trái, "tổng" bên phải
        let df = DateFormatter(); df.locale = Locale(identifier: "vi_VN"); df.dateFormat = "dd/MM"
        ui.setListHeader(left: "\(df.string(from: date)) (\(weekdayShort(date)))",
                         right: money(total))

        // Cập nhật lại marker của đúng ngày vừa nạp (phản ánh tức thì mini text)
        monthMarkers[day] = (sum.income, sum.expense)

        // Refresh UI
        ui.tableView.reloadData()
        ui.collectionView.reloadData()
    }

    // MARK: - Điều hướng tháng & Date Picker

    /// Chuyển về tháng trước
    @objc private func prevMonth() {
        if let d = vnCalendar.date(byAdding: .month, value: -1, to: currentMonthDate) {
            currentMonthDate = d
            rebuildDays(for: d)
        }
    }

    /// Chuyển sang tháng kế
    @objc private func nextMonth() {
        if let d = vnCalendar.date(byAdding: .month, value: 1, to: currentMonthDate) {
            currentMonthDate = d
            rebuildDays(for: d)
        }
    }

    // Các biến giữ tham chiếu sheet picker để dismiss
    private weak var pickerVC: UIViewController?
    private weak var datePicker: UIDatePicker?

    /// Mở DatePicker dạng sheet để chọn ngày/tháng/năm
    @objc private func monthTapped() {
        let vc = UIViewController(); vc.view.backgroundColor = .systemBackground

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "vi_VN")
        picker.calendar = vnCalendar
        picker.date = currentMonthDate

        // Thanh công cụ trên picker (Huỷ / Xong)
        let bar = UIToolbar()
        bar.items = [
            UIBarButtonItem(title: "Huỷ", style: .plain, target: self, action: #selector(cancelPick)),
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(donePick))
        ]

        // Layout picker + toolbar
        vc.view.addSubview(bar); vc.view.addSubview(picker)
        bar.translatesAutoresizingMaskIntoConstraints = false
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: vc.view.topAnchor),
            bar.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            picker.topAnchor.constraint(equalTo: bar.bottomAnchor),
            picker.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            picker.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor),
            picker.heightAnchor.constraint(equalToConstant: 216)
        ])

        // Lưu tham chiếu để đóng về sau
        pickerVC = vc; datePicker = picker

        // Hiển thị kiểu sheet
        if let sheet = vc.sheetPresentationController { sheet.detents = [.medium()] }
        present(vc, animated: true)
    }

    /// Đóng sheet picker (không áp dụng thay đổi)
    @objc private func cancelPick() { pickerVC?.dismiss(animated: true) }

    /// Nhận ngày người dùng chọn, chuyển tháng tương ứng, nạp lại lưới, chọn đúng ngày và hiển thị dữ liệu
    @objc private func donePick() {
        guard let p = datePicker else { return }

        // 1) Đọc ngày chọn
        let pickedDate = p.date
        let pickedDay  = vnCalendar.component(.day, from: pickedDate)

        // 2) Đặt con trỏ tháng theo ngày chọn
        currentMonthDate = startOfMonth(pickedDate)

        // 3) Dựng lại lưới + tải markers
        rebuildDays(for: currentMonthDate)

        // 4) Chọn đúng ngày và hiển thị dữ liệu tương ứng
        selectedDay = pickedDay
        showDay(pickedDay)

        // 5) Đảm bảo highlight đúng cell đã chọn
        if let idx = days.firstIndex(where: { $0 == pickedDay }) {
            let ip = IndexPath(item: idx, section: 0)
            ui.collectionView.reloadData()
            ui.collectionView.scrollToItem(at: ip, at: .centeredVertically, animated: false)
        }

        // 6) Đóng sheet
        cancelPick()
    }

    // MARK: - UICollectionView (lưới lịch)

    /// Số ô = tổng phần tử ma trận `days`
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { days.count }

    /// Cấu hình từng ô ngày: số ngày, màu thứ bảy/CN, mini số thu/chi, trạng thái chọn
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: DayButtonCell.reuseID, for: indexPath) as! DayButtonCell
        let col = indexPath.item % 7

        if let d = days[indexPath.item] {
            // Ô hợp lệ trong tháng
            cell.button.isEnabled = true
            cell.button.setTitle("\(d)", for: .normal)
            let color: UIColor = (col == 5) ? .systemBlue : (col == 6 ? .systemOrange : .label) // T7 xanh, CN cam
            cell.button.setTitleColor(color, for: .normal)

            // Gán tag để biết ngày khi bấm
            cell.button.tag = d
            cell.button.removeTarget(nil, action: nil, for: .allEvents)
            cell.button.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)

            // Highlight nếu đang chọn
            cell.applySelection(d == selectedDay)

            // Mini text thu/chi (nếu có dữ liệu)
            if let s = monthMarkers[d] { cell.setMini(income: s.income, expense: s.expense) }
            else { cell.setMini(income: nil, expense: nil) }
        } else {
            // Ô đệm ngoài tháng
            cell.button.isEnabled = false
            cell.button.setTitle("", for: .normal)
            cell.applySelection(false)
            cell.setMini(income: nil, expense: nil)
        }
        return cell
    }

    /// Khi bấm một ngày trong lịch: cập nhật highlight ô cũ/mới và nạp dữ liệu ngày
    @objc private func dayTapped(_ sender: UIButton) {
        let newDay = sender.tag
        var reload: [IndexPath] = []

        // Tìm indexPath của ô cũ để reload bỏ highlight
        if let old = selectedDay, let oldIdx = days.firstIndex(where: { $0 == old }) {
            reload.append(IndexPath(item: oldIdx, section: 0))
        }
        // Tìm indexPath của ô mới để reload highlight
        if let newIdx = days.firstIndex(where: { $0 == newDay }) {
            reload.append(IndexPath(item: newIdx, section: 0))
        }

        // Nạp dữ liệu ngày mới
        showDay(newDay)

        // Reload tối thiểu 2 ô (cũ/mới) cho mượt
        if reload.isEmpty { ui.collectionView.reloadData() }
        else { ui.collectionView.reloadItems(at: reload) }
    }

    // MARK: - UITableView (danh sách giao dịch)

    /// Số dòng list = số giao dịch trong ngày đã chọn
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { entries.count }

    /// Cấu hình cell danh sách: icon, tên danh mục, số tiền (màu xanh nếu thu)
    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let e = entries[indexPath.row]
        let cell = tv.dequeueReusableCell(withIdentifier: EntryCell.reuseID, for: indexPath) as! EntryCell
        cell.configure(iconName: e.iconName,
                       iconColor: e.iconColor,
                       title: e.title,
                       amount: money(e.amount),
                       amountColor: (e.kind == .income) ? .systemBlue : .label)
        cell.selectionStyle = .none
        return cell
    }
}
