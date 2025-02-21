import Foundation

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension Collection {
    /// Returns the only element of the collection or nil.
    public var spm_only: Element? {
        return count == 1 ? self[startIndex] : nil
    }
}
