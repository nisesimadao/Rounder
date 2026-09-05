import Cocoa
import CoreGraphics
import Foundation

// Minimal dependencies required to compile the production CornerGeometry.swift
// directly. The geometry implementation itself is not copied into this file.
enum CornerType {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

enum CornerCutoutStyle: String, CaseIterable {
    case rounded
    case squircle
    case polygon
}

enum RounderAppConstants {
    static let cornerSizePadding: CGFloat = 0.01
}

private struct TestFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

private func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else { throw TestFailure(message: message) }
}

private func expectNear(
    _ actual: CGFloat,
    _ expected: CGFloat,
    tolerance: CGFloat = 0.0001,
    _ message: String
) throws {
    guard abs(actual - expected) <= tolerance else {
        throw TestFailure(
            message: "\(message): expected \(expected), got \(actual)"
        )
    }
}

private func expectPointNear(
    _ actual: CGPoint,
    _ expected: CGPoint,
    tolerance: CGFloat = 0.0001,
    _ message: String
) throws {
    try expectNear(actual.x, expected.x, tolerance: tolerance, "\(message) x")
    try expectNear(actual.y, expected.y, tolerance: tolerance, "\(message) y")
}

private func physicalCornerPoint(
    in frame: CGRect,
    corner: ScreenCorner
) -> CGPoint {
    switch corner {
    case .topLeft:
        return CGPoint(x: frame.minX, y: frame.maxY)
    case .topRight:
        return CGPoint(x: frame.maxX, y: frame.maxY)
    case .bottomLeft:
        return CGPoint(x: frame.minX, y: frame.minY)
    case .bottomRight:
        return CGPoint(x: frame.maxX, y: frame.minY)
    }
}

private func testStyleFactorsAndCornerSizes() throws {
    try expectNear(CornerGeometry.styleFactor(for: .rounded), 1.0, "Rounded style factor")
    try expectNear(CornerGeometry.styleFactor(for: .polygon), 1.0, "Polygon style factor")
    try expectNear(CornerGeometry.styleFactor(for: .squircle), 1.8, "Squircle style factor")

    let cases: [(CGFloat, CornerCutoutStyle, CGFloat)] = [
        (0, .rounded, 0.01),
        (0, .squircle, 0.01),
        (0, .polygon, 0.01),
        (20, .rounded, 20.01),
        (20, .squircle, 36.01),
        (20, .polygon, 20.01),
        (40, .rounded, 40.01),
        (40, .squircle, 72.01),
        (40, .polygon, 40.01),
    ]

    for (radius, style, expected) in cases {
        let actual = CornerGeometry.cornerSize(radius: radius, style: style)
        try expectNear(
            actual,
            expected,
            "cornerSize radius=\(radius) style=\(style.rawValue)"
        )
    }
}

private func testDrawingCornerRoundTrip() throws {
    for corner in ScreenCorner.allCases {
        try expect(
            corner.drawingCorner.screenCorner == corner,
            "drawingCorner inverse failed for \(corner)"
        )
    }
}

private func testScreenOriginsStayOnPhysicalCorners() throws {
    // Deliberately use a non-zero/negative origin so this also covers displays
    // arranged to the left or above/below the primary display.
    let screenFrame = CGRect(x: -1440, y: 100, width: 1440, height: 900)

    for radius: CGFloat in [0, 20, 40] {
        for style in CornerCutoutStyle.allCases {
            let size = CornerGeometry.cornerSize(radius: radius, style: style)

            for corner in ScreenCorner.allCases {
                let origin = CornerGeometry.windowOrigin(
                    in: screenFrame,
                    corner: corner,
                    cornerSize: size
                )
                let windowFrame = CGRect(origin: origin, size: CGSize(width: size, height: size))
                let expectedAnchor = physicalCornerPoint(in: screenFrame, corner: corner)
                let actualAnchor = CornerGeometry.anchorPoint(for: windowFrame, corner: corner)

                try expectPointNear(
                    actualAnchor,
                    expectedAnchor,
                    "screen anchor radius=\(radius) style=\(style.rawValue) corner=\(corner)"
                )
            }
        }
    }
}

private func testLiveResizeKeepsCapturedAnchor() throws {
    let anchor = CGPoint(x: 2173.5, y: -84.25)

    for corner in ScreenCorner.allCases {
        for radius: CGFloat in [0, 20, 40] {
            for style in CornerCutoutStyle.allCases {
                let size = CornerGeometry.cornerSize(radius: radius, style: style)
                let origin = CornerGeometry.windowOrigin(
                    anchoredAt: anchor,
                    corner: corner,
                    cornerSize: size
                )
                let frame = CGRect(origin: origin, size: CGSize(width: size, height: size))
                let recoveredAnchor = CornerGeometry.anchorPoint(for: frame, corner: corner)

                try expectPointNear(
                    recoveredAnchor,
                    anchor,
                    "live resize anchor radius=\(radius) style=\(style.rawValue) corner=\(corner)"
                )
            }
        }
    }
}

private func testShapeSwitchDoesNotMoveCorner() throws {
    let screenFrame = CGRect(x: 320, y: -900, width: 2560, height: 1440)
    let radius: CGFloat = 20

    for corner in ScreenCorner.allCases {
        let expectedAnchor = physicalCornerPoint(in: screenFrame, corner: corner)

        for style in CornerCutoutStyle.allCases {
            let size = CornerGeometry.cornerSize(radius: radius, style: style)
            let origin = CornerGeometry.windowOrigin(
                in: screenFrame,
                corner: corner,
                cornerSize: size
            )
            let frame = CGRect(origin: origin, size: CGSize(width: size, height: size))

            try expectPointNear(
                CornerGeometry.anchorPoint(for: frame, corner: corner),
                expectedAnchor,
                "shape switch moved corner=\(corner) style=\(style.rawValue)"
            )
        }
    }
}

private func testRoundedQuadrantNeverLeaksOutsidePreviewBounds() throws {
    // Menu previews have padding around their sample bounds. The normal rounded
    // drawing path is a full circle and intentionally extends outside its view,
    // where NSView clipping hides it. A menu Canvas would expose those normally
    // invisible quarters, so previews must use this bounded quadrant path.
    let bounds = CGRect(x: 13, y: 9, width: 25, height: 25)
    let epsilon: CGFloat = 0.0001

    for cornerType in [CornerType.topLeft, .topRight, .bottomLeft, .bottomRight] {
        for radius: CGFloat in [1, 12.5, 25] {
            let path = CornerGeometry.roundedQuadrantPath(
                in: bounds,
                radius: radius,
                cornerType: cornerType
            )
            let box = path.boundingBoxOfPath

            try expect(
                box.minX >= bounds.minX - epsilon &&
                box.minY >= bounds.minY - epsilon &&
                box.maxX <= bounds.maxX + epsilon &&
                box.maxY <= bounds.maxY + epsilon,
                "rounded quadrant leaked outside preview bounds corner=\(cornerType) radius=\(radius): \(box)"
            )
        }
    }
}

@main
struct CornerGeometryTestRunner {
    static func main() {
        let tests: [(String, () throws -> Void)] = [
            ("style factors and 0/20/40 sizes", testStyleFactorsAndCornerSizes),
            ("drawing-corner round trip", testDrawingCornerRoundTrip),
            ("screen origins preserve physical corners", testScreenOriginsStayOnPhysicalCorners),
            ("live resize preserves captured anchor", testLiveResizeKeepsCapturedAnchor),
            ("shape switching preserves physical corner", testShapeSwitchDoesNotMoveCorner),
            ("rounded preview quadrant stays inside bounds", testRoundedQuadrantNeverLeaksOutsidePreviewBounds),
        ]

        var failed = false
        print("=== CornerGeometry regression tests ===")

        for (name, test) in tests {
            do {
                try test()
                print("✓ \(name)")
            } catch {
                failed = true
                print("✗ \(name): \(error)")
            }
        }

        if failed {
            print("=== FAILED ===")
            Foundation.exit(1)
        }

        print("=== PASSED ===")
    }
}
