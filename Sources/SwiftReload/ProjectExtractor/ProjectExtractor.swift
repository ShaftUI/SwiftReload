import Foundation

public protocol ProjectExtractor {
    init(entryPoint: URL)

    var projectRoot: URL { get }

    func findBuildCommand(for path: URL) -> SwiftBuildCommand?
}
