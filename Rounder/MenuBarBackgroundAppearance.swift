import AppKit

/// The normal strip uses the same color as the corner cutouts. Gaming keeps its
/// existing rainbow palette and text-readability adjustment.
struct MenuBarBackgroundAppearance {
    var cornerColor: NSColor = .black
    var gaming = false
    var backgroundColor: NSColor { cornerColor }
    var isOpaque: Bool { gaming || cornerColor.alphaComponent >= 1 }
}
