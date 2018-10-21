// swift-tools-version:4.0
import PackageDescription

let packageBaseUrl = "https://github.com"
let ibmPackageBase = packageBaseUrl + "/IBM-Swift"

let package = Package(
    name: "TodoServer",
    dependencies: [
      .package(url: ibmPackageBase + "/Kitura.git", .upToNextMinor(from: "2.5.0")),
      .package(url: ibmPackageBase + "/HeliumLogger.git", .upToNextMinor(from: "1.7.1")),
      .package(url: ibmPackageBase + "/CloudEnvironment.git", from: "8.0.0"),
      .package(url: packageBaseUrl + "/RuntimeTools/SwiftMetrics.git", from: "2.0.0"),
      .package(url: ibmPackageBase + "/Health.git", from: "1.0.0"),
      .package(url: ibmPackageBase + "/Kitura-OpenAPI.git", from: "1.0.0"),
      .package(url: ibmPackageBase + "/Kitura-CORS.git", from: "2.1.0"),
    ],
    targets: [
      .target(name: "TodoServer", dependencies: [ .target(name: "Application"), "Kitura" , "HeliumLogger"]),
      .target(name: "Application",
              dependencies: [
                "Kitura", "CloudEnvironment","SwiftMetrics","Health",
                "KituraOpenAPI", "KituraCORS"
              ]),

      .testTarget(name: "ApplicationTests" , dependencies: [.target(name: "Application"), "Kitura","HeliumLogger" ])
    ]
)
