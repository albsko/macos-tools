import AppKit
import Foundation

extension CGPoint {
    public var screenFlipped: CGPoint {
        .init(x: x, y: NSScreen.screens[0].frame.maxY - y)
    }
}

extension CGRect {
    public var screenFlipped: CGRect {
        guard !isNull else {
            return self
        }
        return .init(
            origin: .init(x: origin.x, y: NSScreen.screens[0].frame.maxY - maxY), size: size)
    }

    public var isLandscape: Bool { width > height }

    public var centerPoint: CGPoint {
        NSMakePoint(NSMidX(self), NSMidY(self))
    }

    public func numSharedEdges(withRect rect: CGRect) -> Int {
        var sharedEdgeCount = 0
        if minX == rect.minX { sharedEdgeCount += 1 }
        if maxX == rect.maxX { sharedEdgeCount += 1 }
        if minY == rect.minY { sharedEdgeCount += 1 }
        if maxY == rect.maxY { sharedEdgeCount += 1 }
        return sharedEdgeCount
    }
}
