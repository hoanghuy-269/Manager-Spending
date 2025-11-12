import UIKit

class transactionViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    
    func configure(with transaction: Transaction, category: Category?) {
        nameLabel.text = category?.name  ?? ""
        
        // Format số tiền
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedAmount = formatter.string(from: NSNumber(value: transaction.amount)) ?? "\(transaction.amount)"
        amountLabel.text = "\(formattedAmount) đ"
        
        // Màu theo loại giao dịch
        if transaction.transactionTypeId == 2 { // Chi tiêu
            amountLabel.textColor = .systemRed
        } else { // Thu nhập
            amountLabel.textColor = .systemGreen
        }
        // ✅ Hiển thị icon
        if let iconName = category?.icon, !iconName.isEmpty {
            iconImageView.image = UIImage(systemName: iconName)
            iconImageView.tintColor = transaction.transactionTypeId == 2 ? .systemRed : .systemGreen
        } else {
            let defaultIcon = transaction.transactionTypeId == 2 ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
            iconImageView.image = UIImage(systemName: defaultIcon)
            iconImageView.tintColor = transaction.transactionTypeId == 2 ? .systemRed : .systemGreen
        }
        
        // Bo tròn icon
        iconImageView.layer.cornerRadius = 20
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFit
    }
}
