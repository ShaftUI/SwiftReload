import Foundation
import SwiftParser
import SwiftReload
import SwiftSyntax

LocalSwiftReloader().start()

let counter = Counter()

@MainActor func hello() {
    print("hello")
    counter.tick()
}

class Counter {
    var count = 0

    func tick() {
        count += 1
        print("count = \(count)")
    }
}

Task {
    while true {
        try await Task.sleep(for: .milliseconds(500))
        hello()
    }
}

RunLoop.main.run()
