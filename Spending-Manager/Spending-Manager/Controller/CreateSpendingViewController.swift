//
//  CreateSpendingViewController.swift
//  Spending-Manager
//
//  Created by  User on 04/11/2025.
//

import UIKit

class CreateSpendingViewController: UIViewController {
    
    @IBOutlet weak var viewThuNhap: UIView!
    
    @IBOutlet weak var viewChiTieu: UIView!
    
    
    @IBOutlet weak var segmented: CustomSegmentedControl!
    
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateView(for: sender.selectedSegmentIndex)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView(for: segmented.selectedSegmentIndex)
        
        // Do any additional setup after loading the view.
    }
    
    private func updateView(for index: Int) {
        if index == 0 {
            // Chuyen view chi tieu
            viewChiTieu.isHidden = false
            viewThuNhap.isHidden = true
        } else {
            // Chuyen view thu nhap
            viewChiTieu.isHidden = true
            viewThuNhap.isHidden = false
        }
    }
}
