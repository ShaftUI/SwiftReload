# SwiftReload

This is an experimental project that enables hot reloading of Swift code in SwiftPM based projects.

## Quick Start

1. Add SwiftReload to your project's dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ShaftUI/SwiftReload.git", .branch("main"))
]
```

2. Add SwiftReload to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SwiftReload", package: "SwiftReload")
    ]
)
```

3. Add the following code at the beginning of your `main.swift`:

```swift
import SwiftReload

LocalSwiftReloader().start()
```