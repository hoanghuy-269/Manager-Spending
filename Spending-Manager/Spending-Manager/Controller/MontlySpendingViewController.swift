//
//  MontlySpendingViewController.swift
//  Spending-Manager
//

import UIKit

final class MontlySpendingViewController: UIViewController,
    UICollectionViewDataSource, UICollectionViewDelegate,
    UITableViewDataSource, UITableViewDelegate {

    private var ui: CalendarScreenInterface!

    // Lưới ngày
    private var days: [Int?] = []
    private var currentMonthDate = Date()
    private var selectedDay: Int? = nil

    // Dữ liệu
    private var monthMarkers: [Int: (income: Int, expense: Int)] = [:]
    private var entries: [EntryItem] = []

    // MARK: Lifecycle
    override func loadView() {
        ui = CalendarScreenInterface()
        view = ui
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ui.collectionView.dataSource = self
        ui.collectionView.delegate = self
        ui.tableView.dataSource = self
        ui.tableView.delegate = self
/*
        // 💡 Seed dữ liệu mẫu khi DB trống (chỉ Debug)
        #if DEBUG
        if AppDatabase.shared.getAllTransactions().isEmpty {
            AppDatabase.shared.insertSampleTransactions()
        }
        #endif
*/
        // Khởi đầu = tháng hiện tại
        currentMonthDate = Date()
        rebuildDays(for: currentMonthDate)

        // Chọn mặc định = hôm nay (nếu thuộc tháng đang xem)
        let today = Date()
        let compMonth = vnCalendar.component(.month, from: today)
        let compYear  = vnCalendar.component(.year,  from: today)
        if vnCalendar.component(.month, from: currentMonthDate) == compMonth &&
            vnCalendar.component(.year, from: currentMonthDate) == compYear {
            let d = vnCalendar.component(.day, from: today)
            if let _ = days.firstIndex(where: { $0 == d }) { showDay(d) }
        }

        // Điều hướng tháng
        ui.prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        ui.nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        ui.monthLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(monthTapped)))
    }

    // MARK: Calendar helpers (vi_VN)
    private var vnCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "vi_VN")
        c.firstWeekday = 2
        return c
    }
    private func startOfMonth(_ d: Date) -> Date {
        vnCalendar.date(from: vnCalendar.dateComponents([.year,.month], from: d))!
    }
    private func daysInMonth(_ d: Date) -> Int {
        vnCalendar.range(of: .day, in: .month, for: startOfMonth(d))!.count
    }
    private func titleMonth(_ d: Date) -> String {
        let m = String(format: "%02d", vnCalendar.component(.month, from: d))
        let y = vnCalendar.component(.year, from: d)
        return "\(m)/\(y)"
    }
    private func weekdayShort(_ d: Date) -> String {
        ["CN","T.2","T.3","T.4","T.5","T.6","T.7"][vnCalendar.component(.weekday, from: d)-1]
    }
    private func money(_ v: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.groupingSeparator = "."
        return (f.string(from: NSNumber(value: v)) ?? "0") + "đ"
    }

    // MARK: Build days & markers tháng
    private func rebuildDays(for date: Date) {
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

        // markers tháng từ DB
        let y = vnCalendar.component(.year, from: date)
        let m = vnCalendar.component(.month, from: date)
        monthMarkers = AppDatabase.shared.getMonthMarkers(year: y, month: m)

        selectedDay = nil
        ui.setMonthTitle(titleMonth(date))
        ui.collectionView.reloadData()

        // reset summary/list
        entries = []
        ui.setSummary(income: "0đ", expense: "0đ", total: "0đ")
        ui.setListHeader(left: "", right: "")
        ui.tableView.reloadData()
    }

    // MARK: Đổ dữ liệu NGÀY
    private func showDay(_ day: Int) {
        guard day >= 1 else { return }
        selectedDay = day

        var comps = vnCalendar.dateComponents([.year,.month], from: currentMonthDate)
        comps.day = day
        let date = vnCalendar.date(from: comps)!

        // lấy tổng hợp 1 ngày từ DB
        let sum = AppDatabase.shared.getDaySummary(for: date)
        let total = sum.income - sum.expense

        ui.setSummary(income: money(sum.income),
                      expense: money(sum.expense),
                      total:   money(total))

        // list giao dịch ngày
        entries = sum.entries

        // header list (trái: dd/MM (Thứ...), phải: tổng)
        let df = DateFormatter(); df.locale = Locale(identifier: "vi_VN"); df.dateFormat = "dd/MM"
        ui.setListHeader(left: "\(df.string(from: date)) (\(weekdayShort(date)))",
                         right: money(total))

        // cập nhật markers (để mini số trong ô ngày phản ánh ngay khi chọn)
        monthMarkers[day] = (sum.income, sum.expense)

        ui.tableView.reloadData()
        ui.collectionView.reloadData()
    }

    // MARK: Month nav & picker
    @objc private func prevMonth() {
        if let d = vnCalendar.date(byAdding: .month, value: -1, to: currentMonthDate) {
            currentMonthDate = d; rebuildDays(for: d)
        }
    }
    @objc private func nextMonth() {
        if let d = vnCalendar.date(byAdding: .month, value: 1, to: currentMonthDate) {
            currentMonthDate = d; rebuildDays(for: d)
        }
    }

    private weak var pickerVC: UIViewController?
    private weak var datePicker: UIDatePicker?

    @objc private func monthTapped() {
        let vc = UIViewController(); vc.view.backgroundColor = .systemBackground
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "vi_VN")
        picker.calendar = vnCalendar
        picker.date = currentMonthDate

        let bar = UIToolbar()
        bar.items = [
            UIBarButtonItem(title: "Huỷ", style: .plain, target: self, action: #selector(cancelPick)),
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(donePick))
        ]
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
        pickerVC = vc; datePicker = picker
        if let sheet = vc.sheetPresentationController { sheet.detents = [.medium()] }
        present(vc, animated: true)
    }
    @objc private func cancelPick() { pickerVC?.dismiss(animated: true) }
    @objc private func donePick() {
        guard let p = datePicker else { return }
        currentMonthDate = startOfMonth(p.date)
        rebuildDays(for: currentMonthDate)
        cancelPick()
    }

    // MARK: Collection (calendar)
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { days.count }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: DayButtonCell.reuseID, for: indexPath) as! DayButtonCell
        let col = indexPath.item % 7

        if let d = days[indexPath.item] {
            cell.button.isEnabled = true
            cell.button.setTitle("\(d)", for: .normal)
            let color: UIColor = (col == 5) ? .systemBlue : (col == 6 ? .systemOrange : .label)
            cell.button.setTitleColor(color, for: .normal)
            cell.button.tag = d
            cell.button.removeTarget(nil, action: nil, for: .allEvents)
            cell.button.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
            cell.applySelection(d == selectedDay)

            if let s = monthMarkers[d] { cell.setMini(income: s.income, expense: s.expense) }
            else { cell.setMini(income: nil, expense: nil) }
        } else {
            cell.button.isEnabled = false
            cell.button.setTitle("", for: .normal)
            cell.applySelection(false)
            cell.setMini(income: nil, expense: nil)
        }
        return cell
    }

    @objc private func dayTapped(_ sender: UIButton) {
        let newDay = sender.tag
        var reload: [IndexPath] = []
        if let old = selectedDay, let oldIdx = days.firstIndex(where: { $0 == old }) { reload.append(IndexPath(item: oldIdx, section: 0)) }
        if let newIdx = days.firstIndex(where: { $0 == newDay }) { reload.append(IndexPath(item: newIdx, section: 0)) }
        showDay(newDay)
        if reload.isEmpty { ui.collectionView.reloadData() } else { ui.collectionView.reloadItems(at: reload) }
    }

    // MARK: Table (list)
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { entries.count }

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
