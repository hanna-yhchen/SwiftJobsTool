//
//  Spider104.swift
//
//
//  Created by Hanna Chen on 2022/7/22.
//

import Foundation

typealias RawResponse = [String: Any]

public final class Spider104: JSONSpider {
    private let pages: Int

    public init(
        baseURL: String,
        queries: [String: String],
        headers: [String: String],
        pages: Int
    ) throws {
        self.pages = pages

        try super.init(baseURL: baseURL, queries: queries, headers: headers)
    }

    public func start() async {
        print("Start searching on 104人力銀行...")
        do {
            var jobList: [RawResponse] = []
            for i in 1...pages {
                let list = try await fetchJobList(page: i)
                jobList.append(contentsOf: list)
            }

            print(jobList.count, "jobs found.")
            jobList.forEach { job in
                guard
                    let name = job["jobName"] as? String,
                    let linkDict = job["link"] as? [String: String],
                    let urlString = linkDict["job"],
                    let url = URL(string: "https:" + urlString)
                else { return }
                print(name, url.absoluteString)
            }
            // TODO: fetch job detail
            // TODO: write into csv file
        } catch {
            print(error)
        }
    }

    private func fetchJobList(page: Int) async throws -> [RawResponse] {
        urlComponents.queryItems?.append(URLQueryItem(name: "page", value: "\(page)"))
        guard let url = urlComponents.url else {
            throw SpiderError.invalidURL
        }
        request.url = url

        let (data, _) = try await URLSession.shared.data(for: request)
        guard
            let jsonEnvelope = try JSONSerialization.jsonObject(with: data) as? RawResponse,
            let jsonData = jsonEnvelope["data"] as? RawResponse,
            let list = jsonData["list"] as? [RawResponse]
        else {
            throw SpiderError.failedParsing
        }

        return list
    }
}
