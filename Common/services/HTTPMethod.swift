//
//  HTTPMethod.swift
//  Canillitapp
//
//  Created by Nahuel Zapata on 7/13/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum HTTPMethod {
    case DELETE
    case GET
    case POST
    case PUT
}

extension HTTPMethod {
    var method: String {
        switch self {
        case .DELETE:
            return "DELETE"

        case .GET:
            return "GET"

        case .POST:
            return "POST"

        case .PUT:
            return "PUT"
        }
    }
}
