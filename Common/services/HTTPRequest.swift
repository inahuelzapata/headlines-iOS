//
//  HTTPRequest.swift
//  Canillitapp
//
//  Created by Nahuel Zapata on 7/13/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

protocol HTTPRequestable {
    var endpoint: Endpoint { get }

    var parameters: Encodable { get }

    var headers: [Header] { get }
}

struct HTTPRequest: HTTPRequestable {
    var endpoint: Endpoint

    var parameters: Encodable

    var headers: [Header]
}

protocol Endpoint {
    var httpMethod: HTTPMethod { get }

    var baseURL: String { get }

    var urlPath: String { get }

    var builtURL: String { get }
}

extension Endpoint {
    var baseURL: String {
        guard let url = ConfigHelper.configForKey("base_url") as? String else {
            return "http://api.canillitapp.com"
        }

        return url
    }

    var builtURL: String {
        return baseURL + urlPath
    }
}
