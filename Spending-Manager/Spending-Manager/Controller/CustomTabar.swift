import UIKit

class CustomTaBar: UITabBarController, UITabBarControllerDelegate {
    private var shapeLayer: CAShapeLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabBarAppearance()
        addShapeForSelectedItem()
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear

        // 🔸 Thêm 2 dòng này:
        appearance.stackedLayoutAppearance.selected.iconColor = .systemOrange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.lightGray]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // 🔸 Đồng bộ lại tint của tabBar
        tabBar.tintColor = .systemOrange
        tabBar.unselectedItemTintColor = .lightGray

        tabBar.layer.cornerRadius = 24
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 8
    }


    private func addShapeForSelectedItem() {
        shapeLayer?.removeFromSuperlayer()

        let width = tabBar.bounds.width / CGFloat(tabBar.items?.count ?? 1)
        let height: CGFloat = 80
        let xPos = CGFloat(selectedIndex) * width

        let path = UIBezierPath()
        let radius: CGFloat = 30

        // Điểm bắt đầu (trái tab)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: xPos, y: 0))

        // Đoạn cong lên
        path.addCurve(to: CGPoint(x: xPos + width / 2, y: -20),
                      controlPoint1: CGPoint(x: xPos + width * 0.25, y: 0),
                      controlPoint2: CGPoint(x: xPos + width * 0.25, y: -20))
        path.addCurve(to: CGPoint(x: xPos + width, y: 0),
                      controlPoint1: CGPoint(x: xPos + width * 0.75, y: -20),
                      controlPoint2: CGPoint(x: xPos + width * 0.75, y: 0))

        // Kết thúc khung tab bar
        path.addLine(to: CGPoint(x: tabBar.bounds.width, y: 0))
        path.addLine(to: CGPoint(x: tabBar.bounds.width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()

        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = UIColor.white.cgColor
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.1
        shape.shadowOffset = CGSize(width: 0, height: -3)
        shape.shadowRadius = 8

        tabBar.layer.insertSublayer(shape, at: 0)
        shapeLayer = shape

        animateSelectedIcon()
    }

    private func animateSelectedIcon() {
        guard let tabBarButtons = tabBar.subviews.filter({ $0.isUserInteractionEnabled }) as? [UIView] else { return }

        for (index, button) in tabBarButtons.enumerated() {
            let isSelected = index == selectedIndex
            let imageView = button.subviews.compactMap { $0 as? UIImageView }.first
            let label = button.subviews.compactMap { $0 as? UILabel }.first

            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.7,
                           options: .curveEaseInOut,
                           animations: {
                if isSelected {
                    imageView?.transform = CGAffineTransform(translationX: 0, y: -10).scaledBy(x: 1.2, y: 1.2)
                    label?.transform = CGAffineTransform(translationX: 0, y: -8)
                    imageView?.tintColor = .systemOrange
                    label?.textColor = .systemOrange
                } else {
                    imageView?.transform = .identity
                    label?.transform = .identity
                    imageView?.tintColor = .lightGray
                    label?.textColor = .lightGray
                }
            })
        }
    }

    // Khi chọn tab khác
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        animateShapeTransition()
        animateSelectedIcon()
    }

    private func animateShapeTransition() {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let oldPath = shapeLayer?.path
        addShapeForSelectedItem()
        animation.fromValue = oldPath
        animation.toValue = shapeLayer?.path
        shapeLayer?.add(animation, forKey: "pathAnimation")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addShapeForSelectedItem()
    }
}
