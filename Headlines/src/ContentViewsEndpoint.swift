//
//  ContentViewsEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum ContentViewsEndpoint: Endpoint {
    case contentViews

    var httpMethod: HTTPMethod {
        switch self {
        case .contentViews:
            return .post
        }
    }

    var urlPath: String  {
        switch self {
        case .contentViews:
            return "/content-views"
        }
    }
}
