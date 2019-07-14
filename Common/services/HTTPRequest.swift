//
//  HTTPRequest.swift
//  Canillitapp
//
//  Created by Nahuel Zapata on 7/13/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

protocol HTTPRequestable {
    var endpoint: Endpoint { get }

    var parameters: Encodable { get }

    var headers: [Header] { get }
}

struct HTTPRequest: HTTPRequestable {
    var endpoint: Endpoint

    var parameters: Encodable

    var headers: [Header]
}
