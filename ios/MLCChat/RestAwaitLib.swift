//
//  RestAwaitLib.swift
//  MLCChat
//
//  Created by Kleomenis Katevas on 26/01/2024.
//

import Foundation
import Network

class RestAwaitLib {
    let host: String
    let port: Int
    
    static func requestPermission() {
        // dummy url
        let url = URL(string: "http://192.168.1.1:8080")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Nothing
        }
        
        task.resume()
    }

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    func continueExecution(completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "http://\(host):\(port)/continue") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            let responseString = String(data: data, encoding: .utf8)
            completion(responseString, nil)
        }

        task.resume()
    }
}
