//
//  SwiftJobsTool.swift
//
//
//  Created by Hanna Chen on 2022/7/22.
//

import Foundation
import SwiftJobsToolCore

@main
enum SwiftJobsTool {
    static func main() async throws {
        print("Welcome! This is SwiftJobsTool.")

        // TODO: parse input arguments
        let keyword = "iOS"
        let excludedKeyword = "網頁 前端 後端"
        let pages = 5

        let spider104 = try Spider104(
            baseURL: "https://www.104.com.tw/jobs/search/list",
            queries: [
                "ro": "1",
                "isnew": "30",
                "kwop": "1",
                "keyword": keyword,
                "expansionType": "area,spec,com,job,wf,wktm",
                "area": "6001001000", // taipei city
                "order": "2",
                "asc": "0",
                "excludeJobKeyword": excludedKeyword,
                "hotjob": "0",
                "recommendJob": "0",
            ],
            headers: [
                "Referer": "https://www.104.com.tw/jobs/search/",
            ],
            pages: pages
        )
        await spider104.start()
    }
}
