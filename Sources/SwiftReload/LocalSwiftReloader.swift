import Foundation

#if os(Windows)
    import WinSDK
#endif

public class LocalSwiftReloader {
    public init(entryPoint: String = #filePath, onReload: @escaping () -> Void = {}) {
        self.onReload = onReload
        self.entryPoint = URL(fileURLWithPath: entryPoint)
        self.projectExtractor = SwiftPMProjectExtractor(entryPoint: self.entryPoint)
        self.sourceRoot = self.entryPoint.deletingLastPathComponent()
        self.projectRoot = projectExtractor.projectRoot
        self.buildRoot = projectRoot.appendingPathComponent(".build")
        self.patchBuildRoot = buildRoot.appendingPathComponent("patches")
        try? FileManager.default.removeItem(at: patchBuildRoot)
        initState()
    }

    /// The callback to run when a patch is applied. Note that there is no
    /// guarantee that the callback will be run on the main thread.
    public let onReload: () -> Void

    /// The entry point of the Swift project, usually the main Swift file. This
    /// is used to locate the project root.
    public let entryPoint: URL

    /// The root directory of the Swift source files, usually the directory
    /// containing the entry point.
    public let sourceRoot: URL

    /// The root directory of the Swift project. This is the directory
    /// containing the `Package.swift` file.
    public let projectRoot: URL

    /// The root of the build directory of the Swift project. This is usually
    /// the `.build` directory in the project root.
    public let buildRoot: URL

    /// The directory to store the generated patches.
    public let patchBuildRoot: URL

    private lazy var watcher: RecursiveFileWatcher = RecursiveFileWatcher(
        sourceRoot,
        filter: { $0.pathExtension == "swift" },
        callback: onFileChange
    )

    /// The project extractor used to extract build commands and various
    /// additional information from the Swift project.
    private let projectExtractor: ProjectExtractor

    private var patchID: Int { state.patchID }

    private let state = PatcherState()

    /// Load all source files into the patcher state for later diffing and
    /// patching.
    private func initState() {
        enumerateFiles(at: sourceRoot) { url in
            guard let content = try? String(contentsOf: url) else {
                return
            }
            state.loadFile(path: url, content: content)
        }
        print("🚀 Reloader loaded. Watching \(state.count) files")
    }

    private func onFileChange(_ files: [URL]) {
        for file in files {
            patchFile(file)
        }
    }

    /// Generate a patch for a file, compile the patch into a dylib, and load
    /// the patch dylib.
    private func patchFile(_ file: URL) {
        print("🛠️ Patching \(file.path)")

        guard let content = try? String(contentsOf: file) else {
            print("🛑 Failed to read file \(file.path)")
            return
        }
        guard let command = projectExtractor.findBuildCommand(for: file) else {
            print("🛑 Failed to find build command for \(file.path)")
            return
        }
        guard let moduleName = command.findModuleName() else {
            print("🛑 Failed to find module name for \(file.path)")
            return
        }
        guard
            let patched = state.updateAndPatch(
                path: file,
                content: content,
                moduleName: moduleName
            )
        else {
            print("🛑 Failed to generate patch for \(file.path)")
            return
        }

        let filename = file.deletingPathExtension().lastPathComponent
        let patchFile = patchBuildRoot.appendingPathComponent("\(filename).patch_\(patchID).swift")
        // try? patched.write(to: patchFile, atomically: true, encoding: .utf8)
        try! FileManager.default.createDirectory(
            at: patchBuildRoot,
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: patchFile.path, contents: patched.data(using: .utf8))
        print("🛠️ Patch generated at \(patchFile.path)")

        let outputFile = patchBuildRoot.appendingPathComponent("\(filename).patch_\(patchID).dylib")
        let patchedCommand = CommandPatcher.patchCommand(
            command,
            inputFile: patchFile,
            outputFile: outputFile,
            moduleName: moduleName,
            patchID: patchID
        )
        print("🛠️ Compiling with '\(patchedCommand.args.first!)'")

        executeCommand(patchedCommand)

        // load the patch dylib
        do {
            try loadLibrary(path: outputFile.path)
            print("✅ Patch loaded successfully")
            onReload()
        } catch LoadLibraryError.win32Error(let code) {
            print("🛑 Failed to load \(outputFile.path): Win32 error \(code)")
        } catch LoadLibraryError.dlopenError(let error) {
            print("🛑 Failed to load \(outputFile.path): dlopen \(error)")
        } catch {
            print("🛑 Failed to load \(outputFile.path): \(error)")
        }
    }

    public func start() {
        watcher.start()
    }
}

/// Execute a Swift build command.
private func executeCommand(_ command: SwiftBuildCommand) {
    let process = try! Process.run(
        URL(fileURLWithPath: command.args.first!),
        arguments: command.args.dropFirst().map { $0 }
    )
    process.waitUntilExit()
}

enum LoadLibraryError: Error {
    case win32Error(Int)
    case dlopenError(String)
}

private func loadLibrary(path: String) throws {
    #if os(Windows)
        let result = path.withCString(encodedAs: UTF16.self) { LoadLibraryW($0) }
        guard result != nil else {
            throw LoadLibraryError.win32Error(Int(GetLastError()))
        }
        return
    #else
        let loadResult = dlopen(path, RTLD_NOW)
        if loadResult == nil {
            let error = String(cString: dlerror())
            throw LoadLibraryError.dlopenError(error)
        }
    #endif
}
