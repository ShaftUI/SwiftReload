import Foundation
import Yams

/// commands:
///   "/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/CLib3.build/test3.cpp.o":
///      tool: clang
///      inputs: ["/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/Modules/SLib.swiftmodule","/Users/mac/code/PlayGradient/Sources/CLib3/test3.cpp"]
///      outputs: ["/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/CLib3.build/test3.cpp.o"]
///      description: "Compiling CLib3 test3.cpp"
///      args: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang","-fobjc-arc","-target","arm64-apple-macosx14.0","-O0","-DSWIFT_PACKAGE=1","-DDEBUG=1","-fblocks","-index-store-path","/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/index/store","-I","/Users/mac/code/PlayGradient/Sources/CLib3/include","-fmodule-map-file=/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/SLib.build/module.modulemap","-I","/Users/mac/code/PlayGradient/Sources/CLib2","-fmodule-map-file=/Users/mac/code/PlayGradient/Sources/CLib2/module.modulemap","-isysroot","/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk","-F","/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks","-fPIC","-g","-g","-MD","-MT","dependencies","-MF","/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/CLib3.build/test3.cpp.d","-std=c++20","-c","/Users/mac/code/PlayGradient/Sources/CLib3/test3.cpp","-o","/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/CLib3.build/test3.cpp.o"]
///      deps: "/Users/mac/code/PlayGradient/.build/arm64-apple-macosx/debug/CLib3.build/test3.cpp.d"
struct BuildManifest: Codable {
  let commands: [String: Command]

  struct Command: Codable {
    let tool: String
    let inputs: [String]
    let outputs: [String]
    let description: String?
    let args: [String]?
    let deps: String?
  }
}

extension BuildManifest {
  static func load(from url: URL) throws -> BuildManifest {
    let data = try Data(contentsOf: url)
    return try YAMLDecoder().decode(BuildManifest.self, from: data)
  }
}
