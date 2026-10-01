// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Инфраструктурный слой сетевого взаимодействия приложения.
// Содержит enum `NetworkError` с описанием типизированных ошибок сети и расширение `URLSession` с хелпер-методом `data(for:)`.
// Метод перехватывает HTTP-статусы, валидирует диапазон успешных ответов (200..<300) и гарантированно возвращает результат `Result<Data, Error>` в главном потоке (`DispatchQueue.main`), изолируя UI-слой от вызовов из фоновых потоков.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. NetworkError — перечисление ошибок (HTTP статус-коды, отсутствие сети, ошибки парсинга и валидации).
// 2. data(for:completion:) — обертка над `dataTask(with:)`, выполняющая обработку базовых сценариев ответа сервера.
// 3. fulfillCompletionOnTheMainThread — замыкание-помощник для безопасной передачи результата работы в `DispatchQueue.main`.

import Foundation

//  fulfillCompletionOnTheMainThread — форсирует возврат ответа в DispatchQueue.main, чтобы UI не падал при обновлении.

// 💡 ОШИБКИ: Перечисление всех возможных сетевых ошибок для удобной обработки
import Foundation

// MARK: - Ошибки
enum NetworkError: Error {
    case httpStatusCode(Int)      // Сервер вернул плохой статус-код
    case urlRequestError(Error)   // Ошибка самого запроса или отсутствие сети
    case urlSessionError          // Ошибка URLSession
    case invalidRequest           // Некорректный URLRequest
    case decodingError(Error)     // Ошибка парсинга JSON
}

// MARK: - URLSession Extension

extension URLSession {
    
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
                // Ошибка уже залогирована в методе data(for:), передаём failure дальше
                completion(.failure(error))
            }
        }

        return task
    }
}
