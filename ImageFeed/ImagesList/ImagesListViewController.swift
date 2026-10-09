/// **Контроллер списка фотографий (Слой представления / View & Controller)**
///
/// **За что отвечает:**
/// Это слой представления (UI). Его задача — показывать спиннеры (UIBlockingProgressHUD),
/// рисовать ячейки таблицы и реагировать на действия пользователя или события из сервисов.
///
/// **Задачи:**
/// 1. Управляет отображением UITableView и настроек ячеек ImagesListCell.
/// 2. Управляет UI-индикаторами (показ и скрытие UIBlockingProgressHUD).
/// 3. Реагирует на действия пользователя (скролл, клики) и сигналы от ImagesListService.
///
/// **Правило:**
/// Не делает сетевые запросы сам, а использует ImagesListService.

import UIKit

// MARK: - Protocol

/// Протокол UI-контроллера для управления экраном ленты фотографий
protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func updateTableViewAnimated()
    func updateLikeCell(at indexPath: IndexPath, isLiked: Bool)
}

// MARK: - ImagesListViewController

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {

    // MARK: - Public Properties

    var presenter: ImagesListPresenterProtocol?

    // MARK: - Private Properties

    private let imagesListCell = ImagesListCell()
    private var imagesListServiceObserver: NSObjectProtocol?

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    // MARK: - Lifecycle

    /// Точка входа: вызывается один раз при загрузке экрана в память
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        setupUI()
        setupConstraints()

        UIBlockingProgressHUD.show()
        presenter?.fetchPhotosNextPage()
    }

    // MARK: - Public Methods

    /// Анимированное добавление новых строк в таблицу при получении очередной порции фото
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

    /// Обновление состояния кнопки лайка в конкретной ячейке
    func updateLikeCell(at indexPath: IndexPath, isLiked: Bool) {
        if let currentCell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            currentCell.setIsLiked(isLiked)
        }
    }

    // MARK: - Private Methods

    /// Добавление компонентов на экран и их первичная настройка
    private func setupUI() {
        view.addSubview(tableView)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
    }

    /// Растягиваем таблицу по краям экрана с помощью Auto Layout
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    /// Наполнение отдельной ячейки данными (картинка, дата, кнопка лайка)
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let photo = presenter?.photo(at: indexPath) else { return }
        cell.configure(photo: photo)
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {

    /// Вызывается прямо перед тем, как ячейка отрисуется на экране. Используем для пагинации (бесконечного скролла)
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard let presenter else {
            return
        }

        guard tableView.contentSize.height > tableView.bounds.height else {
            return
        }

        guard tableView.isDragging ||
              tableView.isDecelerating ||
              tableView.isTracking else {
            return
        }

        guard indexPath.row + 1 == presenter.numberOfRows() else {
            return
        }

        let currentOffset = tableView.contentOffset.y
        let visibleHeight = tableView.bounds.height
        let contentHeight = tableView.contentSize.height

        guard currentOffset + visibleHeight >= contentHeight - 100 else {
            return
        }

        presenter.fetchPhotosNextPage()
    }

    /// Обработка нажатия на ячейку: снимаем выделение и открываем полноэкранный просмотр
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let photo = presenter?.photo(at: indexPath) else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        let singleImageVC = SingleImageViewController()
        guard let url = URL(string: photo.largeImageURL) else { return }

        singleImageVC.fullImageURL = url
        singleImageVC.modalPresentationStyle = .fullScreen
        present(singleImageVC, animated: true)
    }

    /// Расчет высоты ячейки, чтобы картинка пропорционально вписалась по ширине экрана
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let photo = presenter?.photo(at: indexPath) else { return 0 }
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

    /// Запрашивает количество строк для отображения в секции таблицы
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = presenter?.numberOfRows() ?? 0
        return count
    }

    /// Возвращает сконфигурированную ячейку для конкретного индекса таблицы
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

// MARK: - ImagesListCellDelegate

extension ImagesListViewController: ImagesListCellDelegate {

    /// Метод делегата ячейки, где обрабатывается нажатие на кнопку лайка
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let photo = presenter?.photo(at: indexPath) else { return }

        UIBlockingProgressHUD.show()
        presenter?.didTapLike(at: indexPath)
    }
}
