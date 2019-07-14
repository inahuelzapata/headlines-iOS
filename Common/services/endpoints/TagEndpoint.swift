//
//  TagEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum TagEndpoint: Endpoint {
    case tag(tag: String)

    var httpMethod: HTTPMethod {
        switch self {
        case .tag:
            return .get
        }
    }

    var urlPath: String {
        switch self {
        case .tag(let tag):
            let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? String()

            return "/tags/\(encodedTag)"
        }
    }
}
