//
//  ReactionsEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum ReactionsEndpoint: Endpoint {
    case get(ckUserRecordName: String)
    case post(postID: String)

    var httpMethod: HTTPMethod {
        switch self {
        case .get:
            return .get

        case .post:
            return .post
        }
    }

    var urlPath: String  {
        switch self {
        case .get(let ckUserRecordName):
            return "/reactions/\(ckUserRecordName)/iOS"
        case .post(let postID):
            return "/reactions/\(postID)"
        }
    }
}
