import Foundation

struct CommandPatcher {
    /// Transform a Swift build command to a patch command.
    static func patchCommand(
        _ command: SwiftBuildCommand,
        inputFile: URL,
        outputFile: URL,
        moduleName: String,
        patchID: Int
    ) -> SwiftBuildCommand {
        var patchCommand = command
        patchCommand.remove("-c", count: 2)
        patchCommand.remove("-module-name", count: 2)
        patchCommand.remove("-emit-module")
        patchCommand.remove("-emit-dependencies")
        patchCommand.remove("-emit-module-path", count: 2)
        patchCommand.remove("-module-cache-path", count: 2)
        patchCommand.remove("-output-file-map", count: 2)
        patchCommand.remove("-index-store-path", count: 2)
        patchCommand.remove("-package-name", count: 2)
        patchCommand.remove("-parseable-output")
        patchCommand.remove("-incremental")
        patchCommand.remove("-enable-batch-mode")
        // patchCommand.remove("-color-diagnostics")

        // patchCommand.append("-v")
        patchCommand.append(["-module-name", "\(moduleName)_patch_\(patchID)"])
        patchCommand.append(["-c", inputFile.path])
        patchCommand.append(["-o", outputFile.path])
        patchCommand.append("-emit-library")
        patchCommand.append(["-Xfrontend", "-disable-access-control"])
        patchCommand.append(["-Xlinker", "-flat_namespace"])
        patchCommand.append(["-Xlinker", "-undefined"])
        patchCommand.append(["-Xlinker", "suppress"])
        patchCommand.append(["-Xfrontend", "-enable-implicit-dynamic"])
        patchCommand.append(["-enable-private-imports"])

        return patchCommand
    }
}
