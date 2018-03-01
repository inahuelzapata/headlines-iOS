//
//  ShareURLActivity.swift
//  Canillitapp
//
//  Created by Ezequiel Becerra on 01/03/2018.
//  Copyright © 2018 Ezequiel Becerra. All rights reserved.
//

import UIKit

class ShareCanillitapActivity: UIActivity {
    
    // MARK: Properties
    override var activityTitle: String? { return "Compartir URL" }
    override var activityType: UIActivityType? { return UIActivityType(rawValue: "Canillitapp URL") }
    override class var activityCategory: UIActivityCategory { return .action }
    override var activityImage: UIImage? { return UIImage(named: "icon_activity_share") }
    
    var news: News
    
    // MARK: Initializer
    
    init(withNews news: News) {
        self.news = news
        super.init()
    }
    
    // MARK: Overrides
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        // Nothing to prepare
    }
    
    override func perform() {
        let urlToShare = "https://www.canillitapp.com/article/\(self.news.identifier!)?source=iOS"
        UIPasteboard.general.string = urlToShare
        activityDidFinish(true)
    }
}
