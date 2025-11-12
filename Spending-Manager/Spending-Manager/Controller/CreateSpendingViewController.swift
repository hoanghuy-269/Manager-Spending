import UIKit

class CreateSpendingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - IBOutlet
    
    //view chi tieu
    @IBOutlet weak var viewThuNhap: UIView!
    @IBOutlet weak var collectionThuNhap: UICollectionView!
    @IBOutlet weak var tienThuNhap: UITextField!
    @IBOutlet weak var ghiChuThuNhap: UITextField!
    @IBOutlet weak var thuNhapButton: UIButton!
    @IBOutlet weak var ngayThemThuNhap: UIDatePicker!
    @IBOutlet weak var increaseDayInCome: UIImageView!
    @IBOutlet weak var decreaseDayInCome: UIImageView!
    
    //view thu nhap
    @IBOutlet weak var viewChiTieu: UIView!
    @IBOutlet weak var collectionChiTieu: UICollectionView!
    @IBOutlet weak var tienChiTieu: UITextField!
    @IBOutlet weak var ghiChuChiTieu: UITextField!
    @IBOutlet weak var chiTieuButton: UIButton!
    @IBOutlet weak var ngayThemChiTieu: UIDatePicker!
    
    @IBOutlet weak var increaseDaySpending: UIImageView!
    @IBOutlet weak var decreaseDaySpending: UIImageView!
    
    let dbQueue = DispatchQueue(label: "com.spendingmanager.dbQueue")

    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var selectedCategoryLabel: UILabel!

    @IBOutlet weak var soDu: UILabel!
    
    // MARK: - Data
    private var categoriesChiTieu: [Category] = []
    private var categoriesThuNhap: [Category] = []
    private let db = AppDatabase.shared
    var selectedIndexPath: IndexPath?
    var onCategoryAdded: (() -> Void)?
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        
        let db = AppDatabase.shared
                db.insertSampleTransactions()
                let trans = db.getAllTransactions()
                //Test
                for t in trans{
                    print(t.date)
                }
        setupCollectionViews()
        loadCategories()
        updateView(for: segmented.selectedSegmentIndex)
        setupDateGestureRecognizers()
        ngayThemThuNhap.locale = Locale(identifier: "vi_VN")
            ngayThemChiTieu.locale = Locale(identifier: "vi_VN")
        
        ngayThemThuNhap.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        ngayThemChiTieu.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)

        dbQueue.async {
            let allTransactions = self.db.getAllTransactions()
            let total = allTransactions.reduce(0.0) { sum, tx in
                sum + (tx.transactionTypeId == TransactionTypeId.thuNhap.rawValue ? tx.amount : -tx.amount)
            }
            DispatchQueue.main.async {
                self.updateSoDu(by: total)
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)        // Cập nhật label
    }
    private func setupDateGestureRecognizers() {
        // Thu nhập
        increaseDayInCome.isUserInteractionEnabled = true
        decreaseDayInCome.isUserInteractionEnabled = true
        increaseDayInCome.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(increaseDay(_:))))
        decreaseDayInCome.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(increaseDay(_:))))
        
        // Chi tiêu
        increaseDaySpending.isUserInteractionEnabled = true
        decreaseDaySpending.isUserInteractionEnabled = true
        increaseDaySpending.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(increaseDay(_:))))
        decreaseDaySpending.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(increaseDay(_:))))
    }
    // MARK: - Setup
    private func setupCollectionViews() {
        // Chi tiêu
        collectionChiTieu.delegate = self
        collectionChiTieu.dataSource = self
        collectionChiTieu.register(InComeCollectionViewCell.self, forCellWithReuseIdentifier: "InComeCollectionViewCell")
        // Thu nhập
        collectionThuNhap.delegate = self
        collectionThuNhap.dataSource = self
        collectionThuNhap.register(InComeCollectionViewCell.self, forCellWithReuseIdentifier: "InComeCollectionViewCell")
        // Layout
        if let layout1 = collectionChiTieu.collectionViewLayout as? UICollectionViewFlowLayout {
            layout1.minimumLineSpacing = 12
            layout1.minimumInteritemSpacing = 12
        }
        if let layout2 = collectionThuNhap.collectionViewLayout as? UICollectionViewFlowLayout {
            layout2.minimumLineSpacing = 12
            layout2.minimumInteritemSpacing = 12
        }
    }
    
    // MARK: - Load data
    private func loadCategories() {
        dbQueue.async {
            let chiTieu = AppDatabase.shared.getCategoriesByTransactionTypeId(TransactionTypeId.chiTieu.rawValue)
            let thuNhap = AppDatabase.shared.getCategoriesByTransactionTypeId(TransactionTypeId.thuNhap.rawValue)

            DispatchQueue.main.async {
                self.categoriesChiTieu = chiTieu
                self.categoriesThuNhap = thuNhap
                self.collectionChiTieu.reloadData()
                self.collectionThuNhap.reloadData()
            }
        }
    }

    
    // MARK: - Segment
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateView(for: sender.selectedSegmentIndex)
    }
    
    private func updateView(for index: Int) {
        viewChiTieu.isHidden = index != 0
        viewThuNhap.isHidden = index != 1
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectionChiTieu {
            return categoriesChiTieu.count + 1
        } else {
            return categoriesThuNhap.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InComeCollectionViewCell", for: indexPath) as! InComeCollectionViewCell
        
        if collectionView == collectionChiTieu {
            if indexPath.item < categoriesChiTieu.count {
                cell.configure(with: categoriesChiTieu[indexPath.item])
            } else {
                configureEditCell(cell)
            }
        } else {
            if indexPath.item < categoriesThuNhap.count {
                cell.configure(with: categoriesThuNhap[indexPath.item])
            } else {
                configureEditCell(cell)
            }
        }
        
        // Đổi màu nền dựa vào cell đang chọn
        if selectedIndexPath == indexPath {
            cell.contentView.backgroundColor = UIColor.systemYellow
        } else {
            cell.contentView.backgroundColor = UIColor.systemGray6
        }
        
        return cell
    }
    
    
    private func configureEditCell(_ cell: InComeCollectionViewCell) {
        cell.iconImageView.image = UIImage(systemName: "pencil.circle")
        cell.iconImageView.tintColor = UIColor.systemBlue
        cell.titleLabel.text = "Chỉnh sửa"
    }

    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Lưu cell cũ để đổi màu nền về mặc định
        let previousIndexPath = selectedIndexPath
        selectedIndexPath = indexPath
        
        // Xử lý logic chọn category
        if collectionView == collectionChiTieu {
            if indexPath.item == categoriesChiTieu.count {
                pushChiTieuCategories()
                print("Tap")
            }
        } else {
            if indexPath.item == categoriesThuNhap.count {
                pushThuNhapCategories()
            }
        }
        
        // Cập nhật màu nền: chỉ reload cell cũ và cell mới
        var indexPathsToReload = [indexPath]
        if let previous = previousIndexPath, previous != indexPath {
            indexPathsToReload.append(previous)
        }
        collectionView.reloadItems(at: indexPathsToReload)
    }
    
    
    
    private func pushChiTieuCategories() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SpendingCategoriesTableViewController") as? SpendingCategoriesTableViewController {
            vc.onCategoryAdded = { [weak self] in
                        self?.loadCategories()
                    }
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func pushThuNhapCategories() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "InComeCategoriesTableViewController") as? InComeCategoriesTableViewController {
//            vc.onCategoryAdded = { [weak self] in
//                        self?.loadCategories() // reload collection view ngay khi thêm xong
//                    }
            navigationController?.pushViewController(vc, animated: true)
        }
    }


    
    //MARK: XU LY NUT THEM THU CHI
    @IBAction func thuNhapButtonTapped(_ sender: UIButton) {
        guard let amountText = tienThuNhap.text, !amountText.isEmpty,
                  let amount = Double(amountText.replacingOccurrences(of: ",", with: "")),
                  let indexPath = selectedIndexPath,
                  indexPath.item < categoriesThuNhap.count else {
                showSnackbar(message: "Vui lòng nhập dữ liệu hợp lệ")
                return
            }

            let category = categoriesThuNhap[indexPath.item]
            guard let categoryId = category.id else { return showSnackbar(message: "Category chưa có ID") }
            let transaction = Transaction(
                amount: amount,
                categoryId: categoryId,
                transactionTypeId: TransactionTypeId.thuNhap.rawValue,
                note: ghiChuThuNhap.text,
                date: ngayThemThuNhap.date
            )

            dbQueue.async {
                let success = self.db.insertTransaction(transaction)
                DispatchQueue.main.async {
                    if success {
                        self.updateSoDu(by: amount)
                        self.tienThuNhap.text = ""
                        self.ghiChuThuNhap.text = ""
                        self.selectedIndexPath = nil
                        self.collectionThuNhap.reloadData()
                        self.showSnackbar(message: "Thêm thu nhập thành công")
                    }
                }
            }
    }

    @IBAction func chiTieuButtonTapped(_ sender: UIButton) {
        guard let amountText = tienChiTieu.text, !amountText.isEmpty,
                  let amount = Double(amountText.replacingOccurrences(of: ",", with: "")),
                  let indexPath = selectedIndexPath,
                  indexPath.item < categoriesChiTieu.count else {
                showSnackbar(message: "Vui lòng nhập dữ liệu hợp lệ")
                return
            }

            let category = categoriesChiTieu[indexPath.item]
            guard let categoryId = category.id else { return showSnackbar(message: "Category chưa có ID") }
            let transaction = Transaction(
                amount: amount,
                categoryId: categoryId,
                transactionTypeId: TransactionTypeId.chiTieu.rawValue,
                note: ghiChuChiTieu.text,
                date: ngayThemChiTieu.date
            )

            dbQueue.async {
                let success = self.db.insertTransaction(transaction)
                DispatchQueue.main.async {
                    if success {
                        self.updateSoDu(by: -amount)
                        self.tienChiTieu.text = ""
                        self.ghiChuChiTieu.text = ""
                        self.selectedIndexPath = nil
                        self.collectionChiTieu.reloadData()
                        self.showSnackbar(message: "Thêm chi tiêu thành công ")
                    }
                }
            }
    }

    // MARK: - Cập nhật số dư có định dạng
    private func updateSoDu(by amountChange: Double) {
        guard let currentSoDuText = soDu.text else { return }

        // Lấy phần số từ chuỗi "1,000,000 VNĐ"
        let numericPart = currentSoDuText
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        let currentSoDu = Double(numericPart) ?? 0

        // Tính số dư mới
        let updatedSoDu = currentSoDu + amountChange

        // Định dạng lại
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formattedSoDu = formatter.string(from: NSNumber(value: updatedSoDu)) ?? "\(updatedSoDu)"

        soDu.text = "\(formattedSoDu) VNĐ"
    }

    //MARK: Tăng giảm ngày
    @objc private func increaseDay(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view else { return }
        
        let datePicker: UIDatePicker
        
        switch imageView {
        case increaseDayInCome, decreaseDayInCome:
            datePicker = ngayThemThuNhap
        case increaseDaySpending, decreaseDaySpending:
            datePicker = ngayThemChiTieu
        default:
            return
        }
        
        let currentDate = datePicker.date
        let value = (imageView == increaseDayInCome || imageView == increaseDaySpending) ? 1 : -1
        
        if let newDate = Calendar.current.date(byAdding: .day, value: value, to: currentDate) {
            datePicker.setDate(newDate, animated: true)
        }
    }

    // MARK: - Hiển thị Snackbar
    private func showSnackbar(message: String, duration: Double = 2.0) {
        let snackbarHeight: CGFloat = 50
        let safeAreaBottom = view.safeAreaInsets.bottom
        let snackbar = UILabel(frame: CGRect(x: 16,
                                             y: view.frame.height - snackbarHeight - 16 - safeAreaBottom,
                                             width: view.frame.width - 32,
                                             height: snackbarHeight))
        snackbar.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        snackbar.textColor = .white
        snackbar.textAlignment = .center
        snackbar.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        snackbar.text = message
        snackbar.alpha = 0
        snackbar.layer.cornerRadius = 8
        snackbar.clipsToBounds = true
        snackbar.numberOfLines = 2

        view.addSubview(snackbar)
        view.bringSubviewToFront(snackbar) // đảm bảo hiển thị trên cùng

        UIView.animate(withDuration: 0.3, animations: {
            snackbar.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                snackbar.alpha = 0
            }) { _ in
                snackbar.removeFromSuperview()
            }
        }
    }


    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = 4
        let spacing: CGFloat = 8
        let sectionInsets: CGFloat = 16
        
        let totalSpacing = (itemsPerRow - 1) * spacing + sectionInsets * 2
        let width = (collectionView.bounds.width - totalSpacing) / itemsPerRow
        
        return CGSize(width: width, height: width * 1.1)
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCategories()
    }

}
