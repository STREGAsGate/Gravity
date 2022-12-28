// swift-tools-version: 5.4
//
// Gravity source cloned from commit:
// https://github.com/marcobambini/gravity/tree/971337cc01877d62972e42cab5099379c5b97f12
//
// The following are the changes made to the GravityC source.
// This will be helpful when updating to a new Gravity release.
// - All Files: #include declarations changed to use relative paths.
// - File src/utils/gravity_utils.c: line 508, clang on windows gets confused by this inline
// - File src/compiler/debug_macros.h: line 18, removed #include <assert.h>, crashes on windows with clang when public
//   - Many .c files have a new #include <assert.h> to account for the loass of above

import PackageDescription

let package = Package(
    name: "Gravity",
    products: [
        .library(name: "Gravity", targets: ["Gravity"]),
        .library(name: "GravityC", targets: ["GravityC"]),
    ],
    targets: [
        .executableTarget(name: "Example", dependencies: ["Gravity"], resources: [
            .process("Scripts")
        ]),
        
        .target(name: "Gravity", dependencies: ["GravityC"]),
        .target(name: "GravityC", cSettings: [
            .define("BUILD_GRAVITY_API"),
            // WASI doesn't have umask
            .define("umask(x)", to: "022", .when(platforms: [.wasi])),
            // Silence deprecation warning on windows
            .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
            // Windows doesn't support PIC flag
            .unsafeFlags(["-fPIC"], .when(platforms: .any(except: .windows))),
            
            .unsafeFlags(["-w"]),
        ], linkerSettings: [
            //For math functions
            .linkedLibrary("m", .when(platforms: .any(except: .windows))),
            //For path functions
            .linkedLibrary("Shlwapi", .when(platforms: [.windows])),
            //SR-14728
            .linkedLibrary("swiftCore", .when(platforms: [.windows])),
        ]),
        
        .testTarget(name: "GravityTests", dependencies: ["GravityC", "Gravity"]),
        .testTarget(name: "GravityCTests", dependencies: ["GravityC", "Gravity"], resources: [.copy("_Resources")])
    ],
    swiftLanguageVersions: [.v5],
    cLanguageStandard: .gnu99
)

extension Array where Element == Platform {
    static func any(except excluding: Platform...) -> Self {
        var array = self.all
        for platform in excluding {
            array.removeAll(where: {$0 == platform})
        }
        return array
    }
    
    private static var all: Self {
        return [
            .macOS, .macCatalyst, .iOS, .tvOS, .watchOS, .driverKit,
            .linux, .android,
            .windows,
            .wasi,
        ]
    }
}
