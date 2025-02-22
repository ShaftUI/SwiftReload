# SwiftReload

This is an experimental project that enables hot reloading of Swift code in SwiftPM based projects.

## Platforms

| **Platform** | **CI Status**                                                                                                                                                          | **Support Status** |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| macOS        | [![MacOS](https://github.com/ShaftUI/SwiftReload/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/ShaftUI/SwiftReload/actions/workflows/ci-macos.yml)     | ✅                  |
| Linux        | [![Linux](https://github.com/ShaftUI/SwiftReload/actions/workflows/ci-linux.yml/badge.svg)](https://github.com/ShaftUI/SwiftReload/actions/workflows/ci-linux.yml)     | ✅                  |
| Windows      | [![Swift](https://github.com/ShaftUI/SwiftReload/actions/workflows/ci-windows.yml/badge.svg)](https://github.com/ShaftUI/SwiftReload/actions/workflows/ci-windows.yml) | 🚧                  |

## Quick Start

1. Add SwiftReload to your project's dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ShaftUI/SwiftReload.git", branch: "main")
]
```

2. Add SwiftReload to your target's dependencies:

```swift
.executableTarget(
    name: "MyApp",
    dependencies: [
        "SwiftReload"
    ]
)
```

1. Add `-enable-private-imports` and `-enable-implicit-dynamic` flag to your target's build settings:

```swift
.executableTarget(
    name: "MyApp",
    dependencies: [
        "SwiftReload"
    ],
    swiftSettings: [
        .unsafeFlags(
            ["-Xfrontend", "-enable-private-imports"],
            .when(configuration: .debug)
        ),
        .unsafeFlags(
            ["-Xfrontend", "-enable-implicit-dynamic"],
            .when(configuration: .debug)
        ),
    ],
    linkerSettings: [
        .unsafeFlags(
            ["-Xlinker", "--export-dynamic"],
            .when(platforms: [.linux, .android], configuration: .debug)
        ),
    ]
)
```

This enables method swizzling, which SwiftReload uses to replace code at runtime.

> On Linux, you also need to add the `-Xlinker --export-dynamic` flag to the linker settings to export all symbols from the executable.

3. Add the following code at the beginning of your `main.swift`:

```swift
import SwiftReload

LocalSwiftReloader().start()
```

> For complete example, see the [`Sources/SwiftReloadExample`](https://github.com/ShaftUI/SwiftReload/tree/main/Sources/SwiftReloadExample) directory.


## With [ShaftUI](https://github.com/ShaftUI/Shaft)

The `LocalSwiftReloader` has a `onReload` callback that is called when the code reload is triggered. You can call `backend.scheduleReassemble` in the callback to rebuild the UI.

```swift
#if DEBUG
    import SwiftReload
    LocalSwiftReloader(onReload: backend.scheduleReassemble).start()
#endif
```

## How it works

SwiftReload monitors changes to the source files of your project. When a change is detected, it recompiles the updated source files to a dynamic library and loads it into the running process. The dynamic library then replaces the existing code in the process, effectively enabling hot reloading of Swift code.