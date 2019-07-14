//
//  HTTPMethod.swift
//  Canillitapp
//
//  Created by Nahuel Zapata on 7/13/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum HTTPMethod {
    case delete
    case get
    case post
    case put
}

extension HTTPMethod {
    var method: String {
        switch self {
        case .delete:
            return "DELETE"

        case .get:
            return "GET"

        case .post:
            return "POST"

        case .put:
            return "PUT"
        }
    }
}
