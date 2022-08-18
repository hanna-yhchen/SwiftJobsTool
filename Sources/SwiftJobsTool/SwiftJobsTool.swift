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
            pages: pages
        )

        let CRSpider = try CakeResumeSpider(
            filters: [
                "profession:it_ios-developer",
                "job_type:full_time",
                "seniority_level:entry_level",
            ],
            pages: pages
        )

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await spider104.start() }
            group.addTask { await CRSpider.start() }
        }
    }
}
