import UIKit

class InComeCollectionViewCell: UICollectionViewCell {

    // MARK: - UI Elements
     let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()

     let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Views
    private func setupViews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        // Thêm viền
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        // Padding bên trong cell
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        let sidePadding: CGFloat = 4
        let spacing: CGFloat = 8
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: spacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: sidePadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -sidePadding),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -bottomPadding)
        ])
    }
    
    // MARK: - Configuration
    func configure(with category: Category) {
        let db = AppDatabase.shared
        titleLabel.text = category.name
        
        if let iconString = category.icon {
                // Thử decode Base64 trước
                if let imageData = Data(base64Encoded: iconString),
                   let image = UIImage(data: imageData) {
                    iconImageView.image = image
                } else {
                    // Nếu decode thất bại, coi như là SF Symbol
                    iconImageView.image = UIImage(systemName: iconString)
                }
            } else {
                iconImageView.image = UIImage(systemName: "photo")
            }
        }
    

    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        iconImageView.image = nil
    }
    
    override var isSelected: Bool {
            didSet {
                contentView.backgroundColor = isSelected ? UIColor.systemYellow : UIColor.systemGray6
            }
        }
}
