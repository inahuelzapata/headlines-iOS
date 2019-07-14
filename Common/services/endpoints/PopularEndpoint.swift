//
//  PopularEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum PopularEndpoint: Endpoint {
    case popular(page: Int)

    var httpMethod: HTTPMethod {
        switch self {
        case .popular:
            return .get
        }
    }

    var urlPath: String {
        switch self {
        case .popular(let page):
            return "popular?page=\(page)"
        }
    }
}
