//
//  InComeCategoriesTableViewController.swift
//  Spending-Manager
//
//  Created by  User on 10/11/2025.
//

import UIKit

class InComeCategoriesTableViewController: UITableViewController {

    var categories : [Category] = []
    var onCategoryAdded: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        loadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        categories.count
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.title = "Danh Mục Thu Nhập"
        loadData()
    }
    
    @IBAction func onBack(_ sender: Any){
        navigationController?.popViewController(animated: true)}
    
    
    func loadData(){
        categories = AppDatabase.shared.getCategoriesByTransactionTypeId(TransactionTypeId.thuNhap.rawValue)
        tableView.reloadData()
    }
    
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InComeTableViewCell", for: indexPath) as! InComeTableViewCell

        let item = categories[indexPath.row]

        cell.nameCategory?.text = item.name
        if let iconString = item.icon {
            if let imageData = Data(base64Encoded: iconString),
               let image = UIImage(data: imageData) {
                // Trường hợp là ảnh từ thư viện
                cell.iconCategory.image = image
            } else {
                cell.iconCategory.image = UIImage(systemName: iconString)
            }
        } else {
            cell.iconCategory.image = UIImage(systemName: "photo") // ảnh mặc định
        }
        return cell
    }
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Xóa") { [weak self] action, view, completionHandler in
            self?.confirmDelete(at: indexPath)
            completionHandler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true // swipe full để xóa
        return configuration
    }
    private func confirmDelete(at indexPath: IndexPath) {
        let category = categories[indexPath.row]
        
        let alert = UIAlertController(title: "Xóa danh mục",
                                      message: "Bạn có chắc muốn xóa '\(category.name)' không?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            // Xóa trong database
            if let categoryId = category.id {
                let success = AppDatabase.shared.deleteCategory(withId: categoryId)
                if success {
                    self.categories.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                } else {
                    self.showSnackbar(message: "Xóa thất bại")
                }
            } else {
                self.showSnackbar(message: "Category chưa có ID, không thể xóa")
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if let destination = segue.destination as? AddComingViewController {
             destination.onCategoryAdded = { [weak self] in
                 self?.loadData()
                 self?.onCategoryAdded?()
                
             }
         }
     }
}
extension InComeCategoriesTableViewController {
    func showSnackbar(message: String, duration: Double = 2.0) {
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
        view.bringSubviewToFront(snackbar)

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
}


