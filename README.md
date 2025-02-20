# SwiftReload

This is an experimental project that enables hot reloading of Swift code in SwiftPM based projects.

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
        .unsafeFlags(["-Xfrontend", "-enable-private-imports"]),
        .unsafeFlags(["-Xfrontend", "-enable-implicit-dynamic"]),
    ]
)
```

This enables method swizzling, which SwiftReload uses to replace code at runtime.

3. Add the following code at the beginning of your `main.swift`:

```swift
import SwiftReload

LocalSwiftReloader().start()
```

> For complete example, see the [`Sources/SwiftReloadExample`](https://github.com/ShaftUI/SwiftReload/tree/main/Sources/SwiftReloadExample) directory.

## How it works

SwiftReload uses a file watcher to monitor changes to the source files of your project. When a change is detected, it recompiles the updated source files and reloads the main module of your project.