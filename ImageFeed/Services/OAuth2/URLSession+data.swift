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
enum NetworkError: Error {
    case httpStatusCode(Int)      // Сервер вернул плохой статус-код (например, 400, 401, 500)
    case urlRequestError(Error)   // Ошибка самого запроса или отсутствие сети
    case urlSessionError          // Ошибка URLSession (не пришли ни данные, ни ошибка)
    case invalidRequest           // Некорректный URLRequest
    case decodingError(Error)     // Ошибка парсинга JSON
}

// MARK: - URLSession Extension

extension URLSession {
    
    // 💡 ХЕЛПЕР: Универсальный сетевой метод, который отправляет запрос, проверяет статус-код и гарантированно возвращает ответ в главном потоке (Main Thread)
    func data(for request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        
        // 💡 ЗАМЫКАНИЕ: Перенаправляет передачу результата (success/failure) в главный поток для безопасного обновления UI
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        // 💡 ЗАПРОС: Запускает стандартный dataTask и обрабатывает ответы от сервера
        let task = dataTask(with: request) { data, response, error in
            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode {
                
                // Проверяем, что статус-код успешный (от 200 до 299)
                if 200..<300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    print(String(data: data, encoding: .utf8) ?? "")
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        }

        return task
    }
    
    /// Создаёт задачу сетевого запроса и декодирует ответ сервера в тип `T`.
    /// - Parameters:
    ///   - request: Запрос `URLRequest`.
    ///   - completion: Замыкание с результатом декодирования (`Result<T, Error>`).
    /// - Returns: Созданная задача `URLSessionTask`.
    ///
    /// // Выполняет сетевой запрос и автоматически декодирует ответ в указанную модель T


    func objectTask<T: Decodable>(for request: URLRequest,completion: @escaping (Result<T, Error>) -> Void) -> URLSessionTask {
        let decoder = JSONDecoder()

        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Полученные данные: \(jsonString)")
                }
                do {
                    let decodedObject = try decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    if let decodingError = error as? DecodingError {
                        print("Ошибка декодирования: \(decodingError), Данные: \(String(data: data, encoding: .utf8) ?? "")")
                    } else {
                        print("Ошибка декодирования: \(error.localizedDescription), Данные: \(String(data: data, encoding: .utf8) ?? "")")
                    }
                    completion(.failure(error))
                }

            case .failure(let error):
                print("Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        return task
    }
}
