/// **Инфраструктурный слой сетевого взаимодействия приложения**
///
/// **За что отвечает:**
/// Предоставляет механизмы обработки сетевых запросов и декодирования JSON.
/// Содержит enum `NetworkError` с описанием типизированных ошибок сети и расширение `URLSession`
/// с универсальными методами выполнения запросов `data(for:)` и `objectTask(for:)`.
///
/// **Задачи:**
/// 1. Описывает категорию сетевых ошибок (ошибки HTTP-статусов, парсинга, отсутствие сети).
/// 2. Выполняет базовую валидацию ответов сервера (статус-коды 200..<300) в `data(for:)`.
/// 3. Гарантированно возвращает результат вызова в главном потоке (`DispatchQueue.main`).
/// 4. Декодирует бинарные данные JSON в универсальные модели Swift типа `Decodable`.

import Foundation

// MARK: - NetworkError

/// Перечисление возможных сетевых ошибок для удобной и безопасной обработки
enum NetworkError: Error {
    case httpStatusCode(Int)      // Сервер вернул плохой статус-код
    case urlRequestError(Error)   // Ошибка самого запроса или отсутствие сети
    case urlSessionError          // Ошибка URLSession (отсутствуют данные и ошибка)
    case invalidRequest           // Некорректный URLRequest
    case decodingError(Error)     // Ошибка парсинга JSON
}

// MARK: - URLSession Extension

extension URLSession {

    // MARK: - Public Methods

    /// Выполняет сетевой запрос, валидирует HTTP-статус и возвращает бинарные данные `Data` в главном потоке
    func data(for request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let task = dataTask(with: request) { data, response, error in
            let urlString = request.url?.absoluteString ?? "Неизвестный URL"

            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode {

                if 200..<300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    let rawData = String(data: data, encoding: .utf8) ?? "Нет данных"
                    print("[data URLSession]: [Ошибка HTTP статуса \(statusCode)] [URL: \(urlString), Ответ: \(rawData)]")
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                print("[data URLSession]: [Ошибка сетевого запроса] [URL: \(urlString), Ошибка: \(error.localizedDescription)]")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                print("[data URLSession]: [Ошибка URLSession - нет данных и нет ошибки] [URL: \(urlString)]")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        }

        return task
    }

    /// Выполняет сетевой запрос и автоматически декодирует полученный JSON в указанный тип `Decodable`
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()

        let task = data(for: request) { (result: Result<Data, Error>) in
            let urlString = request.url?.absoluteString ?? "Неизвестный URL"

            switch result {
            case .success(let data):
                do {
                    let decodedObject = try decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    let rawData = String(data: data, encoding: .utf8) ?? "Не удалось прочитать Data"
                    print("[objectTask URLSession]: [Ошибка декодирования JSON] [URL: \(urlString), Ошибка: \(error), Данные: \(rawData)]")
                    completion(.failure(NetworkError.decodingError(error)))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }

        return task
    }
}
