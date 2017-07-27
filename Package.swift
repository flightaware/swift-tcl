// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SwiftTcl",
    targets: [Target(name: "Tcl8_6"),
              Target(name: "SwiftTcl_c", dependencies:["Tcl8_6"]),
              Target(name: "SwiftTcl", dependencies:["SwiftTcl_c"]),
              Target(name: "SwiftTclDemo", dependencies:["SwiftTcl"])]
)

