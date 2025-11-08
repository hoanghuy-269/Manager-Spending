//
//  CustomSegmentedControl.swift
//  Spending-Manager
//
//  Created by  User on 06/11/2025.
//

import UIKit

class CustomSegmentedControl: UISegmentedControl {
    required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        private func setup() {
            // Màu chữ trắng cho cả hai trạng thái
            let whiteText = [NSAttributedString.Key.foregroundColor: UIColor.white]
            setTitleTextAttributes(whiteText, for: .normal)
            setTitleTextAttributes(whiteText, for: .selected)
        }
}
