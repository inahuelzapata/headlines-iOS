//
//  NetworkingError.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum NetworkingError: Error {
    case invalidURL
    case emptyResponseData
}
