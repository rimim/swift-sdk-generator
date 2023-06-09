//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
@testable import SwiftSDKGenerator
import SystemPackage
import XCTest

final class EndToEndTests: XCTestCase {
  func testPackageInitExecutable() async throws {
    let fm = FileManager.default

    var packageDirectory = FilePath(#file)
    packageDirectory.removeLastComponent()
    packageDirectory.removeLastComponent()

    let generatorOutput = try await Shell.readStdout(
      "swift run swift-sdk-generator",
      currentDirectory: packageDirectory
    )

    let installCommand = try XCTUnwrap(generatorOutput.split(separator: "\n").first {
      $0.contains("swift experimental-sdk install")
    })

    let bundleName = try XCTUnwrap(
      FilePath(String(XCTUnwrap(installCommand.split(separator: " ").last))).components.last
    ).stem

    // Make sure this bundle hasn't been installed already.
    try await Shell.run("swift experimental-sdk remove \(bundleName)")

    let installOutput = try await Shell.readStdout(String(installCommand))
    XCTAssertTrue(installOutput.contains("successfully installed"))

    let testPackageURL = FileManager.default.temporaryDirectory.appending(path: "swift-sdk-generator-test").path
    print(testPackageURL)
    let testPackageDir = FilePath(testPackageURL)
    try fm.removeItem(atPath: testPackageDir.string)
    try fm.createDirectory(atPath: testPackageDir.string, withIntermediateDirectories: true)

    try await Shell.run("swift package init --type executable", currentDirectory: testPackageDir)

    let buildOutput = try await Shell.readStdout(
      "swift build --experimental-swift-sdk \(bundleName)",
      currentDirectory: testPackageDir
    )
    XCTAssertTrue(buildOutput.contains("Build complete!"))
  }
}