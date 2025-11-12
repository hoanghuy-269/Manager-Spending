//
//  InComeTableViewCell.swift
//  Spending-Manager
//
//  Created by  User on 11/11/2025.
//

import UIKit

class InComeTableViewCell: UITableViewCell {

    @IBOutlet weak var iconCategory: UIImageView!
   
    @IBOutlet weak var nameCategory: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        iconCategory.translatesAutoresizingMaskIntoConstraints = false
            iconCategory.widthAnchor.constraint(equalToConstant: 70).isActive = true
            iconCategory.heightAnchor.constraint(equalToConstant: 50).isActive = true
        iconCategory.layer.borderWidth = 1.0
            iconCategory.layer.borderColor = UIColor.gray.cgColor
            iconCategory.layer.cornerRadius = 5.0
            iconCategory.clipsToBounds = true
        self.layer.borderWidth = 1.0
            self.layer.borderColor = UIColor.gray.cgColor
            self.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }


}
