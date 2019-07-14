//
//  URLSession+Decodable.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

extension URLSession {
    func dataTask<T: Decodable>(with request: URLRequest,
                                decoder: JSONDecoder,
                                completionHandler: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: request) { data, _, error in
            if let error = error {
                completionHandler(.failure(error))
            }

            guard let safeData = data else {
                completionHandler(.failure(NetworkingError.emptyResponseData))

                return
            }

            completionHandler(Result { try decoder.decode(T.self, from: safeData) })
        }
    }
}
