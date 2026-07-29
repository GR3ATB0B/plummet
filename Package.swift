// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlummetKinematics",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "PlummetKinematics",
            path: "Plummet",
            sources: ["KinematicsSolver.swift"]
        ),
        .testTarget(
            name: "PlummetKinematicsTests",
            dependencies: ["PlummetKinematics"],
            path: "Tests/PlummetKinematicsTests"
        ),
    ]
)
