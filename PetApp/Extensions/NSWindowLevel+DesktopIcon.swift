import AppKit
import CoreGraphics

extension NSWindow.Level {
    /// Provides a level that sits above the desktop but below normal app windows.
    /// CoreGraphics does not expose a dedicated "desktop icon" key on all macOS versions,
    /// so we start from the desktop level constant and nudge it up.
    static let desktopIcon: NSWindow.Level = {
        let level = Int(CGWindowLevelForKey(.desktopWindow)) + 1
        return NSWindow.Level(rawValue: level)
    }()
}
