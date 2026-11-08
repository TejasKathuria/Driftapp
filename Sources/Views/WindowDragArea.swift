import SwiftUI
import AppKit

/// An NSViewRepresentable that hooks directly into AppKit's native window dragging engine.
/// When placed as a background on any view or header, clicking and dragging on that area
/// moves the borderless window with sub-millisecond, hardware-accelerated smoothness.
public struct WindowDragArea: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> WindowDragView {
        return WindowDragView()
    }
    
    public func updateNSView(_ nsView: WindowDragView, context: Context) {}
}

public final class WindowDragView: NSView {
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    public override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown, let window = self.window {
            window.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}
