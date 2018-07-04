//
//  AppDelegate.swift
//  Headlines
//
//  Created by Ezequiel Becerra on 8/23/16.
//  Copyright © 2016 Ezequiel Becerra. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import UserNotifications

extension Notification.Name {
    static let notificationNewsTapped = Notification.Name("notification_news_tapped")
}

@UIApplicationMain
class AppDelegate: UIResponder,
                    UIApplicationDelegate,
                    UISplitViewControllerDelegate,
                    UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    let reactionsService = ReactionsService()
    let usersService = UsersService()
    let newsService = NewsService()
    var newsDataTask: URLSessionDataTask?
    var newsFetched: [Topic]?
    let userSettingsManager = UserSettingsManager()
    var newsToOpen: News?
    
    var loadingTask: LoadingTask?
    
    func registerNotificationActions() {
        let viewAction = UNNotificationAction(identifier: "view", title: "Ver", options: [.foreground])
        let likeAction = UNNotificationAction(identifier: "like", title: "👍", options: [])
        let dislikeAction = UNNotificationAction(identifier: "dislike", title: "👎", options: [])
        
        let newsAPNCategory = UNNotificationCategory(
            identifier: "news_apn",
            actions: [viewAction, likeAction, dislikeAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([newsAPNCategory])
        UNUserNotificationCenter.current().delegate = self
    }
    
    func setupNotifications() {
        registerNotificationActions()
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func initialNewsFetch() {
        
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //  https://www.herzbube.ch/blog/2016/08/how-hide-fabric-api-key-and-build-secret-open-source-project
        let resourceURL = Bundle.main.url(forResource: "fabric", withExtension: "apikey")
        
        do {
            var fabricAPIKey = try String(contentsOf: resourceURL!)
            fabricAPIKey = fabricAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if fabricAPIKey != "" {
                Crashlytics.start(withAPIKey: fabricAPIKey)
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
        if userSettingsManager.firstOpenDate == nil {
            userSettingsManager.firstOpenDate = Date()
        }
        
        let completion: ([Topic]?, [Category]?, NSError?) -> Void = { [unowned self] (topics, categories, error) in
            if let e = error {
                // Replace this with an alert error in the future and a "Try again" button
                print("#ERROR: \(e.localizedDescription)")
                self.loadingTask?.start()
                return
            }
            
            guard let t = topics, let c = categories else {
                // Replace this with an alert error in the future and a "Try again" button
                let e = NSError(
                    domain: "Startup",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Something went wrong"]
                )
                print("#ERROR: \(e.localizedDescription)")
                self.loadingTask?.start()
                return
            }
            
            NewsManager.sharedInstance.categories = c
            NewsManager.sharedInstance.topics = t
            
            let notification = Notification.Name(rawValue: "loadingTaskFinished")
            let nc = NotificationCenter.default
            nc.post(name: notification, object: nil, userInfo: nil)
        }
        
        loadingTask = LoadingTask(with: completion)
        loadingTask?.start()
        
        setupNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        usersService.postDeviceToken(token, success: nil, fail: nil)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("#ERROR: \(error.localizedDescription)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
    
// MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        guard let postId = response.notification.request.content.userInfo["post-id"] as? Int else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "like":
            reactionsService.postReaction(
                "👍",
                atPost: "\(postId)",
                success: nil,
                fail: nil
            )
        case "dislike":
            reactionsService.postReaction(
                "👎",
                atPost: "\(postId)",
                success: nil,
                fail: nil
            )
        //  Responds "view" action and default one
        default:
            if let postURL = response.notification.request.content.userInfo["post-url"] as? String {
                newsToOpen = News()
                newsToOpen?.url = URL(string: postURL)
                newsToOpen?.identifier = "\(postId)"
                
                NotificationCenter.default.post(name: .notificationNewsTapped, object: newsToOpen)
            }
        }
        
        completionHandler()
    }
    
}
