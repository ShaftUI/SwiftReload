import Foundation
import TSCBasic
import TSCUtility

/// A file watcher that watches a directory recursively with optional filtering.
public class RecursiveFileWatcher {
    public init(
        _ directory: Foundation.URL,
        filter: @escaping (Foundation.URL) -> Bool = { _ in true },
        callback: @escaping ([Foundation.URL]) -> Void
    ) {
        assert(directory.isFileURL)
        self.directory = directory
        self.filter = filter
        self.callback = callback
    }

    /// The directory to watch.
    public let directory: Foundation.URL

    /// The filter to select files to watch. Return true to watch a file.
    public let filter: (Foundation.URL) -> Bool

    /// Recording the modification time of files. Used to determine if a file
    /// has been changed.
    private var modifyTime = [Foundation.URL: Date]()

    /// The callback invoked when some files are changed. The argument is the
    /// list of changed files. There is no guarantee which thread the callback
    /// is called on.
    private let callback: ([Foundation.URL]) -> Void

    private lazy var watcher: FSWatch = FSWatch(
        paths: [try! AbsolutePath(validating: directory.path)],
        block: onFileChange
    )

    /// Start watching the directory for file changes.
    public func start() {
        initModifyTime()
        try! watcher.start()
    }

    /// Populate the modify time records for all files in the directory.
    private func initModifyTime() {
        enumerateFilesFiltered(at: directory) { url in
            modifyTime[url] = getModifyTime(url)
        }
    }

    private func onFileChange(_ path: [AbsolutePath]) {
        var changedFiles = [Foundation.URL]()

        for directory in path {
            enumerateFilesFiltered(at: URL(fileURLWithPath: directory.pathString)) { url in
                let newModifyTime = getModifyTime(url)
                if let oldModifyTime = modifyTime[url], oldModifyTime != newModifyTime {
                    changedFiles.append(url)
                    modifyTime[url] = newModifyTime
                }
            }
        }

        callback(changedFiles)
    }

    /// Enumerate all files recursively in a directory that pass the filter.
    private func enumerateFilesFiltered(
        at directory: Foundation.URL,
        block: (Foundation.URL) -> Void
    ) {
        enumerateFiles(at: directory) { url in
            if filter(url) {
                block(url)
            }
        }
    }
}

/// Enumerate all files recursively in a directory.
internal func enumerateFiles(at url: Foundation.URL, _ block: (Foundation.URL) -> Void) {
    let fm = FileManager.default
    let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil)
    for case let url as Foundation.URL in enumerator! {
        block(url)
    }
}

/// Get the modification time of a file.
private func getModifyTime(_ url: Foundation.URL) -> Date {
    let fm = FileManager.default
    let attributes = try! fm.attributesOfItem(atPath: url.path)
    return attributes[.modificationDate] as! Date
}
