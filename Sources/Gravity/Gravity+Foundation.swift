/**
 * Copyright © 2022 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 * Licensed under MIT License
 *
 * http://stregasgate.com
 */

#if canImport(Foundation) && !os(WASI)
import struct Foundation.URL
import GravityC

internal func filenameCallback(fileID: UInt32, xData: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    guard let userData = unsafeBitCast(xData, to: Optional<GravityCompilerUserData>.self) else {return nil}
    return userData.gravity.loadedFilenames[fileID]?.withCString { source in
        return UnsafePointer(strdup(source))
    }
}

internal func loadFileCallback(file: UnsafePointer<CChar>?, size: UnsafeMutablePointer<Int>?, fileID: UnsafeMutablePointer<UInt32>?, xData: UnsafeMutableRawPointer?, isStatic: UnsafeMutablePointer<Bool>?) -> UnsafePointer<CChar>? {
    guard let cFile = file else {return nil}
    guard let userData = unsafeBitCast(xData, to: Optional<GravityCompilerUserData>.self) else {return nil}
    
    let file = String(cString: cFile)
    let url = userData.baseURL!.appendingPathComponent(file)

    let sourceCode: String = url.path.withCString { cString in
        guard let sourceC = GravityC.file_read(cString, nil) else {return ""}
        return String(cString: sourceC)
    }
    
    size?.pointee = sourceCode.count
    if let fileID = fileID?.pointee {
        userData.gravity.loadedFilenames[fileID] = file
    }
    print("Gravity: Loaded File", file)
    return sourceCode.withCString { sourceCode in
        return UnsafePointer(strdup(sourceCode))
    }
}

public extension Gravity {
    /**
     Compile a gravity script.
     - parameter sourceCode: The gravity script as a `String`.
     - parameter addDebug: `true` to add debug. nil to add debug only in DEBUG configurations.
     - throws: Gravity compilation errors such as syntax problems and file loading problems.
     */
    func compile(_ source: URL, addDebug: Bool? = nil) throws {
        let baseURL = source.deletingLastPathComponent()
        let sourceCode: String = source.path.withCString { cString in
            guard let sourceC = GravityC.file_read(cString, nil) else {return ""}
            return String(cString: sourceC)
        }
        compilerUserData.baseURL = baseURL
        try self.compile(sourceCode, addDebug: addDebug)
    }
}

#endif
