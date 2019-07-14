//
//  Header.swift
//  Canillitapp
//
//  Created by Nahuel Zapata on 7/13/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

protocol Headable {
    var value: [String: String] { get }
}

enum Header {
    case contentType(type: ContentType)
    case authentication(token: String)
}

extension Header: Headable {
    var value: [String: String] {
        switch self {
        case .contentType(let type):
            return ["Content-Type": type.value]
        case .authentication(let token):
            return ["Authentication": token]
        }
    }
}
