import Foundation
import SwiftParser
import SwiftSyntax

/// A stateful wrapper for the patcher that has caches intermidiate results for
/// better performance.
class PatcherState {
    public private(set) var patchID: Int = 0

    private var files = PatcherFiles()

    /// The number of files in the patcher state.
    var count: Int { files.count }

    /// Load a file into the patcher without patching it.
    func loadFile(path: URL, content: String) {
        files.update(path: path, content: content)
    }

    /// Update a file and generate a patch for it.
    func updateAndPatch(path: URL, content: String, moduleName: String) -> String? {
        let oldSyntax = files.getSyntax(for: path)
        files.update(path: path, content: content)
        let newSyntax = files.getSyntax(for: path)!
        let patch = Pacher(patchID: patchID).patch(
            oldSyntax: oldSyntax!,
            newSyntax: newSyntax,
            moduleName: moduleName
        )
        patchID += 1
        return patch.formatted().description
    }
}

private class PatcherFiles {
    private var files: [URL: String] = [:]

    private var syntaxCache: [URL: SourceFileSyntax] = [:]

    var count: Int { files.count }

    func update(path: URL, content: String) {
        if let oldContent = files[path] {
            if oldContent != content {
                files[path] = content
                revokeSyntaxCache(for: path)
            }
        } else {
            files[path] = content
        }
    }

    func remove(path: URL) {
        files.removeValue(forKey: path)
        revokeSyntaxCache(for: path)
    }

    private func revokeSyntaxCache(for path: URL) {
        syntaxCache.removeValue(forKey: path)
    }

    func getSyntax(for path: URL) -> SourceFileSyntax? {
        if let syntax = syntaxCache[path] {
            return syntax
        } else {
            if let content = files[path] {
                let syntax = Parser.parse(source: content)
                syntaxCache[path] = syntax
                return syntax
            } else {
                return nil
            }
        }
    }
}
