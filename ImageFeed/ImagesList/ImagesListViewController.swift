//
//  ViewController.swift
//  ImageFeed
//
//  Created by Сергей on 23.07.2026.
//

import UIKit

final class ImagesListViewController: UIViewController {
    
    // 1. Создаём константу для имени перехода в одном месте
    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Private Properties

    private let photosName = (0..<20).map { String($0) }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
    
    // 2. Метод подготовки к переходу
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Сравниваем с нашей константой
        if segue.identifier == showSingleImageSegueIdentifier {
            
            // Безопасно разворачиваем новый экран и индекс нажатой ячейки
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            // Достаем картинку из массива по индексу
            let image = UIImage(named: photosName[indexPath.row])
            
            // ЧЕСТНОЕ РЕШЕНИЕ: кладем картинку в простую промежуточную переменную image
            viewController.image = image
            
        } else {
            super.prepare(for: segue, sender: sender)
        }
    
    }

    // MARK: - Private Methods

    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return
        }

        cell.cellImage.image = image
        cell.dateLabel.text = dateFormatter.string(from: Date())

        let isLiked = indexPath.row % 2 == 0
        let likeImage = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = image.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) // 1
            
        guard let imageListCell = cell as? ImagesListCell else { // 2
            return UITableViewCell()
        }
            
        configCell(for: imageListCell, with: indexPath) // 3
        return imageListCell // 4
    }
}

