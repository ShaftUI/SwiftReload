import Foundation
import Testing

@testable import SwiftReload

class LocalSwiftReloaderTests {
    init() {
        saveSelf()
    }

    deinit {
        restoreSelf()
    }

    @Test func example() async throws {
        var resume: () -> Void = {}

        LocalSwiftReloader(onReload: {
            resume()
        }).start()

        print(greet("Alice"))
        #expect(greet("Alice") == "Hello, Alice!")

        // replace self file "Hello" with "Hi"
        try await replaceSelf("Hello", with: "Hi")

        // wait for the reloader to reload the module
        // try await Task.sleep(for: .milliseconds(2000))
        await withCheckedContinuation { continuation in
            print("waiting for reload")
            resume = continuation.resume
            print("resumed")
        }

        // check if the changes are reflected
        print(greet("Alice"))
        #expect(greet("Alice") == "Hi, Alice!")
    }

    func greet(_ name: String) -> String {
        return "Hello, \(name)!"
    }

}

var savedSelf: String?

/// Save the current file content
func saveSelf() {
    let file = URL(fileURLWithPath: #filePath)
    let content = try! String(contentsOf: file)
    savedSelf = content
}

/// Restore previous file content
func restoreSelf() {
    guard let content = savedSelf else {
        return
    }
    let file = URL(fileURLWithPath: #filePath)
    try! content.write(to: file, atomically: true, encoding: .utf8)
}

/// Replace a string in the current file
func replaceSelf(_ old: String, with new: String) async throws {
    let file = URL(fileURLWithPath: #filePath)
    let content = try String(contentsOf: file)
    let newContent = content.replacingOccurrences(of: old, with: new)
    try newContent.write(to: file, atomically: true, encoding: .utf8)
}
