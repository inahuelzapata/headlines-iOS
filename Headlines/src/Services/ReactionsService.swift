//
//  ReactionsService.swift
//  Headlines
//
//  Created by Ezequiel Becerra on 4/8/17.
//  Copyright © 2017 Ezequiel Becerra. All rights reserved.
//

import UIKit
import CloudKit

// swiftlint:disable force_try
class ReactionsService: HTTPService {

    func postReaction(_ reaction: String,
                      atPost postId: String,
                      success: ((_ response: URLResponse?, News?) -> Void)?,
                      fail: ((_ error: Error) -> Void)?) {

        let container = CKContainer.default()
        container.fetchUserRecordID { (recordId, error) in
            if let err = error {
                DispatchQueue.main.async(execute: {
                    fail?(err)
                })
                return
            }

            guard let userId = recordId else {
                let errUserInfo = [NSLocalizedDescriptionKey: "No user record id"]
                let err = NSError(domain: "ReactionsService",
                                  code: 1,
                                  userInfo: errUserInfo)
                DispatchQueue.main.async(execute: {
                    fail?(err)
                })
                return
            }

            let successBlock: (_ result: Data?, _ response: URLResponse?) -> Void = {(data, response) in
                guard let d = data else {
                    return
                }

                let n = try? JSONDecoder().decode(News.self, from: d)

                DispatchQueue.main.async(execute: {
                    success?(response, n)
                })
            }

            let failBlock: (_ error: NSError) -> Void = { (e) in
                DispatchQueue.main.async(execute: {
                    fail?(e as NSError)
                })
            }

            let params = [
                "reaction": reaction,
                "source": "iOS",
                "user_id": userId.recordName
            ]

            _ = self.request(method: .POST,
                             path: "reactions/\(postId)",
                             params: params,
                             success: successBlock,
                             fail: failBlock)
        }
    }

    func getReactions(success: ((_ response: URLResponse?, [Reaction]) -> Void)?,
                      fail: ((_ error: Error) -> Void)?) {

        let successBlock: (_ result: Data?, _ response: URLResponse?) -> Void = {(data, response) in
            guard let d = data else {
                return
            }

            let reactions = try! JSONDecoder().decode([Reaction].self, from: d)

            DispatchQueue.main.async(execute: {
                success?(response, reactions)
            })
        }

        let failBlock: (_ error: NSError) -> Void = { (e) in
            DispatchQueue.main.async(execute: {
                fail?(e as NSError)
            })
        }

        if ProcessInfo.processInfo.arguments.contains("mockRequests") {
            let mockService = MockService()
            _ = mockService.request(file: "GET-reactions",
                                    success: successBlock,
                                    fail: failBlock)
            return
        }

        let container = CKContainer.default()
        container.fetchUserRecordID { (recordId, error) in
            if let err = error {
                DispatchQueue.main.async(execute: {
                    fail?(err)
                })
                return
            }

            guard let userId = recordId else {
                let errUserInfo = [NSLocalizedDescriptionKey: "No user record id"]
                let err = NSError(domain: "ReactionsService",
                                  code: 1,
                                  userInfo: errUserInfo)

                DispatchQueue.main.async(execute: {
                    fail?(err)
                })
                return
            }

            _ = self.request(method: .GET,
                             path: "reactions/\(userId.recordName)/iOS",
                             params: nil,
                             success: successBlock,
                             fail: failBlock)
        }
    }
}
