//
//  InterestsEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum InterestsEndpoint: Endpoint {
    case interests(ckUserRecordName: String)

    var httpMethod: HTTPMethod {
        switch self {
        case .interests:
            return .get
        }
    }

    var urlPath: String {
        switch self {
        case .interests(let ckUserRecordName):
            return "/interests/\(ckUserRecordName)/iOS"
        }
    }
}
