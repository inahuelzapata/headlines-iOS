//
//  TrendingNews.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum TrendingNewsEndpoint: Endpoint {
    case trending(date: Date, count: Int)
    case search
    
    var httpMethod: HTTPMethod {
        switch self {
        case .trending:
            return .get
        case .search:
            return .get
        }
    }
    
    var urlPath: String {
        switch self {
        case .trending(let date, let count):
            return "/trending/\(date.mapToString())/\(count)"

        case .search:
            return "/search/trending"
        }
    }
}
