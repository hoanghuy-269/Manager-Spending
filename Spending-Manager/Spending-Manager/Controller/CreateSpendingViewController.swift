import UIKit

class CreateSpendingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - IBOutlet
    @IBOutlet weak var viewThuNhap: UIView!
    @IBOutlet weak var viewChiTieu: UIView!
    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var selectedCategoryLabel: UILabel!
    
    @IBOutlet weak var collectionChiTieu: UICollectionView!
    @IBOutlet weak var collectionThuNhap: UICollectionView!
    
    // MARK: - Data
    private var categoriesChiTieu: [Category] = []
    private var categoriesThuNhap: [Category] = []
    private let db = AppDatabase.shared
    
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
        categoriesChiTieu = db.getCategoriesByTransactionTypeId(TransactionTypeId.chiTieu.rawValue)
        for category in categoriesChiTieu {
            print("Chi tieu category: \(category.icon)")
        }
        categoriesThuNhap = db.getCategoriesByTransactionTypeId(TransactionTypeId.thuNhap.rawValue)
        
        collectionChiTieu.reloadData()
        collectionThuNhap.reloadData()
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
            return categoriesChiTieu.count + 1 // +1 cell chỉnh sửa
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
        
        return cell
    }
    
    private func configureEditCell(_ cell: InComeCollectionViewCell) {
        cell.iconImageView.image = UIImage(systemName: "pencil.circle")
        cell.titleLabel.text = "Chỉnh sửa"
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collectionChiTieu {
            if indexPath.item == categoriesChiTieu.count {
                pushAllCategories()
            } else {
                selectedCategoryLabel.text = categoriesChiTieu[indexPath.item].name
            }
        } else {
            if indexPath.item == categoriesThuNhap.count {
                pushAllCategories()
            } else {
                selectedCategoryLabel.text = categoriesThuNhap[indexPath.item].name
            }
        }
    }
    
    private func pushAllCategories() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        /*
         if let vc = storyboard.instantiateViewController(withIdentifier: "AllCategoriesViewController") as? AllCategoriesViewController {
         self.navigationController?.pushViewController(vc, animated: true)
         }
         */
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
}
