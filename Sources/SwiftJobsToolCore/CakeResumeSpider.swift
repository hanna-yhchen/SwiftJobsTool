//
//  CakeResumeSpider.swift
//  
//
//  Created by Hanna Chen on 2022/8/18.
//

import Foundation

public final class CakeResumeSpider {
    private let baseRequest: URLRequest
    private var basePayloadParams = ""
    private let pages: Int

    public init(
        filters: [String],
        pages: Int
    ) throws {
        guard var urlComponents = URLComponents(string: "https://966rg9m3ek-dsn.algolia.net/1/indexes/*/queries") else {
            throw SpiderError.invalidURL
        }
        //swiftlint:disable line_length
        urlComponents.queryItems = [
            "x-algolia-agent": "Algolia for JavaScript (4.14.0); Browser (lite); instantsearch.js (4.43.1); react (18.2.0); react-instantsearch (6.30.2); react-instantsearch-hooks (6.30.2); JS Helper (3.10.0)",
            "x-algolia-api-key": "YzYzNWY5OGJlNTg1MTI5MjVkMzJhYmNiM2M4MGZhYzRjZDliODQ1MjhjZGI1MzAzNDMwMWVhMjMzNWVmNWUyNHZhbGlkVW50aWw9MTY2MTQwNTQxNyZyZXN0cmljdEluZGljZXM9Sm9iJTJDSm9iX29yZGVyX2J5X2NvbnRlbnRfdXBkYXRlZF9hdCUyQ0pvYl9wbGF5Z3JvdW5kJTJDUGFnZSUyQ1BhZ2Vfb3JkZXJfYnlfY29udGVudF91cGRhdGVkX2F0JmZpbHRlcnM9YWFzbV9zdGF0ZSUzQSslMjJjcmVhdGVkJTIyK0FORCtub2luZGV4JTNBK2ZhbHNlJmhpdHNQZXJQYWdlPTEwJmF0dHJpYnV0ZXNUb1NuaXBwZXQ9JTVCJTIyZGVzY3JpcHRpb25fcGxhaW5fdGV4dCUzQTgwJTIyJTVEJmhpZ2hsaWdodFByZVRhZz0lM0NtYXJrJTNFJmhpZ2hsaWdodFBvc3RUYWc9JTNDJTJGbWFyayUzRQ==",
            "x-algolia-application-id": "966RG9M3EK"
        ].map { URLQueryItem(name: $0, value: $1) }
        //swiftlint:enable line_length

        guard let url = urlComponents.url else { throw SpiderError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(K.agent, forHTTPHeaderField: "User-Agent")

        self.baseRequest = request
        self.pages = pages
        self.basePayloadParams = basePayloadParams(filters: filters) ?? ""
    }

    public func start() async {
        print("Start searching on CakeResume...")

        do {
            var csvString = "Job Name, Company, Min Salary, Date, Link\n"
            try await fetchJobs(pages: pages, writeTo: &csvString)
            let path = try FileManager.default.url(
                for: .desktopDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )

            let fileURL = path.appendingPathComponent("cake_resume_jobs.csv")

            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Write to file \"cake_resume_jobs.csv\" in the desktop directory.")
        } catch {
            print(error)
        }
    }
}

// MARK: - Networking

extension CakeResumeSpider {
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
                        var name = job["title"] as? String,
                        let companyPage = job["page"] as? RawResponse,
                        var company = companyPage["name"] as? String,
                        let companyPath = companyPage["path"] as? String,
                        let minSalary = job["salary_min"] as? Int,
                        let rawDate = job["content_updated_at"] as? Double,
                        let path = job["path"] as? String
                    else { continue }

                    let link = "https://www.cakeresume.com/companies/\(companyPath)/jobs/\(path)"

                    let date = Date(timeIntervalSince1970: TimeInterval(rawDate / 1000)).formatted(date: .numeric, time: .omitted)

                    name.removeAll { $0 == "," }
                    company.removeAll { $0 == "," }

                    let row = "\(name), \(company), \(minSalary), \(date), \(link)\n"
                    csvString += row
                }
            }
        }
    }

    private func fetchJobList(with request: URLRequest) async throws -> [RawResponse] {
        let (data, _) = try await URLSession.shared.data(for: request)
        guard
            let jsonEnvelope = try JSONSerialization.jsonObject(with: data) as? RawResponse,
            let results = jsonEnvelope["results"] as? [RawResponse],
            let list = results[0]["hits"] as? [RawResponse]
        else {
            throw SpiderError.failedParsing
        }

        return list
    }
}

// MARK: - Helpers

extension CakeResumeSpider {
    private func request(forPage page: Int) throws -> URLRequest {
        var (params, request) = (basePayloadParams, baseRequest)

        let jsonString = #"{"requests": [{"indexName": "Job","params": "facetFilters="# + "\(params)&page=\(page - 1)\"}]}"
        guard let data = jsonString.data(using: .utf8) else {
            throw SpiderError.failedEncoding
        }
        request.httpBody = data

        return request
    }

    private func basePayloadParams(filters: [String]) -> String? {
        var facetFilters = "["
        for filter in filters {
            facetFilters += #"[""# + filter + #""],"#
        }
        if facetFilters.removeLast() == "," {
            facetFilters += "]"
        }
        let encodedFilters = facetFilters.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)

        return encodedFilters
    }
}
