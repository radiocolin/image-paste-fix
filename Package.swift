// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImagePasteFix",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ImagePasteFix",
            path: "ImagePasteFix",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate",
                              "-Xlinker", "__TEXT",
                              "-Xlinker", "__info_plist",
                              "-Xlinker", "ImagePasteFix/Info.plist"])
            ]
        )
    ]
)
