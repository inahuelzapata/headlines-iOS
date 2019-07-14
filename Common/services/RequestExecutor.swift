//
//  RequestExecutor.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

protocol RequestExecutor {
    init(session: URLSession, urlRequestBuilder: URLRequestBuildable)

    func execute<T: Decodable>(request: HTTPRequest,
                               response: @escaping (Result<T, Error>) -> Void,
                               dispatchQueue: DispatchQueue)
}

class ServiceExecutor: RequestExecutor {
    private let session: URLSession
    private let urlRequestBuilder: URLRequestBuildable

    required init(session: URLSession, urlRequestBuilder: URLRequestBuildable) {
        self.session = session
        self.urlRequestBuilder = urlRequestBuilder
    }

    func execute<T: Decodable>(request: HTTPRequest,
                               response: @escaping (Result<T, Error>) -> Void,
                               dispatchQueue: DispatchQueue = .main) {
        do {
            let urlRequest = try urlRequestBuilder.build(from: request)

            let dataTask = session.dataTask(with: urlRequest, decoder: JSONDecoder()) { (resultResponse: Result<T, Error>) in
                do {
                    let result = try resultResponse.get()

                    dispatchQueue.async {
                        response(.success(result))
                    }
                } catch {
                    dispatchQueue.async {
                        response(.failure(error))
                    }
                }
            }

            dataTask.resume()
        } catch {
            dispatchQueue.async {
                response(.failure(error))
            }
        }
    }
}

extension ServiceExecutor: HeaderComposer { }
