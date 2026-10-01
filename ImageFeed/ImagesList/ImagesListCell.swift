//
//

import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    
    weak var delegate: ImagesListCellDelegate?
    
    // MARK: - Reuse Identifier
    // Идентификатор ячейки для регистрации и переиспользования в таблице
    static let reuseIdentifier = "ImagesListCell"

    // MARK: - UI Components
    // Основная картинка поста
    private let cellImage: UIImageView = {
        let cellImage = UIImageView()
        cellImage.clipsToBounds = true
        cellImage.layer.cornerRadius = 16
        cellImage.backgroundColor = UIColor(named: "YP Gray (iOS)")
        cellImage.translatesAutoresizingMaskIntoConstraints = false
        return cellImage
    }()
    
    // Иконка-заглушка, отображаемая во время загрузки
    private let stubImageView: UIImageView = {
        let stubImageView = UIImageView()
        stubImageView.image = UIImage(named: "stub")
        stubImageView.translatesAutoresizingMaskIntoConstraints = false
        return stubImageView
    }()
    
    // Лейбл для даты публикации
    private let dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.textColor = UIColor(named: "YP White (iOS)")
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        return dateLabel
    }()
    
    // Кнопка установки/снятия лайка
    private let likeButton: UIButton = {
        let likeButton = UIButton()
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        return likeButton
    }()
    
    // Подложка под текст с градиентом для лучшей читаемости
    private let gradientView: UIView = {
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()
    
    // MARK: - Private Properties
    // Форматтер для превращения даты в читаемую строку
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Initializers
    // Основной инициализатор при создании ячейки из кода
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor(named: "YP Black (iOS)")
        setupUI()
        setupConstraints()
    }
    
    // Обязательный инициализатор для работы со Storyboard/XIB (не используется)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    // Подготовка ячейки к повторномуใชванию: отмена фоновой загрузки Kingfisher
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
    }
    
    // Расчет и обновление геометрии слоев (в частности — градиента)
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
    
    // MARK: - Public Methods
    
    func setIsLiked(_ isLiked: Bool) {
        let likeImage = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeButton.setImage(likeImage, for: .normal)
    }
    
    // Настройка содержимого ячейки данными фотографии
    func configure(photo: Photo) {
        setIsHidden(true)
        
        if let url = URL(string: photo.thumbImageURL) {
            cellImage.kf.setImage(with: url) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.setIsHidden(false)
                case .failure(_):
                    self.setIsHidden(false)
                }
            }
        } else {
            self.setIsHidden(false)
        }
            
        if let createdAt = photo.createdAt {
            dateLabel.text = Self.dateFormatter.string(from: createdAt)
        } else {
            dateLabel.text = ""
        }
        
        setIsLiked(photo.isLiked)
    }
    
    // MARK: - Private Methods
    // Добавление дочерних представлений в иерархию
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(cellImage)
        contentView.addSubview(stubImageView)
        cellImage.addSubview(gradientView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(likeButton)
        likeButton.addTarget(self, action: #selector(didTaplikeButton), for: .touchUpInside)
    }

    // Настройка ограничений (Auto Layout) для всех элементов
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            stubImageView.centerXAnchor.constraint(equalTo: cellImage.centerXAnchor),
            stubImageView.centerYAnchor.constraint(equalTo: cellImage.centerYAnchor),
            stubImageView.widthAnchor.constraint(equalToConstant: 83),
            stubImageView.heightAnchor.constraint(equalToConstant: 75),
            
            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            gradientView.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 40),
            
            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor, constant: -8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8),
            dateLabel.topAnchor.constraint(equalTo: gradientView.topAnchor)
        ])
    }
    
    // Переключение видимости UI-элементов во время загрузки и после нее
    private func setIsHidden(_ isLoading: Bool) {
        if isLoading {
            likeButton.isHidden = true
            dateLabel.isHidden = true
            gradientView.isHidden = true
            stubImageView.isHidden = false
        } else {
            stubImageView.isHidden = true
            likeButton.isHidden = false
            dateLabel.isHidden = false
            gradientView.isHidden = false
        }
    }
    
    @objc private func didTaplikeButton() {
        delegate?.imageListCellDidTapLike(self)
    }
}
