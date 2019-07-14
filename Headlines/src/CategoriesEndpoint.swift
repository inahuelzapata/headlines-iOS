//
//  CategoriesEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum CategoriesEndpoint: Endpoint {
    case categories

    var httpMethod: HTTPMethod {
        switch self {
        case .categories:
            return .get
        }
    }

    var urlPath: String {
        switch self {
        case .categories:
            return "/categories"
        }
    }
}
