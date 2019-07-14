//
//  NewsEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum NewsEndpoint: Endpoint {
    case withCategory(categoryID: String, page: Int)

    var httpMethod: HTTPMethod {
        switch self {
        case .withCategory:
            return .GET
        }
    }

    var urlPath: String {
        switch self {
        case .withCategory(let categoryID, let page):
            return "/news/category/\(categoryID)?page=\(page)"
        }
    }
}
