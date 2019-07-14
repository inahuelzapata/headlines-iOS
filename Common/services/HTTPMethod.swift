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


protocol HeaderComposer {
    func composeHeaders(_ headers: [Headable]) -> [String: String]
}

extension HeaderComposer {
    func composeHeaders(_ headers: [Headable]) -> [String: String] {
        return headers.map { return $0.value }
            .flatMap { $0 }
            .reduce([String: String]()) {
                var nextDict = $0
                nextDict.updateValue($1.1, forKey: $1.0)

                return nextDict
        }
    }
}

// TODO: Check if needed to abstract this into a smaller dependency
