
/// **Контроллер списка фотографий (Слой представления / View & Controller)**
///
/// **За что отвечает:**
/// Это слой представления (UI). Его задача — показывать спиннеры (UIBlockingProgressHUD),
/// рисовать ячейки таблицы и реагировать на действия пользователя или события из сервисов.
///
/// Задачи:
/// 1. Управляет отображением UITableView и настроек ячеек ImagesListCell.
/// 2. Управляет UI-индикаторами (показ и скрытие UIBlockingProgressHUD).
/// 3. Реагирует на действия пользователя (скролл, клики) и сигналы от ImagesListService.
/// 
/// **Правило:**
/// Не делает сетевые запросы сам, а использует ImagesListService.

import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let imagesListCell = ImagesListCell()
    private let imagesListService = ImagesListService()
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    // MARK: - Lifecycle
    
    // Точка входа: вызывается один раз при загрузке экрана в память
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        setupUI()
        setupConstraints()
        
        // Подписываемся на уведомления от сервиса, чтобы обновлять таблицу при приходе новых данных
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            UIBlockingProgressHUD.dismiss()
            self?.updateTableViewAnimated()
        }
        
        // ставим спиннер перед первой загрузкой фотографий
        UIBlockingProgressHUD.show()
        // Запрашиваем самую первую страницу фотографий с сервера
        imagesListService.fetchPhotosNextPage()
    }
    
    // MARK: - UI Setup
    
    // Добавление компонентов на экран и их первичная настройка
    private func setupUI() {
        view.addSubview(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
    }

    // Растягиваем таблицу по краям экрана с помощью Auto Layout
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    // MARK: - Data & Cell Configuration
    
    // Анимированное добавление новых строк в таблицу при получении очередной порции фото
    func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            tableView.performBatchUpdates {
                var indexPaths: [IndexPath] = []
                for i in oldCount..<newCount {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                tableView.insertRows(at: indexPaths, with: .automatic)
            } completion: { _ in }
        }
    }

    // Наполнение отдельной ячейки данными (картинка, дата, кнопка лайка)
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        
        let photo = photos[indexPath.row]
        
 
//        let isLiked = indexPath.row % 2 == 0
        cell.configure(photo: photo)
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    
    // Вызывается прямо перед тем, как ячейка отрисуется на экране. Используем для пагинации (бесконечного скролла)
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            // ставим спиннер перед второй и последующей загрузкой фотографий
            UIBlockingProgressHUD.show()
            imagesListService.fetchPhotosNextPage()
            
        }
    }
    
    // Обработка нажатия на ячейку: снимаем выделение и открываем полноэкранный просмотр
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        
        // 💡 Вот здесь сразу видим точный размер в пикселях:
        print("Нажали на фото: \(Int(photo.size.width)) × \(Int(photo.size.height)) px")
        tableView.deselectRow(at: indexPath, animated: true)
        
        let singleImageVC = SingleImageViewController()
        guard let url = URL(string: photo.largeImageURL) else {return}
        
        singleImageVC.fullImageURL = url
        
        singleImageVC.modalPresentationStyle = .fullScreen
        present(singleImageVC, animated: true)
    }

    // Расчет высоты ячейки, чтобы картинка пропорционально вписалась по ширине экрана
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}

// MARK: - UITableViewDataSource

extension ImagesListViewController: UITableViewDataSource {
    
    // Спрашивает у нас: «Сколько всего строк нарисовать в таблице?»
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    // Спрашивает у нас: «Дай мне готовую и заполненную ячейку для конкретной строки»
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        cell.selectionStyle = .none
            
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        
        print("1. [VC] Нажали лайк для фото id: \(photo.id), текущий isLiked: \(photo.isLiked)")
        UIBlockingProgressHUD.show()
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.photos = self.imagesListService.photos
                    let newIsLiked = self.photos[indexPath.row].isLiked
                    print("2. [VC] Успех сети! Новое значение из массива: \(newIsLiked)")
                    
                    if let currentCell = self.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                        print("3. [VC] Ячейка найдена по indexPath, вызываем setIsLiked(\(newIsLiked))")
                        currentCell.setIsLiked(newIsLiked)
                    } else {
                        print("⚠️ [VC] Ошибка: cellForRow(at: \(indexPath)) вернул nil! Таблица не видит эту ячейку.")
                    }
                    
                    UIBlockingProgressHUD.dismiss()
                    
                case .failure(let error):
                    UIBlockingProgressHUD.dismiss()
                    print("❌ [VC] Ошибка запроса: \(error)")
                }
            }
        }
    }
}
