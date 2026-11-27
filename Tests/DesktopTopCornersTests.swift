import AppKit

enum RounderAppConstants { static let cornerSizePadding: CGFloat = 0.01 }
@main struct DesktopTopCornersTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        let screen = NSScreen.screens[0], id = screen.displayID!
        let ids = DesktopSpaceMembership.spaceIDs(for: id)!
        let corners = DesktopTopCorners()
        corners.configure(.init(radius: 20, style: .rounded, color: .black, gaming: false, speed: 1,
                                topLeft: true, topRight: true, displayIDs: [id]), screens: [screen], fullscreen: [])
        precondition(corners.windows.count == ids.count * 2)
        let frames = corners.windows.map(\.frame), numbers = corners.windows.map(\.windowNumber)
        corners.refresh(screens: [screen], fullscreen: [id])
        precondition(corners.windows.map(\.frame) == frames,
                     "Incoming desktop corners must keep their own menu inset while fullscreen is active")
        precondition(corners.windows.map(\.windowNumber) == numbers)
        corners.updateGeometry(radius: 30, style: .squircle)
        precondition(zip(corners.windows, frames).allSatisfy { abs($0.0.frame.maxY - $0.1.maxY) < 0.01 })
        corners.refresh(screens: [screen], fullscreen: [])
        precondition(corners.windows.map(\.windowNumber) == numbers)
        corners.close()
        precondition(corners.windows.isEmpty)
        print("PASS: each ordinary Space keeps its own top corners at the menu inset throughout fullscreen transitions")
    }
}
