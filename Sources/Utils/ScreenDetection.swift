import AppKit

public class ScreenDetection {
    public func detectScreens(using frontmostWindowElement: AccessibilityElement?) -> UsableScreens?
    {
        let screens = NSScreen.screens
        guard let firstScreen = screens.first else { return nil }

        if screens.count == 1 {
            let adjacentScreens =
                Defaults.traverseSingleScreen.enabled == true
                ? AdjacentScreens(prev: firstScreen, next: firstScreen)
                : nil

            return UsableScreens(
                currentScreen: firstScreen, adjacentScreens: adjacentScreens,
                numScreens: screens.count, screensOrdered: [firstScreen])
        }

        let screensOrdered = order(screens: screens)
        guard
            let sourceScreen: NSScreen = screenContaining(
                frontmostWindowElement?.frame ?? CGRect.zero, screens: screensOrdered)
        else {
            let adjacentScreens = AdjacentScreens(prev: firstScreen, next: firstScreen)
            return UsableScreens(
                currentScreen: firstScreen, adjacentScreens: adjacentScreens,
                numScreens: screens.count, screensOrdered: screensOrdered)
        }

        let adjacentScreens = adjacent(toFrameOfScreen: sourceScreen.frame, screens: screensOrdered)

        return UsableScreens(
            currentScreen: sourceScreen, adjacentScreens: adjacentScreens,
            numScreens: screens.count, screensOrdered: screensOrdered)
    }

    public func screenContaining(_ rect: CGRect, screens: [NSScreen]) -> NSScreen? {
        var result: NSScreen? = NSScreen.main
        var largestPercentageOfRectWithinFrameOfScreen: CGFloat = 0.0
        for currentScreen in screens {
            let currentFrameOfScreen = NSRectToCGRect(currentScreen.frame)
            let normalizedRect: CGRect = rect.screenFlipped
            if currentFrameOfScreen.contains(normalizedRect) {
                result = currentScreen
                break
            }
            let percentageOfRectWithinCurrentFrameOfScreen: CGFloat = percentageOf(
                normalizedRect, withinFrameOfScreen: currentFrameOfScreen)
            if percentageOfRectWithinCurrentFrameOfScreen
                > largestPercentageOfRectWithinFrameOfScreen
            {
                largestPercentageOfRectWithinFrameOfScreen =
                    percentageOfRectWithinCurrentFrameOfScreen
                result = currentScreen
            }
        }
        return result
    }

    public func percentageOf(_ rect: CGRect, withinFrameOfScreen frameOfScreen: CGRect) -> CGFloat {
        let intersectionOfRectAndFrameOfScreen: CGRect = rect.intersection(frameOfScreen)
        var result: CGFloat = 0.0
        if !intersectionOfRectAndFrameOfScreen.isNull {
            result =
                computeAreaOfRect(rect: intersectionOfRectAndFrameOfScreen)
                / computeAreaOfRect(rect: rect)
        }
        return result
    }

    public func adjacent(toFrameOfScreen frameOfScreen: CGRect, screens: [NSScreen])
        -> AdjacentScreens?
    {
        if screens.count == 2 {
            let otherScreen = screens.first(where: { screen in
                let frame = NSRectToCGRect(screen.frame)
                return !frame.equalTo(frameOfScreen)
            })
            if let otherScreen = otherScreen {
                return AdjacentScreens(prev: otherScreen, next: otherScreen)
            }
        } else if screens.count > 2 {
            let currentScreenIndex = screens.firstIndex(where: { screen in
                let frame = NSRectToCGRect(screen.frame)
                return frame.equalTo(frameOfScreen)
            })
            if let currentScreenIndex = currentScreenIndex {
                let nextIndex =
                    currentScreenIndex == screens.count - 1
                    ? 0
                    : currentScreenIndex + 1
                let prevIndex =
                    currentScreenIndex == 0
                    ? screens.count - 1
                    : currentScreenIndex - 1
                return AdjacentScreens(prev: screens[prevIndex], next: screens[nextIndex])
            }
        }

        return nil
    }

    public func order(screens: [NSScreen]) -> [NSScreen] {
        if Defaults.screensOrderedByX.userEnabled {
            let screensOrderedByX = screens.sorted(by: { screen1, screen2 in
                return screen1.frame.origin.x < screen2.frame.origin.x
            })
            return screensOrderedByX
        }

        let sortedScreens = screens.sorted(by: { screen1, screen2 in
            if screen2.frame.maxY <= screen1.frame.minY {
                return true
            }
            if screen1.frame.maxY <= screen2.frame.minY {
                return false
            }
            return screen1.frame.minX < screen2.frame.minX
        })
        return sortedScreens
    }

    private func computeAreaOfRect(rect: CGRect) -> CGFloat {
        return rect.size.width * rect.size.height
    }

}

public struct UsableScreens {
    public let currentScreen: NSScreen
    public let adjacentScreens: AdjacentScreens?
    public let frameOfCurrentScreen: CGRect
    public let numScreens: Int
    public let screensOrdered: [NSScreen]

    public init(
        currentScreen: NSScreen, adjacentScreens: AdjacentScreens? = nil, numScreens: Int,
        screensOrdered: [NSScreen]? = nil
    ) {
        self.currentScreen = currentScreen
        self.adjacentScreens = adjacentScreens
        self.frameOfCurrentScreen = currentScreen.frame
        self.numScreens = numScreens
        self.screensOrdered = screensOrdered ?? [currentScreen]
    }
}

public struct AdjacentScreens {
    public let prev: NSScreen
    public let next: NSScreen
}

extension NSScreen {

    public func adjustedVisibleFrame(_ ignoreTodo: Bool = false, _ ignoreStage: Bool = false)
        -> CGRect
    {
        var newFrame = visibleFrame

        if Defaults.screenEdgeGapsOnMainScreenOnly.enabled, self != NSScreen.screens.first {
            return newFrame
        }

        newFrame.origin.x += Defaults.screenEdgeGapLeft.cgFloat
        newFrame.origin.y += Defaults.screenEdgeGapBottom.cgFloat
        newFrame.size.width -=
            (Defaults.screenEdgeGapLeft.cgFloat + Defaults.screenEdgeGapRight.cgFloat)

        if #available(macOS 12.0, *), self.safeAreaInsets.top != 0,
            Defaults.screenEdgeGapTopNotch.value != 0
        {
            newFrame.size.height -=
                (Defaults.screenEdgeGapTopNotch.cgFloat + Defaults.screenEdgeGapBottom.cgFloat)
        } else {
            newFrame.size.height -=
                (Defaults.screenEdgeGapTop.cgFloat + Defaults.screenEdgeGapBottom.cgFloat)
        }

        return newFrame
    }

    public static var portraitDisplayConnected: Bool {
        NSScreen.screens.contains(where: { !$0.frame.isLandscape })
    }
}
