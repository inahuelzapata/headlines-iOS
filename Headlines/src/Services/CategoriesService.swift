//
//  CategoriesService.swift
//  Canillitapp
//
//  Created by Ezequiel Becerra on 30/06/2018.
//  Copyright © 2018 Ezequiel Becerra. All rights reserved.
//

import Foundation
import SwiftyJSON

class CategoriesService: HTTPService {
    
    func categoriesList (success: ((_ result: [Category]?) -> Void)?,
                         fail: ((_ error: NSError) -> Void)?) {
        
        let successBlock: (_ result: Data?, _ response: URLResponse?) -> Void = {(data, response) in
            guard let d = data else {
                return
            }
            
            let json = JSON(data: d)
            
            var res = [Category]()
            
            for (_, v) in json {
                let c = Category(json: v)
                res.append(c)
            }
            
            DispatchQueue.main.async(execute: {
                success?(res)
            })
        }
        
        let failBlock: (_ error: NSError) -> Void = { (e) in
            DispatchQueue.main.async(execute: {
                fail?(e as NSError)
            })
        }
        
        _ = request(method: .GET, path: "categories/", params: nil, success: successBlock, fail: failBlock)
    }
}
