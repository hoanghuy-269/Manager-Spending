//
//  CalendarScreenInterface.swift
//  Spending-Manager
//

import UIKit

/// View thuần-code cho màn hình Lịch.
/// Chịu trách nhiệm dựng UI (header, thanh tháng, thứ trong tuần, lưới lịch,
/// 3 ô tổng hợp, danh sách giao dịch) và cung cấp vài API nhỏ để VC cập nhật.
final class CalendarScreenInterface: UIView {

    // MARK: - Expose to VC (ViewController sẽ gắn datasource/delegate)
    let collectionView: UICollectionView          // Lưới lịch (7 cột x 5-6 hàng)
    let tableView = UITableView(frame: .zero, style: .plain) // Danh sách giao dịch ngày

    let prevButton = UIButton(type: .system)      // Nút chuyển tháng về trước
    let nextButton = UIButton(type: .system)      // Nút chuyển tháng về sau
    let monthLabel = UILabel()                    // Nhãn hiển thị "MM/YYYY" (tap để mở date picker)

    /// VC gọi để đổi tiêu đề tháng
    func setMonthTitle(_ text: String) { monthLabel.text = text }

    /// VC gọi để cập nhật 3 ô tổng hợp
    func setSummary(income: String, expense: String, total: String) {
        incomeValue.text = income; expenseValue.text = expense; totalValue.text = total
    }

    /// Header list (bên trái: "dd/MM (Thứ)", bên phải: "Tổng tiền của ngày")
    func setListHeader(left: String, right: String) {
        headerLeft.text = left; headerRight.text = right
        // Phải set lại frame tableHeaderView để chiều cao cập nhật
        if let h = tableView.tableHeaderView {
            var f = h.frame; f.size.height = 40; h.frame = f
            tableView.tableHeaderView = h
        }
    }

    // MARK: - Private UI thành phần
    private let titleLabel = UILabel()            // Tiêu đề "Lịch"
    private let weekdaysStack = UIStackView()     // Hàng hiển thị T.2..CN
    private var monthWrap = UIView()              // Vùng chứa thanh tháng (để định vị weekdays bám theo)

    // Nhóm 3 ô tổng hợp (Thu nhập / Chi tiêu / Tổng)
    private let incomeValue = UILabel()
    private let expenseValue = UILabel()
    private let totalValue = UILabel()
    private let summaryContainer = UIView()

    // Header cho danh sách giao dịch ngày
    private let headerLeft = UILabel()
    private let headerRight = UILabel()

    // Constraint động để điều chỉnh kích thước lưới lịch cho vừa 6 hàng, canh giữa
    private var calendarHeightC: NSLayoutConstraint?
    private var calendarWidthC: NSLayoutConstraint?

    // MARK: - Init

    override init(frame: CGRect) {
        // Chuẩn bị layout cho collectionView (ô vuông, không khoảng cách)
        let flow = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        flow.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flow)
        super.init(frame: frame)
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Dựng UI chính

    private func buildUI() {
        backgroundColor = .systemGroupedBackground
        setupHeaderTitle()        // "Lịch"
        setupMonthBar()           // thanh chuyển tháng + tiêu đề tháng
        setupWeekdays()           // T.2..CN
        setupCalendarCentered()   // lưới lịch – canh giữa màn hình
        setupSummary()            // 3 ô tổng hợp dưới lịch
        setupList()               // bảng danh sách giao dịch
    }

    /// Dòng chữ "Lịch" căn giữa theo màn hình
    private func setupHeaderTitle() {
        titleLabel.text = "Lịch"
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor) // căn giữa
        ])
    }

    /// Thanh chứa nút trái/phải và label "MM/YYYY"
    private func setupMonthBar() {
        let wrap = UIView()
        monthWrap = wrap
        wrap.backgroundColor = .secondarySystemBackground
        wrap.layer.cornerRadius = 12

        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)

        monthLabel.text = "11/2025"
        monthLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        monthLabel.textAlignment = .center
        monthLabel.layer.cornerRadius = 10
        monthLabel.layer.masksToBounds = true
        monthLabel.isUserInteractionEnabled = true   // để VC addGesture mở date picker

        let row = UIStackView(arrangedSubviews: [prevButton, monthLabel, nextButton])
        row.axis = .horizontal; row.alignment = .center; row.spacing = 12

        addSubview(wrap); wrap.addSubview(row)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            wrap.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            wrap.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            row.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -8)
        ])

        // Giữ nút không bị giãn
        prevButton.setContentHuggingPriority(.required, for: .horizontal)
        nextButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    /// Hàng thứ trong tuần (T.2..CN) – màu khác cho T.7 và CN
    private func setupWeekdays() {
        weekdaysStack.axis = .horizontal
        weekdaysStack.distribution = .fillEqually
        ["T.2","T.3","T.4","T.5","T.6","T.7","CN"].enumerated().forEach { i, t in
            let lb = UILabel()
            lb.text = t; lb.textAlignment = .center
            lb.font = .systemFont(ofSize: 12, weight: .semibold)
            lb.textColor = (i==6) ? .systemOrange : (i==5 ? .systemBlue : .secondaryLabel)
            weekdaysStack.addArrangedSubview(lb)
        }
        addSubview(weekdaysStack)
        weekdaysStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weekdaysStack.topAnchor.constraint(equalTo: monthWrap.bottomAnchor, constant: 8),
            weekdaysStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            weekdaysStack.widthAnchor.constraint(equalTo: widthAnchor, constant: -24), // chừa 12pt mỗi bên
            weekdaysStack.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    /// Lưới lịch canh GIỮA màn, kích thước tính động theo bề rộng (ô vuông, 7 cột).
    /// Chiều cao sẽ được set trong `updateCalendarHeight` để vừa 5–6 hàng (không thừa).
    private func setupCalendarCentered() {
        collectionView.backgroundColor = .white
        collectionView.layer.cornerRadius = 8
        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = UIColor.separator.cgColor
        collectionView.register(DayButtonCell.self, forCellWithReuseIdentifier: DayButtonCell.reuseID)

        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Tạo trước constraint width/height rồi giữ reference để cập nhật động.
        calendarWidthC  = collectionView.widthAnchor.constraint(equalToConstant: 320)
        calendarHeightC = collectionView.heightAnchor.constraint(equalToConstant: 320)
        calendarWidthC?.isActive = true
        calendarHeightC?.isActive = true

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: weekdaysStack.bottomAnchor, constant: 6),
            collectionView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    /// Khối 3 ô tổng hợp dưới lịch (chia đều 3 cột)
    private func setupSummary() {
        // Tạo 1 block (nhãn tiêu đề + giá trị)
        func makeBlock(_ title: String, _ value: UILabel, _ color: UIColor) -> UIStackView {
            let t = UILabel(); t.text = title; t.textColor = .secondaryLabel
            t.font = .systemFont(ofSize: 14, weight: .semibold)
            value.text = "0đ"; value.textColor = color
            value.font = .systemFont(ofSize: 18, weight: .bold)
            let v = UIStackView(arrangedSubviews: [t, value])
            v.axis = .vertical; v.alignment = .center; v.spacing = 2
            return v
        }
        let s1 = makeBlock("Thu nhập", incomeValue, .systemBlue)
        let s2 = makeBlock("Chi tiêu",  expenseValue, .systemOrange)
        let s3 = makeBlock("Tổng",      totalValue,   .label)

        let row = UIStackView(arrangedSubviews: [s1, s2, s3])
        row.axis = .horizontal; row.alignment = .center; row.distribution = .fillEqually

        summaryContainer.backgroundColor = .white
        summaryContainer.layer.cornerRadius = 12
        summaryContainer.layer.borderWidth = 1
        summaryContainer.layer.borderColor = UIColor.separator.cgColor

        addSubview(summaryContainer); summaryContainer.addSubview(row)
        summaryContainer.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            summaryContainer.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 12),
            summaryContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            summaryContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            summaryContainer.heightAnchor.constraint(equalToConstant: 72),

            row.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor),
            row.topAnchor.constraint(equalTo: summaryContainer.topAnchor),
            row.bottomAnchor.constraint(equalTo: summaryContainer.bottomAnchor)
        ])
    }

    /// Dựng bảng danh sách giao dịch + header (trái/phải)
    private func setupList() {
        headerLeft.font = .systemFont(ofSize: 15, weight: .semibold)
        headerRight.font = .systemFont(ofSize: 15, weight: .semibold)
        headerRight.textAlignment = .right

        let headerRow = UIStackView(arrangedSubviews: [headerLeft, UIView(), headerRight])
        headerRow.axis = .horizontal; headerRow.alignment = .center; headerRow.spacing = 8

        let header = UIView(); header.addSubview(headerRow)
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerRow.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            headerRow.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            headerRow.topAnchor.constraint(equalTo: header.topAnchor, constant: 6),
            headerRow.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -6)
        ])
        header.frame.size.height = 40
        tableView.tableHeaderView = header

        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorColor = .separator
        tableView.rowHeight = 56
        tableView.register(EntryCell.self, forCellReuseIdentifier: EntryCell.reuseID)
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = true

        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: summaryContainer.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Layout helpers (tính kích thước lưới)

    /// Tính lại kích thước lưới để luôn là 7 cột * N hàng, ô vuông, canh giữa,
    /// và **không thừa** khoảng trắng ở dưới.
    /// - Parameter rows: 6 (tháng có 6 hàng), 5 với một số tháng – nhưng ta đo theo contentSize để chính xác.
    func updateCalendarHeight(rows: Int) {
        guard let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        flow.sectionInset = .zero

        // Bề rộng có chừa tổng 24pt (12 mỗi bên) để ô không dính sát mép
        let screenW = bounds.width
        let safeHorizontalMargin: CGFloat = 24
        let maxGridW = max(0, screenW - safeHorizontalMargin)

        let scale = UIScreen.main.scale
        // Ô vuông = bề rộng chia 7, làm tròn theo pixel để nét
        let rawItemW = maxGridW / 7.0
        let itemW = floor(rawItemW * scale) / scale
        let itemH = itemW
        flow.itemSize = CGSize(width: itemW, height: itemH)

        // Cập nhật width thực của lưới để centerX
        let gridW = itemW * 7.0
        calendarWidthC?.constant = gridW

        // Invalidate để collectionView tính lại contentSize -> chiều cao chính xác
        flow.invalidateLayout()
        collectionView.layoutIfNeeded()
        let contentH = flow.collectionViewContentSize.height
        let finalH = ceil(contentH * scale) / scale
        calendarHeightC?.constant = finalH

        layoutIfNeeded()
    }

    /// Mỗi lần layout lại (xoay máy/đổi kích thước), cập nhật kích cỡ lưới + header list
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCalendarHeight(rows: 6)
        if let h = tableView.tableHeaderView {
            var f = h.frame; f.size.height = 40; h.frame = f
            tableView.tableHeaderView = h
        }
    }
}

// MARK: - Cells

/// Ô ngày trong lưới lịch: 1 nút hiển thị số ngày + 2 dòng mini cho thu/chi
final class DayButtonCell: UICollectionViewCell {
    static let reuseID = "DayButtonCell"

    let button = UIButton(type: .system) // tap để chọn ngày
    private let miniIncome = UILabel()   // số thu nhỏ
    private let miniExpense = UILabel()  // số chi nhỏ

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor

        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)

        miniIncome.font = .systemFont(ofSize: 10, weight: .semibold)
        miniIncome.textColor = .systemBlue
        miniIncome.textAlignment = .right

        miniExpense.font = .systemFont(ofSize: 10, weight: .semibold)
        miniExpense.textColor = .systemOrange
        miniExpense.textAlignment = .right

        // Sắp xếp: [nút ngày] trên, [thu nhỏ], [chi nhỏ] dưới
        let v = UIStackView(arrangedSubviews: [button, miniIncome, miniExpense])
        v.axis = .vertical; v.spacing = 2
        contentView.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            v.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            v.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Đổi nền nhẹ khi đang chọn
    func applySelection(_ selected: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.button.backgroundColor = selected ? UIColor.systemGray5 : .clear
        }
    }

    /// Hiển thị mini thu/chi (ẩn nếu bằng 0 hoặc nil)
    func setMini(income: Int?, expense: Int?) {
        let nf = NumberFormatter(); nf.numberStyle = .decimal; nf.groupingSeparator = "."
        miniIncome.text  = (income ?? 0) > 0 ? nf.string(from: NSNumber(value: income!)) : ""
        miniExpense.text = (expense ?? 0) > 0 ? nf.string(from: NSNumber(value: expense!)) : ""
    }
}

/// Cell danh sách giao dịch: icon + tên danh mục + số tiền
final class EntryCell: UITableViewCell {
    static let reuseID = "EntryCell"

    private let icon = UIImageView()     // SFSymbol theo danh mục
    private let titleLb = UILabel()      // Tên danh mục / ghi chú
    private let amountLb = UILabel()     // Số tiền (xanh nếu thu)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemGroupedBackground
        contentView.backgroundColor = .systemGroupedBackground

        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        titleLb.font = .systemFont(ofSize: 16, weight: .semibold)

        amountLb.font = .systemFont(ofSize: 16, weight: .semibold)
        amountLb.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [icon, titleLb, UIView(), amountLb])
        row.axis = .horizontal; row.alignment = .center; row.spacing = 12
        contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Cấu hình hiển thị một giao dịch
    func configure(iconName: String, iconColor: UIColor, title: String, amount: String, amountColor: UIColor) {
        icon.image = UIImage(systemName: iconName)
        icon.tintColor = iconColor
        titleLb.text = title
        amountLb.text = amount
        amountLb.textColor = amountColor
    }
}
