//
//  AddSpendingViewController.swift
//  Spending-Manager
//
//  Created by  User on 11/11/2025.
//

import UIKit

class AddSpendingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var nameCategory: UITextField!
    @IBOutlet weak var addCategory: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var transactionTypeId: Int = 1
        var selectedIconName: String?
    let db = AppDatabase.shared
    var onCategoryAdded: (() -> Void)?
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // Cho phép người dùng nhấn vào icon để chọn hình
            icon.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
            icon.addGestureRecognizer(tapGesture)
            
            // Gán hành động cho nút
            addCategory.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
            cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        }
        
        // MARK: - Chọn ảnh hoặc icon
        @objc func selectImage() {
            let alert = UIAlertController(title: "Chọn hình ảnh", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Chọn từ thư viện", style: .default, handler: { _ in
                self.openPhotoLibrary()
            }))
            alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
        
        func openPhotoLibrary() {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            present(picker, animated: true)
        }
        
        func openIconPicker() {
            // Tạm thời chọn icon mặc định (bạn có thể mở popup để chọn icon sau)
            selectedIconName = "cart.fill"
            icon.image = UIImage(systemName: selectedIconName!)
        }
        
        // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            icon.image = editedImage
            selectedImage = editedImage  
        } else if let originalImage = info[.originalImage] as? UIImage {
            icon.image = originalImage
            selectedImage = originalImage
        }
        picker.dismiss(animated: true)
    }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        // MARK: - Thêm danh mục
    @IBAction func addCategoryTapped(_ sender: UIButton) {
        guard let name = nameCategory.text, !name.isEmpty else {
            showAlert(title: "Lỗi", message: "Vui lòng nhập tên danh mục")
            return
        }
        
        var iconString = ""
        if let selectedImage = selectedImage,
           let data = selectedImage.pngData() {
            iconString = data.base64EncodedString()
        } else {
            iconString = "cart"
        }

        let category = Category(
            id: nil,
            name: name,
            transactionTypeId: transactionTypeId,
            icon: iconString
        )
        
        if db.insertCategory(category) {
            showAlert(title: "Thành công", message: "Đã thêm danh mục mới!") {
                self.onCategoryAdded?()
                self.dismiss(animated: true)
            }
        } else {
            showAlert(title: "Lỗi", message: "Tên danh mục đã tồn tại, vui lòng chọn tên khác.")
        }
    }


    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

        
        // MARK: - Alert helper
        func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
            present(alert, animated: true)
        }
}
