//
//  TransactionCell.swift
//  Spending-Manager
//
//  Created by  User on 09.11.2025.
//

import Foundation
import UIKit

import UIKit

class TransactionCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    // Method để configure cell
    func configure(with transaction: Transaction, categoryName: String) {
        // Format số tiền
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedAmount = formatter.string(from: NSNumber(value: transaction.amount)) ?? "\(transaction.amount)"
        amountLabel.text = "\(formattedAmount) đ"
    }
}
