//
//  HeaderComposer.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

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
