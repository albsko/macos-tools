import AppKit
import Foundation

public class AccessibilityElement {
    public let wrappedElement: AXUIElement

    public init(_ element: AXUIElement) {
        wrappedElement = element
    }

    public convenience init(_ pid: pid_t) {
        self.init(AXUIElementCreateApplication(pid))
    }

    public convenience init?(_ bundleIdentifier: String) {
        guard
            let app =
                (NSWorkspace.shared.runningApplications.first {
                    $0.bundleIdentifier == bundleIdentifier
                })
        else { return nil }
        self.init(app.processIdentifier)
    }

    @MainActor
    public convenience init?(_ position: CGPoint) {
        guard let element = AXUIElement.systemWide.getElementAtPosition(position) else {
            return nil
        }
        self.init(element)
    }

    private func getElementValue(_ attribute: NSAccessibility.Attribute) -> AccessibilityElement? {
        guard let value = wrappedElement.getValue(attribute),
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return AccessibilityElement(value as! AXUIElement)
    }

    private func getElementsValue(_ attribute: NSAccessibility.Attribute) -> [AccessibilityElement]?
    {
        guard let value = wrappedElement.getValue(attribute), let array = value as? [AXUIElement]
        else { return nil }
        return array.map { AccessibilityElement($0) }
    }

    private var role: NSAccessibility.Role? {
        guard let value = wrappedElement.getValue(.role) as? String else { return nil }
        return NSAccessibility.Role(rawValue: value)
    }

    private var isApplication: Bool? {
        guard let role = role else { return nil }
        return role == .application
    }

    public var isWindow: Bool? {
        guard let role = role else { return nil }
        return role == .window
    }

    public var isSheet: Bool? {
        guard let role = role else { return nil }
        return role == .sheet
    }

    public var isToolbar: Bool? {
        guard let role = role else { return nil }
        return role == .toolbar
    }

    public var isGroup: Bool? {
        guard let role = role else { return nil }
        return role == .group
    }

    public var isTabGroup: Bool? {
        guard let role = role else { return nil }
        return role == .tabGroup
    }

    public var isStaticText: Bool? {
        guard let role = role else { return nil }
        return role == .staticText
    }

    private var subrole: NSAccessibility.Subrole? {
        guard let value = wrappedElement.getValue(.subrole) as? String else { return nil }
        return NSAccessibility.Subrole(rawValue: value)
    }

    public var isSystemDialog: Bool? {
        guard let subrole = subrole else { return nil }
        return subrole == .systemDialog
    }

    private var position: CGPoint? {
        get {
            wrappedElement.getWrappedValue(.position)
        }
        set {
            guard let newValue = newValue else { return }
            wrappedElement.setValue(.position, newValue)
        }
    }

    public func isResizable() -> Bool {
        if let isResizable = wrappedElement.isValueSettable(.size) {
            return isResizable
        }
        // Logger.log("Unable to determine if window is resizeable. Assuming it is.")
        return true
    }

    public var size: CGSize? {
        get {
            wrappedElement.getWrappedValue(.size)
        }
        set {
            guard let newValue = newValue else { return }
            wrappedElement.setValue(.size, newValue)
            // Logger.log(
            //     "AX sizing proposed: \(newValue.debugDescription), result: \(size?.debugDescription ?? "N/A")"
            // )
        }
    }

    public var frame: CGRect {
        guard let position = position, let size = size else { return .null }
        return .init(origin: position, size: size)
    }

    public func setFrame(_ frame: CGRect, adjustSizeFirst: Bool = true) {
        let appElement = applicationElement
        var enhancedUI: Bool? = nil

        if let appElement = appElement {
            enhancedUI = appElement.enhancedUserInterface
            if enhancedUI == true {
                appElement.enhancedUserInterface = false
            }
        }

        if adjustSizeFirst {
            size = frame.size
        }
        position = frame.origin
        size = frame.size

        if let appElement = appElement, enhancedUI == true {
            appElement.enhancedUserInterface = true
        }
    }

    private var childElements: [AccessibilityElement]? {
        getElementsValue(.children)
    }

    public func getChildElement(_ role: NSAccessibility.Role) -> AccessibilityElement? {
        return childElements?.first { $0.role == role }
    }

    public func getChildElements(_ role: NSAccessibility.Role) -> [AccessibilityElement]? {
        guard let elements = (childElements?.filter { $0.role == role }), elements.count > 0 else {
            return nil
        }
        return elements
    }

    public func getChildElement(_ subrole: NSAccessibility.Subrole) -> AccessibilityElement? {
        return childElements?.first { $0.subrole == subrole }
    }

    public func getChildElements(_ subrole: NSAccessibility.Subrole) -> [AccessibilityElement]? {
        guard let elements = (childElements?.filter { $0.subrole == subrole }), elements.count > 0
        else {
            return nil
        }
        return elements
    }

    public func getSelfOrChildElementRecursively(_ position: CGPoint) -> AccessibilityElement? {
        func getChildElement() -> AccessibilityElement? {
            return element.childElements?
                .map { (element: $0, frame: $0.frame) }
                .filter { $0.frame.contains(position) }
                .min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }?
                .element
        }
        var element = self
        var elements = Set<AccessibilityElement>()
        while let childElement = getChildElement(), elements.insert(childElement).inserted {
            element = childElement
        }
        return element
    }

    public var windowId: CGWindowID? {
        wrappedElement.getWindowId()
    }

    @MainActor public func getWindowId() -> CGWindowID? {
        if let windowId = windowId {
            return windowId
        }
        let frame = frame
        // Take the first match because there's no real way to guarantee which window we're actually getting
        if let pid = pid,
            let info = (WindowUtil.getWindowList().first { $0.pid == pid && $0.frame == frame })
        {
            return info.id
        }
        return nil
    }

    public var pid: pid_t? {
        wrappedElement.getPid()
    }

    public var windowElement: AccessibilityElement? {
        if isWindow == true { return self }
        return getElementValue(.window)
    }

    private var isMainWindow: Bool? {
        get {
            windowElement?.wrappedElement.getValue(.main) as? Bool
        }
        set {
            guard let newValue = newValue else { return }
            windowElement?.wrappedElement.setValue(.main, newValue)
        }
    }

    public var isMinimized: Bool? {
        windowElement?.wrappedElement.getValue(.minimized) as? Bool
    }

    public var isFullScreen: Bool? {
        guard let subrole = windowElement?.getElementValue(.fullScreenButton)?.subrole else {
            return nil
        }
        return subrole == .zoomButton
    }

    public var titleBarFrame: CGRect? {
        guard
            let windowElement,
            case let windowFrame = windowElement.frame,
            windowFrame != .null,
            let closeButtonFrame = windowElement.getChildElement(.closeButton)?.frame,
            closeButtonFrame != .null
        else {
            return nil
        }
        let gap = closeButtonFrame.minY - windowFrame.minY
        let height = 2 * gap + closeButtonFrame.height
        return CGRect(
            origin: windowFrame.origin, size: CGSize(width: windowFrame.width, height: height))
    }

    private var applicationElement: AccessibilityElement? {
        if isApplication == true { return self }
        guard let pid = pid else { return nil }
        return AccessibilityElement(pid)
    }

    private var focusedWindowElement: AccessibilityElement? {
        applicationElement?.getElementValue(.focusedWindow)
    }

    public var windowElements: [AccessibilityElement]? {
        applicationElement?.getElementsValue(.windows)
    }

    public var isHidden: Bool? {
        applicationElement?.wrappedElement.getValue(.hidden) as? Bool
    }

    public var enhancedUserInterface: Bool? {
        get {
            applicationElement?.wrappedElement.getValue(.enhancedUserInterface) as? Bool
        }
        set {
            guard let newValue = newValue else { return }
            applicationElement?.wrappedElement.setValue(.enhancedUserInterface, newValue)
        }
    }

    public var windowIds: [CGWindowID]? {
        wrappedElement.getValue(.windowIds) as? [CGWindowID]
    }

    public func bringToFront(force: Bool = false) {
        if isMainWindow != true {
            isMainWindow = true
        }
        if let pid = pid, let app = NSRunningApplication(processIdentifier: pid),
            !app.isActive || force
        {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
}

extension AccessibilityElement {
    public static func getFrontApplicationElement() -> AccessibilityElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return AccessibilityElement(app.processIdentifier)
    }

    public static func getFrontWindowElement() -> AccessibilityElement? {
        guard let appElement = getFrontApplicationElement() else {
            return nil
        }
        if let focusedWindowElement = appElement.focusedWindowElement {
            return focusedWindowElement
        }
        if let firstWindowElement = appElement.windowElements?.first {
            return firstWindowElement
        }
        return nil
    }

    @MainActor private static func getWindowInfo(_ location: CGPoint) -> WindowInfo? {
        WindowUtil.getWindowList().first(where: { windowInfo in
            windowInfo.level < 23  // 23 is the level of the Notification Center
                && !["Dock", "WindowManager"].contains(windowInfo.processName)
                && windowInfo.frame.contains(location)
        })
    }

    @MainActor public static func getWindowElementUnderCursor() -> AccessibilityElement? {
        let position = NSEvent.mouseLocation.screenFlipped

        if let info = getWindowInfo(position) {
            if let windowElements = AccessibilityElement(info.pid).windowElements {
                if let windowElement = (windowElements.first { $0.windowId == info.id }) {
                    return windowElement
                }
                if let windowElement = (windowElements.first { $0.frame == info.frame }) {
                    return windowElement
                }
            }
        }

        if let element = AccessibilityElement(position),
            let windowElement = element.windowElement
        {
            return windowElement
        }

        return nil
    }

    @MainActor public static func getWindowElement(_ windowId: CGWindowID) -> AccessibilityElement?
    {
        guard let pid = WindowUtil.getWindowList(ids: [windowId]).first?.pid else { return nil }
        return AccessibilityElement(pid).windowElements?.first { $0.windowId == windowId }
    }

    @MainActor public static func getAllWindowElements() -> [AccessibilityElement] {
        return WindowUtil.getWindowList().uniqueMap { $0.pid }.compactMap {
            AccessibilityElement($0).windowElements
        }.flatMap { $0 }
    }
}

extension AccessibilityElement: Equatable {
    public static func == (lhs: AccessibilityElement, rhs: AccessibilityElement) -> Bool {
        return lhs.wrappedElement == rhs.wrappedElement
    }
}

extension AccessibilityElement: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedElement)
    }
}
