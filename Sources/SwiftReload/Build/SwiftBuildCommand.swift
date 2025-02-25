/// Wrapper around build commands generated by SwiftPM with additional utility
/// methods.
public struct SwiftBuildCommand {
    public init(from args: [String]) {
        self.args = args
    }

    public private(set) var args: [String]

    public func findModuleName() -> String? {
        guard let index = args.firstIndex(of: "-module-name") else {
            return nil
        }
        return args[index + 1]
    }

    /// Remove `count` args starting from the first occurence of `arg`.
    public mutating func remove(_ arg: String, count: Int = 1) {
        if let index = args.firstIndex(of: arg) {
            args.removeSubrange(index..<(index + count))
        }
    }

    /// Add `arg` to the end of the args.
    public mutating func append(_ arg: String) {
        args.append(arg)
    }

    /// Add multiple args to the end of the args.
    public mutating func append(_ args: [String]) {
        self.args.append(contentsOf: args)
    }
}

extension SwiftBuildCommand: CustomStringConvertible {
    public var description: String {
        args.joined(separator: " ")
    }
}
