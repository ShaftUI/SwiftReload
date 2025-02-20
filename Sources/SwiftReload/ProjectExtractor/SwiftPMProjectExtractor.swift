import Foundation

public class SwiftPMProjectExtractor: ProjectExtractor {
  public required init(entryPoint: URL) {
    self.entryPoint = entryPoint
  }

  public let entryPoint: URL

  public lazy var projectRoot: URL = findProjectRoot(of: entryPoint)!

  private lazy var buildManifest: BuildManifest = loadBuildManifest(projectRoot: projectRoot)

  public func findBuildCommand(for file: URL) -> SwiftBuildCommand? {
    for command in buildManifest.commands.values {
      if command.inputs.contains(file.path) && command.tool == "shell" {
        return SwiftBuildCommand(from: command.args!)
      }
    }
    return nil
  }
}

private func loadBuildManifest(projectRoot: URL) -> BuildManifest {
  let buildManifestURL = projectRoot.appendingPathComponent(".build/debug.yaml")
  return try! BuildManifest.load(from: buildManifestURL)
}

private func findProjectRoot(of swiftSource: URL) -> URL? {
  var current = swiftSource.deletingLastPathComponent()
  while current.path != "/" {
    let files = try! FileManager.default.contentsOfDirectory(atPath: current.path)
    if files.contains("Package.swift") {
      return current
    }
    current = current.deletingLastPathComponent()
  }
  return nil
}
