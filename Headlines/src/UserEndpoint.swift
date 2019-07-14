//
//  UserEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum UserEndpoint: Endpoint {
    case deviceToken

    var httpMethod: HTTPMethod {
        switch self {
        case .deviceToken:
            return .post
        }
    }

    var urlPath: String  {
        switch self {
        case .deviceToken:
            return "/users/devicetoken"
        }
    }
}
