
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
//import Kingfisher

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set}
    func updateTableViewAnimated()
    func updateLikeCell(at indexPath: IndexPath, isLiked: Bool)
}

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    var presenter: ImagesListPresenterProtocol?
    
    // MARK: - Private Properties
    
    private let imagesListCell = ImagesListCell()
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
        
        // ставим спиннер перед первой загрузкой фотографий
        UIBlockingProgressHUD.show()
        // Запрашиваем самую первую страницу фотографий с сервера
        presenter?.fetchPhotosNextPage()
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
        let oldCount = presenter?.numberOfRowsOldCount() ?? 0
        let newCount = presenter?.numberOfRows() ?? 0
        
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
        
        guard let photo = presenter?.photo(at: indexPath) else { return }
        
 
//        let isLiked = indexPath.row % 2 == 0
        cell.configure(photo: photo)
    }
    
    func updateLikeCell(at indexPath: IndexPath, isLiked: Bool) {
        if let currentCell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            print("3. [VC] Ячейка найдена по indexPath, вызываем setIsLiked(\(isLiked))")
            currentCell.setIsLiked(isLiked)
        } else {
            print("⚠️ [VC] Ошибка: cellForRow(at: \(indexPath)) вернул nil! Таблица не видит эту ячейку.")
        }
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    
    // Вызывается прямо перед тем, как ячейка отрисуется на экране. Используем для пагинации (бесконечного скролла)
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard let presenter else {
            return
        }

        // ДОБАВЛЕНО: не загружаем следующую страницу,
        // если контент ещё не превышает высоту таблицы
        guard tableView.contentSize.height > tableView.bounds.height else {
            return
        }

        // ДОБАВЛЕНО: проверяем, что таблица действительно скроллится
        guard tableView.isDragging ||
              tableView.isDecelerating ||
              tableView.isTracking else {
            return
        }

        // ОСТАЛОСЬ: загружаем только при отображении последней ячейки
        guard indexPath.row + 1 == presenter.numberOfRows() else {
            return
        }

        // ДОБАВЛЕНО: проверяем, что пользователь действительно почти достиг низа
        let currentOffset = tableView.contentOffset.y
        let visibleHeight = tableView.bounds.height
        let contentHeight = tableView.contentSize.height

        guard currentOffset + visibleHeight >= contentHeight - 100 else {
            return
        }

        presenter.fetchPhotosNextPage()
    }

    
    // Обработка нажатия на ячейку: снимаем выделение и открываем полноэкранный просмотр
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let photo = presenter?.photo(at: indexPath) else { return }
//        let photo = photos[indexPath.row]
        
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
        guard let photo = presenter?.photo(at: indexPath) else { return 0 }
//        let photo = presenter?.photo(at:indexPath)
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
            let count = presenter?.numberOfRows() ?? 0
            print("📊 Таблица спрашивает количество строк: \(count)")
            return count
        }
    
    // Спрашивает у нас: «Дай мне готовую и заполненную ячейку для конкретной строки»
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🎨 Таблица запрашивает ячейку для индекса: \(indexPath.row)")
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
    
    // метод делегата ячейки, где обрабатывается нажатие на кнопку лайка
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let photo = presenter?.photo(at: indexPath) else { return }
        
        print("1. [VC] Нажали лайк для фото id: \(photo.id), текущий isLiked: \(photo.isLiked)")
        UIBlockingProgressHUD.show()
        
        presenter?.didTapLike(at: indexPath)
    }
}
