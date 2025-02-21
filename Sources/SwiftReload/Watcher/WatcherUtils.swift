/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2020 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

#if os(Windows)
import WinSDK
#endif

/// Closable entity is one that manages underlying resources and needs to be closed for cleanup
/// The intent of this method is for the sole owner of the refernece/handle of the resource to close it completely, comapred to releasing a shared resource.
public protocol Closable {
  func close() throws
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension Collection {
    /// Returns the only element of the collection or nil.
    public var spm_only: Element? {
        return count == 1 ? self[startIndex] : nil
    }
}

extension AbsolutePath {
  /// File URL created from the normalized string representation of the path.
  public var asURL: Foundation.URL {
    return URL(fileURLWithPath: pathString)
  }
}

/// Returns the "real path" corresponding to `path` by resolving any symbolic links.
public func resolveSymlinks(_ path: AbsolutePath) throws -> AbsolutePath {
  #if os(Windows)
    let handle: HANDLE = path.pathString.withCString(encodedAs: UTF16.self) {
      CreateFileW(
        $0, GENERIC_READ, DWORD(FILE_SHARE_READ), nil,
        DWORD(OPEN_EXISTING), DWORD(FILE_FLAG_BACKUP_SEMANTICS), nil)
    }
    if handle == INVALID_HANDLE_VALUE { return path }
    defer { CloseHandle(handle) }
    return try withUnsafeTemporaryAllocation(of: WCHAR.self, capacity: 261) {
      let dwLength: DWORD =
        GetFinalPathNameByHandleW(
          handle, $0.baseAddress!, DWORD($0.count),
          DWORD(FILE_NAME_NORMALIZED))
      let path = String(decodingCString: $0.baseAddress!, as: UTF16.self)
      return try AbsolutePath(path)
    }
  #else
    let pathStr = path.pathString

    // FIXME: We can't use FileManager's destinationOfSymbolicLink because
    // that implements readlink and not realpath.
    if let resultPtr = realpath(pathStr, nil) {
      let result = String(cString: resultPtr)
      // If `resolved_path` is specified as NULL, then `realpath` uses
      // malloc(3) to allocate a buffer [...].  The caller should deallocate
      // this buffer using free(3).
      //
      // String.init(cString:) creates a new string by copying the
      // null-terminated UTF-8 data referenced by the given pointer.
      resultPtr.deallocate()
      // FIXME: We should measure if it's really more efficient to compare the strings first.
      return result == pathStr ? path : try AbsolutePath(validating: result)
    }

    return path
  #endif
}