import UIKit

final class CalendarScreenInterface: UIView {

    // Expose cho VC
    let collectionView: UICollectionView
    let tableView = UITableView(frame: .zero, style: .plain)
    let prevButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)
    let monthLabel = UILabel()

    func setMonthTitle(_ text: String) { monthLabel.text = text }
    func setSummary(income: String, expense: String, total: String) {
        incomeLabel.text = income; expenseLabel.text = expense; totalLabel.text = total
    }
    func setListHeader(left: String, right: String) {
        leftHeaderLabel.text = left
        rightHeaderLabel.text = right
        if let h = tableView.tableHeaderView {
            var f = h.frame; f.size.height = 36; h.frame = f
            tableView.tableHeaderView = h
        }
    }

    // private UI
    private let incomeLabel = UILabel()
    private let expenseLabel = UILabel()
    private let totalLabel = UILabel()
    private let weekdaysStack = UIStackView()
    private let summaryContainer = UIView()
    private let leftHeaderLabel  = UILabel()
    private let rightHeaderLabel = UILabel()

    override init(frame: CGRect) {
        let flow = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flow)
        super.init(frame: frame)
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildUI() {
        backgroundColor = .systemGroupedBackground
        setupHeader()
        setupMonthBar()
        setupWeekdays()
        setupCalendar()
        setupSummary()
        setupList()
    }

    private func setupHeader() {
        let title = UILabel()
        title.text = "Lịch"
        title.font = .systemFont(ofSize: 28, weight: .semibold)
        let search = UIButton(type: .system)
        search.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        let bar = UIStackView(arrangedSubviews: [title, UIView(), search])
        bar.axis = .horizontal; bar.alignment = .center
        addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    private func setupMonthBar() {
        let wrap = UIView()
        wrap.backgroundColor = .secondarySystemBackground
        wrap.layer.cornerRadius = 12

        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)

        monthLabel.text = "11/2025"
        monthLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        monthLabel.textAlignment = .center
        monthLabel.backgroundColor = .secondarySystemBackground
        monthLabel.layer.cornerRadius = 10
        monthLabel.layer.masksToBounds = true
        monthLabel.isUserInteractionEnabled = true

        let row = UIStackView(arrangedSubviews: [prevButton, monthLabel, nextButton])
        row.axis = .horizontal; row.alignment = .center; row.spacing = 12

        addSubview(wrap); wrap.addSubview(row)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 48),
            wrap.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            wrap.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            row.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -8)
        ])
        prevButton.setContentHuggingPriority(.required, for: .horizontal)
        nextButton.setContentHuggingPriority(.required, for: .horizontal)
    }

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
            weekdaysStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 98),
            weekdaysStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            weekdaysStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            weekdaysStack.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupCalendar() {
        collectionView.backgroundColor = .white
        collectionView.layer.cornerRadius = 8
        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = UIColor.separator.cgColor
        collectionView.register(DayButtonCell.self, forCellWithReuseIdentifier: DayButtonCell.reuseID)

        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: weekdaysStack.bottomAnchor, constant: 6),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            collectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }

    private func setupSummary() {
        func block(_ title: String, _ value: UILabel, _ color: UIColor) -> UIStackView {
            let t = UILabel()
            t.text = title; t.textColor = .secondaryLabel
            t.font = .systemFont(ofSize: 14, weight: .semibold)
            value.text = "0đ"; value.textColor = color
            value.font = .systemFont(ofSize: 18, weight: .bold)
            let s = UIStackView(arrangedSubviews: [t, value])
            s.axis = .vertical; s.alignment = .center; s.spacing = 2
            return s
        }
        let s1 = block("Thu nhập", incomeLabel, .systemBlue)
        let s2 = block("Chi tiêu",  expenseLabel, .systemOrange)
        let s3 = block("Tổng",      totalLabel,   .label)

        let row = UIStackView(arrangedSubviews: [s1, s2, s3])
        row.axis = .horizontal; row.alignment = .center
        row.distribution = .fillEqually; row.spacing = 0

        summaryContainer.backgroundColor = .white
        summaryContainer.layer.cornerRadius = 12
        summaryContainer.layer.borderWidth = 1
        summaryContainer.layer.borderColor = UIColor.separator.cgColor
        summaryContainer.clipsToBounds = true

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

    private func setupList() {
        leftHeaderLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        leftHeaderLabel.textColor = .label
        rightHeaderLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        rightHeaderLabel.textAlignment = .right

        let header = UIView(); header.backgroundColor = .secondarySystemBackground
        let headerRow = UIStackView(arrangedSubviews: [leftHeaderLabel, UIView(), rightHeaderLabel])
        headerRow.axis = .horizontal; headerRow.alignment = .center; headerRow.spacing = 8
        header.addSubview(headerRow)
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerRow.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            headerRow.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            headerRow.topAnchor.constraint(equalTo: header.topAnchor),
            headerRow.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])
        header.frame.size.height = 36
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
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let w = collectionView.bounds.width
            flow.itemSize = CGSize(width: floor(w/7.0), height: 56)
        }
        if let h = tableView.tableHeaderView {
            var f = h.frame; f.size.height = 36; h.frame = f
            tableView.tableHeaderView = h
        }
    }
}

// MARK: - Cells
final class DayButtonCell: UICollectionViewCell {
    static let reuseID = "DayButtonCell"
    let button = UIButton(type: .system)
    private let miniIncome = UILabel()
    private let miniExpense = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.borderWidth = 1; layer.borderColor = UIColor.separator.cgColor

        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        miniIncome.font = .systemFont(ofSize: 10, weight: .semibold)
        miniIncome.textColor = .systemBlue; miniIncome.textAlignment = .right
        miniExpense.font = .systemFont(ofSize: 10, weight: .semibold)
        miniExpense.textColor = .systemOrange; miniExpense.textAlignment = .right

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

    func applySelection(_ selected: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.button.backgroundColor = selected ? UIColor.systemGray5 : .clear
        }
    }
    func setMini(income: Int?, expense: Int?) {
        let nf = NumberFormatter(); nf.numberStyle = .decimal; nf.groupingSeparator = "."
        miniIncome.text  = (income ?? 0) > 0 ? nf.string(from: NSNumber(value: income!)) : ""
        miniExpense.text = (expense ?? 0) > 0 ? nf.string(from: NSNumber(value: expense!)) : ""
    }
}

final class EntryCell: UITableViewCell {
    static let reuseID = "EntryCell"
    private let icon = UIImageView()
    private let titleLb = UILabel()
    private let amountLb = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .systemGroupedBackground
        contentView.backgroundColor = .systemGroupedBackground

        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)

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

    func configure(iconName: String, iconColor: UIColor, title: String, amount: String, amountColor: UIColor) {
        icon.image = UIImage(systemName: iconName)
        icon.tintColor = iconColor
        titleLb.text = title
        amountLb.text = amount
        amountLb.textColor = amountColor
    }
}
