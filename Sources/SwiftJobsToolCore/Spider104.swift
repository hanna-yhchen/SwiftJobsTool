//
//  Spider104.swift
//
//
//  Created by Hanna Chen on 2022/7/22.
//

import Foundation

typealias RawResponse = [String: Any]

public final class Spider104 {
    private let baseComponents: URLComponents
    private let baseRequest: URLRequest
    private let pages: Int

    public init(
        queries: [String: String],
        headers: [String: String]? = nil,
        pages: Int
    ) throws {
        guard var urlComponents = URLComponents(string: "https://www.104.com.tw/") else {
            throw SpiderError.invalidURL
        }
        urlComponents.queryItems = queries.map { URLQueryItem(name: $0, value: $1) }
        self.baseComponents = urlComponents

        guard let url = urlComponents.url else { throw SpiderError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(K.agent, forHTTPHeaderField: "User-Agent")
        if let headers = headers {
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }
        self.baseRequest = request

        self.pages = pages
    }

    public func start() async {
        print("Start searching on 104人力銀行...")

        do {
            // let ids = try await fetchIDs(upTo: pages)
            var csvString = "Job Name, Company, Date, Link\n"
            try await fetchJobs(pages: pages, writeTo: &csvString)
            let path = try FileManager.default.url(
                for: .desktopDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )

            let fileURL = path.appendingPathComponent("104jobs.csv")

            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Write to file \"104jobs.csv\" in the desktop directory.")
        } catch {
            print(error)
        }
    }
}

// MARK: - Networking

extension Spider104 {
//    private func fetchIDs(upTo pages: Int) async throws -> [String] {
//        try await withThrowingTaskGroup(
//            of: (page: Int, list: [RawResponse]).self,
//            returning: [String].self
//        ) { group in
//            for page in 1...pages {
//                group.addTask {[self] in
//                    let list = try await fetchJobList(with: request(forPage: page))
//                    return (page, list)
//                }
//            }
//
//            var lists: [Int: [RawResponse]] = [:]
//            for try await result in group {
//                lists[result.page] = result.list
//            }
//
//            var ids: [String] = []
//            for page in 1...pages {
//                guard let list = lists[page] else { continue }
//                for job in list {
//                    guard
//                        let linkDict = job["link"] as? RawResponse,
//                        let linkString = linkDict["job"] as? String,
//                        let id = extractID(from: linkString)
//                    else { continue }
//                    ids.append(id)
//                }
//            }
//            return ids
//        }
//    }

    private func fetchJobs(pages: Int, writeTo csvString: inout String) async throws {
        try await withThrowingTaskGroup(of: (page: Int, list: [RawResponse]).self) { group in
            for page in 1...pages {
                group.addTask {[self] in
                    let list = try await fetchJobList(with: request(forPage: page))
                    return (page, list)
                }
            }

            var lists: [Int: [RawResponse]] = [:]
            for try await result in group {
                lists[result.page] = result.list
            }

            for page in 1...pages {
                guard let list = lists[page] else { continue }
                for job in list {
                    guard
                        var name = job["jobName"] as? String,
                        var company = job["custName"] as? String,
                        let date = job["appearDateDesc"] as? String,
                        let linkDict = job["link"] as? RawResponse,
                        var link = linkDict["job"] as? String
                    else { continue }

                    name.removeAll { $0 == "," }
                    company.removeAll { $0 == "," }
                    link.insert(contentsOf: "https:", at: link.startIndex)
                    if let startIndexOfQuery = link.firstIndex(of: "?") {
                        link.removeSubrange(startIndexOfQuery...)
                    }

                    let row = "\(name), \(company), \(date), \(link)\n"
                    csvString += row
                }
            }
        }
    }

    private func fetchJobList(with request: URLRequest) async throws -> [RawResponse] {
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

// MARK: - Helpers

extension Spider104 {
    private func extractID(from link: String) -> String? {
        guard
            let start = link.range(of: "job/")?.upperBound,
            let end = link.firstIndex(of: "?")
        else {
            return nil
        }
        return String(link[start..<end])
    }

    private func request(forPage page: Int) throws -> URLRequest {
        var (urlComponents, request) = (baseComponents, baseRequest)
        urlComponents.path = "/jobs/search/list"
        urlComponents.queryItems?.append(URLQueryItem(name: "page", value: String(page)))
        guard let url = urlComponents.url else { throw SpiderError.invalidURL }

        request.url = url
        request.setValue("https://www.104.com.tw/jobs/search/", forHTTPHeaderField: "Referer")

        return request
    }

    private func request(forID id: String) throws -> URLRequest {
        var (urlComponents, request) = (baseComponents, baseRequest)
        urlComponents.path = "/job/ajax/content/" + id
        guard let url = urlComponents.url else { throw SpiderError.invalidURL }

        request.url = url
        request.setValue("https://www.104.com.tw/job/" + id, forHTTPHeaderField: "Referer")

        return request
    }
}
