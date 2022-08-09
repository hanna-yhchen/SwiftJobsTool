//
//  SwiftLintPlugin.swift
//  
//
//  Created by Hanna Chen on 2022/7/27.
//

import PackagePlugin

@main
struct SwiftLintPlugins: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return [
            .buildCommand(
                displayName: "Linting \(target.name)",
                executable: try context.tool(named: "swiftlint").path,
                arguments: [
                    "lint",
                    "--no-cache",
                    "--in-process-sourcekit",
                    target.directory.string
                ],
                environment: [:]
            )
        ]
    }
}
