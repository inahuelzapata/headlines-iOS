//
//  BaseService.swift
//  Headlines
//
//  Created by Ezequiel Becerra on 5/3/17.
//  Copyright © 2017 Ezequiel Becerra. All rights reserved.
//

import Foundation

protocol RequestExecutor {
    init(session: URLSession, dispatchQueue: DispatchQueue)

    func execute<T: Decodable>(request: HTTPRequest, response: @escaping (Result<T, Error>) -> Void)
}

extension ServiceExecutor: HeaderComposer { }

extension Encodable {
    func encodeToData(withEncoder encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
}

enum NetworkingError: Error {
    case captureList
    case emptyResponseData
}

class ServiceExecutor: RequestExecutor {
    let session: URLSession
    let dispatchQueue: DispatchQueue

    required init(session: URLSession, dispatchQueue: DispatchQueue = .main) {
        self.session = session
        self.dispatchQueue = dispatchQueue
    }

    func execute<T: Decodable>(request: HTTPRequest, response: @escaping (Result<T, Error>) -> Void) {
        var urlRequest = URLRequest(url: URL(string: request.endpoint.builtURL)!) // Avoid Force Unwrap
        urlRequest.httpMethod = request.endpoint.httpMethod.method
        urlRequest.allHTTPHeaderFields = composeHeaders(request.headers)
        urlRequest.httpBody = try? request.parameters.encodeToData()

        let task = session.dataTask(with: urlRequest) { [weak self] data, _, error in
            guard let self = self else {
                response(.failure(NetworkingError.captureList))
                return
            }

            if let error = error {
                self.dispatchQueue.async {
                    response(.failure(error))
                }
            }

            guard let safeData = data else {
                response(.failure(NetworkingError.emptyResponseData))

                return
            }

            let decoded = Result { try JSONDecoder().decode(T.self, from: safeData) }

            self.dispatchQueue.async {
                response(decoded)
            }
        }

        task.resume()
    }
}

class HTTPService {
    func baseURL() -> String {
        guard let baseURL = ConfigHelper.configForKey("base_url") as? String else {
            return "http://api.canillitapp.com"
        }

        return baseURL
    }

    func request(method: HTTPMethod,
                 path: String,
                 params: [String: String]?,
                 headers: [String: String]? = nil,
                 success: ((_ result: Data?, _ response: URLResponse?) -> Void)?,
                 fail: ((_ error: NSError) -> Void)?) -> URLSessionDataTask? {

        let url = URL(string: "\(baseURL())/\(path)")
        var request = URLRequest(url: url!)

        switch method {
        case .POST:
            request.httpMethod = "POST"
        default:
            break
        }

        if let headers = headers {
            headers.forEach { (k, v) in
                request.addValue(v, forHTTPHeaderField: k)
            }
        }

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        if let p = params {
            var tmp = [String]()
            for (k, v) in p {
                tmp.append("\(k)=\(v)")
            }
            let httpBody = tmp.joined(separator: "&")
            request.httpBody = httpBody.data(using: .utf8)
        }

        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            if let e = error {
                fail?(e as NSError)
                return
            }

            success?(data, response)
        })

        task.resume()
        return task
    }
}
