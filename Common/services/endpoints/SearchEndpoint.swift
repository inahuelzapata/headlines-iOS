//
//  SearchEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum SearchEndpoint: Endpoint {
    case search

    var httpMethod: HTTPMethod {
        switch self {
        case .search:
            return .get
        }
    }

    var urlPath: String {
        switch self {
        case .search:
            return "/search"
        }
    }
}
