//
//  AddComingViewController.swift
//  Spending-Manager
//
//  Created by  User on 12/11/2025.
//

import UIKit

class AddComingViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var nameCategory: UITextField!
    @IBOutlet weak var addCate: UIButton!
    @IBOutlet weak var cacel: UIButton!
    
    var transactionTypeId: Int = 2
        var selectedIconName: String?
    let db = AppDatabase.shared
    var onCategoryAdded: (() -> Void)?
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // Cho phép người dùng nhấn vào icon để chọn hình
            iconImage.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImage))
            iconImage.addGestureRecognizer(tapGesture)
            
            // Gán hành động cho nút
            addCate.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
            cacel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
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
            iconImage.image = UIImage(systemName: selectedIconName!)
        }
        
        // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            iconImage.image = editedImage
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            iconImage.image = originalImage
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

        // Tạo đối tượng category
        let category = Category(
            id: nil,
            name: name,
            transactionTypeId: transactionTypeId,
            icon: iconString
        )
        
        // Gọi hàm thêm danh mục vào DB
        if db.insertCategory(category) {
            showAlert(title: "Thành công", message: "Đã thêm danh mục mới!") {
                self.onCategoryAdded?()
                self.dismiss(animated: true)
            }
        } else {
            // Hiển thị lỗi cụ thể khi trùng tên
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
