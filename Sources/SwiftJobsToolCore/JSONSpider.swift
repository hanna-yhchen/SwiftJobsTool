//
//  JSONSpider.swift
//
//
//  Created by Hanna Chen on 2022/7/22.
//

import Foundation

public class JSONSpider {
    var urlComponents: URLComponents
    var request: URLRequest
    
    init(
        baseURL: String,
        queries: [String: String],
        headers: [String: String]
    ) throws {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw SpiderError.invalidURL
        }
        urlComponents.queryItems = queries.map { URLQueryItem(name: $0, value: $1) }
        self.urlComponents = urlComponents

        guard let url = urlComponents.url else {
            throw SpiderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(K.agent, forHTTPHeaderField: "User-Agent")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        self.request = request
    }
}
