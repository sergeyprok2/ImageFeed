//
//

import UIKit

final class ImagesListCell: UITableViewCell {
    
    static let reuseIdentifier = "ImagesListCell"

    let cellImage: UIImageView = {
        let cellImage = UIImageView()
        cellImage.translatesAutoresizingMaskIntoConstraints = false
        return cellImage
    }()
    
    let dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.textColor = UIColor(named: "YP White (iOS)")
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        return dateLabel
    }()
    
    let likeButton: UIButton = {
        let likeButton = UIButton()
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        return likeButton
    }()
    
    private let gradientView: UIView = {
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor(named: "YP Black (iOS)")
        setupUI()
        setupConstraints()

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(cellImage)
        contentView.addSubview(gradientView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(likeButton)
        
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            gradientView.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo:cellImage.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 40),
            
            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor, constant: -8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8),
            dateLabel.topAnchor.constraint(equalTo: gradientView.topAnchor)
            
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Если градиент ещё не добавлен, создаём его
        if gradientView.layer.sublayers == nil || gradientView.layer.sublayers?.isEmpty == true {
            let gradient = CAGradientLayer()
            gradient.frame = gradientView.bounds
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
            gradientView.layer.insertSublayer(gradient, at: 0)
        } else {
            gradientView.layer.sublayers?.first?.frame = gradientView.bounds
        }
    }
    
}
