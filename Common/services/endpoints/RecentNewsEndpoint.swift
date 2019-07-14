//
//  RecentNewsEndpoint.swift
//  Headlines
//
//  Created by Nahuel Zapata on 7/14/19.
//  Copyright © 2019 Ezequiel Becerra. All rights reserved.
//

import Foundation

extension Date {
    func mapToString(withCalendar calendar: Calendar = .current) -> String {
        let components = (calendar as NSCalendar).components([.day, .month, .year], from: self)

        return String(format: "%d-%02d-%02d", components.year!, components.month!, components.day!)
    }
}

enum RecentNewsEndpoint: Endpoint {
    case latest(withDate: Date)

    var httpMethod: HTTPMethod {
        switch self {
        case .latest:
            return .get
        }
    }

    var urlPath: String {
        switch self {
        case .latest (let date):
            return "/latest/\(date.mapToString())"
        }
    }
}
