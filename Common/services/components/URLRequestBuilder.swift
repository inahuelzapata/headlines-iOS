//
//  URLRequestBuilder.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

protocol URLRequestBuildable {
    func build(from request: HTTPRequestable) throws -> URLRequest
}

struct URLRequestBuilder: URLRequestBuildable {
    func build(from request: HTTPRequestable) throws -> URLRequest {
        guard let url = URL(string: request.endpoint.builtURL) else {
            throw NetworkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.endpoint.httpMethod.method
        urlRequest.allHTTPHeaderFields = composeHeaders(request.headers)
        urlRequest.httpBody = try? request.parameters.encodeToData()

        return urlRequest
    }
}
