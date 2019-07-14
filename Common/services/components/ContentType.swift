//
//  ContentType.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/13/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

enum ContentType {
    case applicationJSON
    case applicationJavaScript
    case imageJPEG

    var value: String {
        switch self {
        case .applicationJSON:
            return "application/json"

        case .imageJPEG:
            return "image/jpeg"

        case .applicationJavaScript
            return "application/javascript"
        }
    }
}
